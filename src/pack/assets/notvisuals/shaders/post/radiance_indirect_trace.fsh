#version 330
#extension GL_ARB_separate_shader_objects : require
// NotVisuals R10: original screen-space irradiance gathering, inspired by the
// general rendering concepts studied in VPT (NOT copied VPT GLSL).
// Visible geometry only; no chunks, shadow maps, motion vectors or voxel GI.
uniform sampler2D SceneSampler;
uniform sampler2D LitSampler;
uniform sampler2D MainDepthSampler;
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
const float NV_NEAR=0.05;
float distApprox(float d) {return min(128.0,NV_NEAR/max(d,0.00002));}
vec3 positionAt(vec2 uv,float d){
    float z=distApprox(d);
    vec2 s=vec2(textureSize(SceneSampler,0));
    vec2 xy=(uv*2.0-1.0)*vec2(s.x/max(s.y,1.0),1.0)*0.7002075*z;
    return vec3(xy,-z);
}
void main(){
    float d=texture(MainDepthSampler,texCoord).r;
    if(d<=0.00002||d>=0.999999){fragColor=vec4(0.0);return;}
    vec3 p=positionAt(texCoord,d);
    vec2 fullPixel=1.0/vec2(textureSize(MainDepthSampler,0));
    vec3 incident=vec3(0.0);float weightSum=0.0;
    // Multi-scale deterministic gathering: several orientations and projected
    // distances, no random per-frame patterns (prevents temporal sparkles).
    const vec2 directions[12]=vec2[](
       vec2(1.0,0.0),vec2(.866025,.5),vec2(.5,.866025),vec2(0.0,1.0),
       vec2(-.5,.866025),vec2(-.866025,.5),vec2(-1.0,0.0),
       vec2(-.866025,-.5),vec2(-.5,-.866025),vec2(0.0,-1.0),
       vec2(.5,-.866025),vec2(.866025,-.5));
    // Ranges are in SCREEN pixels at full scene resolution; scale adapts to
    // resolution so lighting extends farther than the original R9 glow.
    vec2 pixel=vec2(1.0)/vec2(textureSize(SceneSampler,0));
    float radii[3]=float[](10.0,27.0,56.0);
    for(int ring=0;ring<3;ring++){
        for(int i=0;i<12;i++){
            vec2 uv=texCoord+directions[i]*radii[ring]*pixel;
            if(any(lessThan(uv,vec2(0.004)))||any(greaterThan(uv,vec2(.996))))continue;
            float sd=texture(MainDepthSampler,uv).r;
            if(sd<=0.00002||sd>=0.999999)continue;
            vec3 q=positionAt(uv,sd);
            float travel=length(q-p);
            // Neighbor must be in a plausible local geometry neighborhood.
            float rangeLimit=ring==0?3.0:(ring==1?6.0:11.0);
            if(travel>rangeLimit||travel<0.03)continue;
            vec3 original=texture(SceneSampler,uv).rgb;
            vec3 lit=texture(LitSampler,uv).rgb;
            vec3 direct=max(lit-original,vec3(0.0));
            // Albedo preservation: colored direct light on a surface becomes
            // secondary radiance rather than sampling only bright source pixels.
            vec3 bounceColor=direct*(.72+.28*clamp(original,0.0,1.0));
            float smoothDistance=pow(max(0.0,1.0-travel/(rangeLimit+.01)),1.35);
            float comparableDepth=1.0-smoothstep(.35,1.6,abs(distApprox(sd)-distApprox(d)));
            float w=(.25+.75*smoothDistance)*mix(.15,1.0,comparableDepth);
            incident+=bounceColor*w;
            weightSum+=w;
        }
    }
    // As a physically conservative approximation, no direct energy is added
    // when zero neighbors exhibit colored R9 lighting.
    vec3 bounced=weightSum>0.00001?incident/weightSum:vec3(0.0);
    fragColor=vec4(clamp(bounced*1.55,vec3(0.0),vec3(0.75)),1.0);
}
