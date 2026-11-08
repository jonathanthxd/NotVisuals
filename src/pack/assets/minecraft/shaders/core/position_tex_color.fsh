#version 330
#extension GL_ARB_separate_shader_objects : require
// NotVisuals R14 - End-only violet curtains. No end_sky.png replacement:
// this deliberately leaves End portals, End gateways, GUI and Overworld intact.
layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    mat4 TextureMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
};
uniform sampler2D Sampler0;
layout(location = 0) in vec2 texCoord0;
layout(location = 1) in vec4 vertexColor;
layout(location = 2) flat in float nvEndSky;
layout(location = 3) in vec3 nvEndDirection;
layout(location = 0) out vec4 fragColor;

// World-space angular auroral drapes; broad smooth purple ribbons that wrap
// continuously around the inward-facing End sky cube. No tiled 16x texture.
// R16 END SKY: wide irregular horizontally-curved auroral sheets rather than
// thin vertical stripes. World-direction sampling is seam-safe in azimuth.
// This shader is intentionally static: an unbound time uniform would break
// startup rendering. Stars do not twinkle (no flashing artifacts).
float nvStarHash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec3 nvEndStars(vec3 direction, float auroraDensity) {
    vec3 d=normalize(direction);
    // Unit-direction cube atlas coordinates, not spherical lat/long UVs.
    // Cube tiles retain finite area above the player's head (zenith).
    vec3 a=abs(d);
    vec2 plane;
    float face;
    if(a.x>=a.y && a.x>=a.z){
        plane=vec2(d.z,d.y)/a.x;face=d.x>0.0?1.0:2.0;
    }else if(a.y>=a.z){
        plane=vec2(d.x,d.z)/a.y;face=d.y>0.0?3.0:4.0;
    }else{
        plane=vec2(d.x,d.y)/a.z;face=d.z>0.0?5.0:6.0;
    }
    const float cells=164.0;
    vec2 uv=(plane*0.5+0.5)*cells;
    vec2 cell=floor(uv);
    vec2 r=vec2(nvStarHash(cell+vec2(face*177.7,17.9)),
                nvStarHash(cell+vec2(64.7,face*219.3)));
    vec2 local=fract(uv)-mix(vec2(0.24),vec2(0.76),r);
    float dist=length(local);
    float occurrence=step(0.978,nvStarHash(cell+vec2(14.3+face*7.0,52.6)));
    float aa=max(0.014,fwidth(dist)*0.72);
    float core=1.0-smoothstep(0.018,0.018+aa,dist);
    float halo=exp(-pow(dist/0.17,2.0))*0.10;
    float seamGuard=smoothstep(0.005,0.03,min(min(plane.x+1.0,1.0-plane.x),min(plane.y+1.0,1.0-plane.y)));
    float altitude=smoothstep(-0.06,0.21,d.y);
    float densityFade=1.0-0.21*clamp(auroraDensity,0.0,1.0);
    float variation=mix(0.31,0.83,nvStarHash(cell+vec2(9.2,73.8+face)));
    vec3 pearly=vec3(0.91,0.92,1.0);
    vec3 lilac=vec3(0.85,0.75,1.0);
    vec3 tint=mix(pearly,lilac,nvStarHash(cell+vec2(39.1,4.8))*0.38);
    return tint*occurrence*(core+halo)*seamGuard*altitude*densityFade*variation;
}

vec3 nvFarGalaxies(vec3 d){
    vec3 c1=normalize(vec3(-0.62,0.38,0.69));
    vec3 c2=normalize(vec3(0.57,0.54,-0.61));
    vec3 c3=normalize(vec3(0.12,0.78,0.54));
    float g1=exp(-pow((1.0-dot(d,c1))/0.18,2.0));
    float g2=exp(-pow((1.0-dot(d,c2))/0.14,2.0));
    float g3=exp(-pow((1.0-dot(d,c3))/0.20,2.0));
    vec3 whiteMist=vec3(0.090,0.094,0.108)*g1;
    vec3 pearlMist=vec3(0.075,0.072,0.090)*g2;
    vec3 tinyCloud=vec3(0.030,0.026,0.040)*g3;
    return whiteMist + pearlMist + tinyCloud;
}

