#version 330
#extension GL_ARB_separate_shader_objects : require
// NotVisuals Radiance R9 final candidate - high-chroma color, unchanged falloff.
// VIEW-DEPENDENT reconstruction: sources are visible-frame appearances, not
// authenticated Minecraft emitters; off-screen lights and world GI are absent.
uniform sampler2D SceneSampler;
uniform sampler2D MainDepthSampler;
uniform sampler2D NearestSeedSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;
// R4 high-precision seed data: normalized source UV is stored in 12 bits/axis,
// 24 bits encoded in RGB bytes; alpha is the exact 8-bit material class.
// No dependence on undocumented float-render-target extensions.
vec4 nvPackSeed(vec2 uv, int cls) {
    ivec2 q=ivec2(round(clamp(uv,vec2(0.0),vec2(1.0))*4095.0));
    int packedUVBits=(q.x<<12)|q.y;
    ivec3 rgb=ivec3((packedUVBits>>16)&255,(packedUVBits>>8)&255,packedUVBits&255);
    return vec4(vec3(rgb)/255.0,float(cls)/255.0);
}
vec2 nvUnpackUV(vec4 seed) {
    ivec3 c=ivec3(round(clamp(seed.rgb,0.0,1.0)*255.0));
    int packedUVBits=(c.x<<16)|(c.y<<8)|c.z;
    return vec2(float((packedUVBits>>12)&4095),float(packedUVBits&4095))/4095.0;
}
int nvUnpackClass(vec4 seed) {
    return int(round(clamp(seed.a,0.0,1.0)*255.0));
}