vec3 nvVioletDrapes(vec3 direction){
    vec3 d=normalize(direction);
    float elevation=asin(clamp(d.y,-1.0,1.0));
    float a=atan(d.z,d.x);

    // R17: bring back upward-reaching auroral lines, but make them broad,
    // layered and patterned instead of thin identical pillars.
    float foot = smoothstep(-0.10, 0.16, elevation);
    float crownFade = 1.0 - smoothstep(1.06, 1.43, elevation);
    float envelope = foot * crownFade;

    float stripesA = max(0.0, sin(a*6.0 + 0.55*sin(a*2.0) + 0.25));
    float stripesB = max(0.0, sin(a*9.0 - 0.80*sin(a*3.0) - 0.55));
    float stripesC = max(0.0, sin(a*13.0 + 0.25*sin(a*4.0) + 1.4));
    stripesA = pow(stripesA, 1.7);
    stripesB = pow(stripesB, 2.0);
    stripesC = pow(stripesC, 2.6);

    float bendA = 0.76 + 0.24*sin(elevation*4.2 + a*1.8);
    float bendB = 0.72 + 0.28*sin(elevation*6.0 - a*2.3 + 0.6);
    float verticalReach = smoothstep(-0.08,0.28,elevation) * (1.0 - smoothstep(1.22,1.47,elevation));

    float curtainA = stripesA * bendA * verticalReach;
    float curtainB = stripesB * bendB * verticalReach * 0.82;
    float curtainC = stripesC * (0.70+0.30*sin(elevation*8.0+a*1.1)) * verticalReach * 0.54;

    float lowHaze = exp(-pow((elevation-0.10)/0.25,2.0));
    float midGlow = exp(-pow((elevation-0.48)/0.36,2.0));
    float highGlow = exp(-pow((elevation-0.92)/0.28,2.0));

    vec3 deepViolet=vec3(0.13,0.04,0.30);
    vec3 amethyst=vec3(0.28,0.11,0.48);
    vec3 orchid=vec3(0.42,0.19,0.60);

    vec3 aurora = deepViolet*(curtainA*0.26 + curtainB*0.12)
                + amethyst*(curtainA*0.60 + curtainB*0.42 + curtainC*0.18)
                + orchid*(curtainB*0.28 + curtainC*0.32 + highGlow*0.10);
    aurora += mix(deepViolet, amethyst, 0.35) * lowHaze * 0.045;
    aurora += mix(amethyst, orchid, 0.58) * midGlow * 0.028;
    aurora *= envelope;
    aurora *= mix(0.50,1.0,smoothstep(-0.02,0.18,elevation));

    float density = clamp(curtainA*0.50 + curtainB*0.35 + curtainC*0.20 + lowHaze*0.12,0.0,1.0);
    vec3 space = nvFarGalaxies(d);
    return max(vec3(0.0), aurora) + space + nvEndStars(d, density);
}

void main() {
    vec4 sampled = texture(Sampler0, texCoord0);
    if(sampled.a == 0.0) discard;
    vec4 original = sampled * vertexColor * ColorModulator;
    if(nvEndSky > 0.5) {
        // End sky uses vanilla #282828 tint, hence preserve its dark noise.
        vec3 aurora=nvVioletDrapes(nvEndDirection);
        // Preserve the dim, unknown End atmosphere. High auroras glow but
        // bright colors never erase the underlying sky texture.
        float baseGlow=0.76+0.24*smoothstep(0.01,0.15,length(original.rgb));
        vec3 haze=vec3(0.008,0.006,0.014)*(0.35+0.65*smoothstep(-0.10,0.25,nvEndDirection.y));
        vec3 shade=original.rgb + haze + aurora*baseGlow;
        fragColor=vec4(min(shade,vec3(0.92)),original.a);
        return;
    }
    fragColor=original;
}