// ShaderC 26.3 post-processing deliberately does NOT bind the vanilla
// Projection UBO by default. Including minecraft:projection.glsl in this
// shader caused `Unable to find shader defined uniform (Projection)` and
// Minecraft to disable the entire resource pack (latest.log, 20:45:38).
// Do not reintroduce that include or a built-in world Projection UBO here.
// The post-effect API currently exposes scene depth, NOT the live camera FOV.
// This is intentionally a view-dependent perspective approximation rather
// than falsely advertising exact world-space positions.
const float NV_TAN_HALF_FOV = 0.7002075; // tan(70 degrees / 2).
const float NV_NEAR_PLANE = 0.05;
vec3 viewPosition(vec2 uv, float depth) {
    // 26.3 RenderPearl uses reversed-Z. Depth clear is normally ~0.
    // Approximate distance from inverse depth; never fetch an unbound UBO.
    float viewDistance = min(128.0, NV_NEAR_PLANE / max(depth, 0.00002));
    vec2 frameSize = vec2(textureSize(SceneSampler, 0));
    float aspect = frameSize.x / max(1.0, frameSize.y);
    vec2 ndc = uv * 2.0 - 1.0;
    return vec3(ndc.x * viewDistance * NV_TAN_HALF_FOV * aspect,
                ndc.y * viewDistance * NV_TAN_HALF_FOV,
                -viewDistance);
}
// Choose the less discontinuous depth derivative on each axis. At a silhouette
// the normal becomes uncertain: fade towards camera-facing, not a huge flickering tangent.
vec3 viewNormal(vec2 uv, vec3 p) {
    vec2 px=1.0/vec2(textureSize(MainDepthSampler,0));
    float raw=texture(MainDepthSampler,uv).r;
    float l=texture(MainDepthSampler,clamp(uv-vec2(px.x,0),vec2(0),vec2(1))).r;
    float r=texture(MainDepthSampler,clamp(uv+vec2(px.x,0),vec2(0),vec2(1))).r;
    float b=texture(MainDepthSampler,clamp(uv-vec2(0,px.y),vec2(0),vec2(1))).r;
    float t=texture(MainDepthSampler,clamp(uv+vec2(0,px.y),vec2(0),vec2(1))).r;
    bool takeR=abs(raw-r)<abs(raw-l);
    bool takeT=abs(raw-t)<abs(raw-b);
    vec2 uvX=clamp(uv+vec2(takeR?px.x:-px.x,0),vec2(0),vec2(1));
    vec2 uvY=clamp(uv+vec2(0,takeT?px.y:-px.y),vec2(0),vec2(1));
    float dX=takeR?r:l;
    float dY=takeT?t:b;
    vec3 fallback=normalize(-p);
    if(dX<0.00002 || dY<0.00002) return fallback;
    vec3 a=(viewPosition(uvX,dX)-p)*(takeR?1.0:-1.0);
    vec3 c=(viewPosition(uvY,dY)-p)*(takeT?1.0:-1.0);
    vec3 n=cross(a,c);
    float ns=length(n);
    if(ns<0.000001) return fallback;
    n/=ns;
    if(dot(n,fallback)<0.0) n=-n;
    float confidence=1.0-smoothstep(0.025,0.25,max(abs(dX-raw),abs(dY-raw))/max(raw,0.00002));
    return normalize(mix(fallback,n,0.80*confidence));
}
// Conservative, continuous shadow confidence. Hard screen-space tests generate
// moving striped shadows because hidden geometry is not available to this pack.
float shadowVisibility(vec2 fromUV, vec2 toUV, vec3 p, vec3 l) {
    float occlusion=0.0;
    for(int j=1;j<=4;j++) {
        float t=float(j)/5.0;
        vec2 uv=mix(fromUV,toUV,t);
        if(any(lessThan(uv,vec2(0.002))) || any(greaterThan(uv,vec2(0.998))))continue;
        float d=texture(MainDepthSampler,uv).r;
        if(d<=0.00002 || d>=0.999999)continue;
        vec3 hit=viewPosition(uv,d);
        vec3 expected=mix(p,l,t);
        float margin=max(0.18,0.045*length(expected));
        float obstruction=length(expected)-length(hit);
        // Ignore small/noisy depth differences; softer response over transitions.
        occlusion+=smoothstep(margin,margin*3.5,obstruction);
    }
    // R3 could flicker between a factor of 1.0 and 0.22. R4 never jumps this far.
    return 1.0-0.24*clamp(occlusion*0.25,0.0,1.0);
}
void main() {
    vec4 scene = texture(SceneSampler, texCoord);
    float depth = texture(MainDepthSampler, texCoord).r;
    if (depth < 0.00002 || depth > 0.999999) { fragColor = scene; return; }
    vec3 surfacePos = viewPosition(texCoord,depth);
    vec3 normal = viewNormal(texCoord, surfacePos);
    vec3 irradiance = vec3(0.0);
    // Sample spatially distributed neighborhoods of the nearest-source field.
    // The field contains individual visible *marker faces*, not one emitter per block.
    // R6 groups nearby faces of the same emission class before shading, avoiding
    // duplicated brightness and abrupt changes when the camera rotates.
    // R8 extended neighborhood improves independent source mixtures (cyan +
    // warm + violet). This remains screen-space, not full 3D source lookup.
    const vec2 taps[21] = vec2[](
        vec2(0.0,0.0),vec2(0.065,0.0),vec2(-0.065,0.0),
        vec2(0.0,0.065),vec2(0.0,-0.065),
        vec2(0.065,0.065),vec2(-0.065,0.065),
        vec2(0.065,-0.065),vec2(-0.065,-0.065),
        vec2(0.155,0.0),vec2(-0.155,0.0),
        vec2(0.0,0.155),vec2(0.0,-0.155),
        vec2(0.125,0.080),vec2(-0.125,0.080),
        vec2(0.125,-0.080),vec2(-0.125,-0.080),
        vec2(0.080,0.125),vec2(-0.080,0.125),
        vec2(0.080,-0.125),vec2(-0.080,-0.125));
    vec3 sourcePosition[21];
    vec2 sourceUVs[21];
    int sourceClasses[21];
    float sourceCounts[21];
    int sourceCount = 0;
    // 1. Gather candidates. Cluster marker faces of the *same* block/material
    // when they lie within ~0.85 reconstructed world units. Adjacent identical
    // blocks remain independent in most configurations (~1 block spacing).
    for (int i = 0; i < 21; ++i) {
        vec2 probe = clamp(texCoord + taps[i], vec2(0.001),vec2(0.999));
        // R13 nearest-texel read; never bilinearly blend packed source UVs.
        ivec2 fieldSize=textureSize(NearestSeedSampler,0);
        ivec2 fieldXY=clamp(ivec2(floor(probe*vec2(fieldSize))),ivec2(0),fieldSize-ivec2(1));
        vec4 seed = texelFetch(NearestSeedSampler,fieldXY,0);
        int cls = nvUnpackClass(seed);
        if (cls < 1 || cls > 53) continue;
        vec2 seedUV = nvUnpackUV(seed);
        float zd = texture(MainDepthSampler, seedUV).r;
        if (zd < 0.00002 || zd > 0.999999) continue;
        vec3 candidate = viewPosition(seedUV, zd);
        float distToSurface = distance(candidate, surfacePos);
        if (distToSurface > 14.0 || distToSurface < 0.015) continue;
        int slot = -1;
        for (int j=0; j<sourceCount; ++j) {
            if (sourceClasses[j] == cls && distance(sourcePosition[j],candidate) < 0.85) {
                slot=j;break;
            }
        }
        if (slot >= 0) {
            // Reconstruct an averaged position from independent marker faces;
            // changes to the visible face no longer multiply the light energy.
            float n=sourceCounts[slot];
            sourcePosition[slot]=(sourcePosition[slot]*n+candidate)/(n+1.0);
            sourceUVs[slot]=(sourceUVs[slot]*n+seedUV)/(n+1.0);
            sourceCounts[slot]=n+1.0;
        } else {
            sourcePosition[sourceCount]=candidate;
            sourceUVs[sourceCount]=seedUV;
            sourceClasses[sourceCount]=cls;
            sourceCounts[sourceCount]=1.0;
            ++sourceCount;
        }
    }
    // 2. Shade each *cluster* once. Never read the marker RGB from a
    // bilinear framebuffer: the class is propagated exactly through RGBA8.
    for (int i=0; i<sourceCount; ++i) {
        vec2 sourceUV=sourceUVs[i];
        vec3 lightPos=sourcePosition[i];
        vec3 delta=lightPos-surfacePos;
        float radius=length(delta);
        if (radius>14.0 || radius<0.025) continue;
        vec3 dir=delta/radius;
        float lambert=max(dot(normal,dir),0.0);
        float diffuse=mix(0.19,1.0,lambert);
        int classId=sourceClasses[i];
        vec3 tint=vec3(1.0);
        float strength=1.0;
        if(classId==1){tint=vec3(1.00,.74,.40);strength=1.00;}          // glowstone warm
        else if(classId==2){tint=vec3(.40,.92,1.18);strength=1.08;}      // sea lantern
        else if(classId==3){tint=vec3(1.00,.50,.24);strength=1.04;}      // lava/magma
        else if(classId==4){tint=vec3(1.00,.84,.46);strength=1.02;}      // shroomlight
        else if(classId==5){tint=vec3(.56,1.08,.62);strength=1.08;}      // froglight A
        else if(classId==6){tint=vec3(.92,.70,1.08);strength=1.06;}      // froglight B
        else if(classId==7){tint=vec3(1.00,.40,.20);strength=1.04;}
        else if(classId==8){tint=vec3(1.00,.66,.28);strength=1.03;}
        else if(classId==9){tint=vec3(1.00,.63,.32);strength=1.06;}      // torch warm
        else if(classId==10){tint=vec3(.08,.98,1.55);strength=1.58;}     // soul torch vivid cyan
        else if(classId==11){tint=vec3(1.00,.69,.36);strength=1.05;}
        else if(classId==12){tint=vec3(.10,.94,1.48);strength=1.48;}     // soul lantern vivid cyan
        else if(classId==13){tint=vec3(.18,1.46,.20);strength=1.62;}     // copper torch / lantern vivid green
        else if(classId==14){tint=vec3(.46,1.30,.36);strength=1.52;}     // exposed copper
        else if(classId==15){tint=vec3(.22,1.16,.74);strength=1.44;}     // weathered copper
        else if(classId==16){tint=vec3(.12,.96,.90);strength=1.34;}      // oxidized copper
        else if(classId==17){tint=vec3(1.00,.24,.18);strength=1.14;}     // redstone torch vivid red
        else if(classId==18){tint=vec3(.90,.96,1.04);strength=1.06;}     // end rod

        else if(classId==19){tint=vec3(1.00,.66,.36);strength=.44;}   // one lit candle
        else if(classId==20){tint=vec3(1.00,.66,.34);strength=.70;}   // two candles
        else if(classId==21){tint=vec3(1.00,.64,.32);strength=.90;}   // three candles
        else if(classId==22){tint=vec3(1.00,.64,.30);strength=1.10;}  // four candles
        else if(classId==23){tint=vec3(1.00,.52,.24);strength=1.12;}  // active furnace family
        else if(classId==24){tint=vec3(1.00,.67,.28);strength=1.06;}  // jack-o-lantern
        else if(classId==25){tint=vec3(.38,1.16,.48);strength=.60;}   // glow lichen / berries
        else if(classId==26){tint=vec3(.72,.28,1.22);strength=.80;}   // crying obsidian
        else if(classId==27){tint=vec3(.72,.26,1.28);strength=.44;}   // respawn charge 1
        else if(classId==28){tint=vec3(.76,.27,1.30);strength=.74;}   // charge 2
        else if(classId==29){tint=vec3(.80,.28,1.38);strength=1.00;}  // charge 3
        else if(classId==30){tint=vec3(.84,.30,1.46);strength=1.26;}  // charge 4
        else if(classId==31){tint=vec3(.22,1.12,1.24);strength=.40;}  // 1 sea pickle
        else if(classId==32){tint=vec3(.22,1.14,1.28);strength=.66;}  // 2 sea pickles
        else if(classId==33){tint=vec3(.20,1.16,1.36);strength=.91;}  // 3 sea pickles
        else if(classId==34){tint=vec3(.18,1.18,1.40);strength=1.20;} // 4 sea pickles
        else if(classId==35){tint=vec3(.70,.28,1.35);strength=1.15;}  // Nether portal experimental
        else if(classId==36){tint=vec3(1.00,.55,.26);strength=.95;}  // reserved for fire
        else if(classId==37){tint=vec3(.08,.94,1.52);strength=1.18;}  // soul fire experimental
        else if(classId==38){tint=vec3(.58,.36,.95);strength=.36;}   // enchanting table ambience
        else if(classId==39){tint=vec3(.34,.30,.90);strength=.46;}   // ender chest ambience
        else if(classId==40){tint=vec3(1.00,.40,.18);strength=.33;}   // weak magma glow
        else if(classId==41){tint=vec3(1.00,.89,.50);strength=.64;}  // firefly bush: pale gold
        // R19 Material Soul: short-radius ore bounce. NOT vanilla block light.
        else if(classId==42){tint=vec3(.34,.93,1.27);strength=.62;} // diamond cyan
        else if(classId==43){tint=vec3(.27,1.18,.53);strength=.60;} // emerald green
        else if(classId==44){tint=vec3(1.19,.23,.21);strength=.61;} // redstone crimson
        else if(classId==45){tint=vec3(.30,.51,1.28);strength=.55;} // lapis blue
        else if(classId==46){tint=vec3(1.15,.78,.34);strength=.51;} // gold and gilded
        else if(classId==47){tint=vec3(1.00,.56,.35);strength=.43;} // copper
        else if(classId==48){tint=vec3(.90,.76,.62);strength=.34;} // iron warm white
        else if(classId==49){tint=vec3(1.00,.84,.65);strength=.43;} // nether quartz
        else if(classId==50){tint=vec3(.75,.34,.26);strength=.32;} // ancient debris
        else if(classId==51){tint=vec3(.60,.58,.63);strength=.20;} // coal only a hint
        else if(classId==52){tint=vec3(.75,.48,1.26);strength=.49;} // amethyst clusters
        else if(classId==53){tint=vec3(.22,.78,.88);strength=.30;} // sculk catalyst

        // R9 final candidate: strengthen chroma WITHOUT increasing light reach.
        // Work in luminance-preserving chroma space.  When a chroma channel
        // becomes negative, clamp and renormalize to the original luminance.
        // The classes and their original strength/falloff remain unchanged.
        float colorLuminance=dot(tint,vec3(0.2126,0.7152,0.0722));
        float chromaBoost=1.22; // saturated warm/red classes retain R7 appearance
        if(classId==10 || classId==12 || classId==37) chromaBoost=1.52; // soul cyan
        else if(classId==13 || classId==14 || classId==15 || classId==16) chromaBoost=1.50; // copper green/teal
        else if(classId==26 || (classId>=27 && classId<=30) || classId==35 || classId==38 || classId==39)
            chromaBoost=1.50; // purple/portal/magic
        else if(classId==2 || classId==31 || classId==32 || classId==33 || classId==34)
            chromaBoost=1.38; // underwater cyan
        else if(classId==18) chromaBoost=1.05; // white end rod remains neutral
        else if(classId==42 || classId==43 || classId==44 || classId==45 || classId==52 || classId==53) chromaBoost=1.40; // mineral color fidelity
        vec3 saturatedTint=max(vec3(0.0),vec3(colorLuminance)+(tint-vec3(colorLuminance))*chromaBoost);
        tint=saturatedTint*(colorLuminance/max(dot(saturatedTint,vec3(0.2126,0.7152,0.0722)),0.00001));
        float emitterRadius=11.0;
        if(classId>=19 && classId<=22)emitterRadius=4.5+0.85*float(classId-19);
        else if(classId==25 || classId==26)emitterRadius=5.5;
        else if(classId>=27 && classId<=30)emitterRadius=5.0+float(classId-27);
        else if(classId>=31 && classId<=34)emitterRadius=4.5+float(classId-31)*.9;
        else if(classId==38 || classId==39)emitterRadius=5.0;
        else if(classId==40)emitterRadius=4.0;
        else if(classId==41)emitterRadius=4.4;
        else if(classId>=42 && classId<=49)emitterRadius=4.2; // short local bounce
        else if(classId>=50 && classId<=51)emitterRadius=3.2;
        else if(classId==52)emitterRadius=3.85;
        else if(classId==53)emitterRadius=3.7;
        else if(classId==35)emitterRadius=9.0;
        // Existing R7 cubical emitters retain their visual identity, while
        // broad emissive surfaces get slightly less face-normal dependency.
        if(classId==1 || classId==2 || classId==5 || classId==6 || classId==25 || classId==35)diffuse=mix(diffuse,1.0,.24);
        float falloff=pow(max(0.0,1.0-radius/emitterRadius),2.0)/(1.0+radius*radius*0.055);
        float shade=shadowVisibility(texCoord,sourceUV,surfacePos,lightPos);
        float edge=min(min(sourceUV.x,1.0-sourceUV.x),min(sourceUV.y,1.0-sourceUV.y));
        float edgeWeight=smoothstep(0.005,0.065,edge);
        irradiance+=tint*(0.48*edgeWeight*strength)*diffuse*falloff*shade;
    }
    // Keep a conservative screen-space energy budget. Never put the result in
    // bloom itself: radiance is mixed into scene shading BEFORE Chromaglow.
    // R7 intentionally biases reflectance slightly towards neutral white so
    // strong cyan / green emitters do not collapse back into warm yellow.
    vec3 reflectance = clamp(mix(vec3(1.0), scene.rgb, 0.72) + vec3(0.04),vec3(0.10),vec3(1.0));
    // Gentle shoulder controls sudden local high-energy changes.
    vec3 energy=vec3(0.52)*(vec3(1.0)-exp(-irradiance/vec3(0.52)));
    vec3 outColor = scene.rgb + energy*reflectance;
    fragColor = vec4(outColor,scene.a);
}
