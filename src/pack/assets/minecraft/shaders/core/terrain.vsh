#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:fog.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:sample_lightmap.glsl>
#include <minecraft:terrainglobals.glsl>
#ifndef MULTIDRAW_TERRAIN
    #include <minecraft:chunksection.glsl>
#endif

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in ivec2 UV2;
#ifdef MULTIDRAW_TERRAIN
layout(location = 4) in ivec3 ChunkPosition;
layout(location = 5) in float ChunkVisibility;
#endif

#ifndef OIT_ALPHA_ONLY
uniform sampler2D Sampler2;
#endif
// Water/lava are generated chunk meshes, not JSON block models. Their
// identification below is conservative and EXPERIMENTAL: atlas + tint + top Y.
uniform sampler2D Sampler0;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
layout(location = 2) out vec4 vertexColor;
layout(location = 3) out vec2 texCoord0;
layout(location = 4) out float chunkVisibility;

float nvSineBlend(vec2 p,float time,float freq,float a,float b){
    return sin(time*freq+dot(p,vec2(a,b))) +
           0.33*sin(time*freq*0.57+dot(p,vec2(-b*1.7,a*1.25)));
}

// A full 16x16x16 leaf cube in NotVisuals uses 0.023/15.977 model coordinates
// instead of 0/16. It is indistinguishable at gameplay scale yet gives a
// reliable vertex-only block-type signature without purple marker textures.
bool nvIsEncodedLeaf(vec3 p){
    vec3 err=abs(p-round(p));
    return all(greaterThan(err,vec3(0.00090))) &&
           all(lessThan(err,vec3(0.00215)));
}

// Classify only the raised TOP surfaces of fluid meshes. No fluid block ID is
// provided by Minecraft's terrain vertex interface in 26.3; thus these are
// color/atlas heuristics, not a guarantee for every biome or shader addon.
vec3 nvWavingDisplacement(vec3 localPos,vec3 worldPos,vec4 rgba,vec2 uv){
    float ticks=GameTime*24000.0;
    vec2 p=worldPos.xz;
    if(nvIsEncodedLeaf(localPos)){
        // R13 Wind Loom: foliage branches move as locally phased clusters,
        // with occasional gusts and fine high-frequency leaf flutter.
        // Base vertices stay near the branch; treetop vertices travel farther.
        vec3 block=floor(worldPos+vec3(0.001));
        float phase=dot(block.xz,vec2(0.103,0.071))+block.y*0.047;
        float yfrac=fract(localPos.y);
        float upper=yfrac>0.5?1.0:0.16;
        float sway=sin(ticks*0.052+dot(p,vec2(0.24,0.16))+phase);
        float crossWind=sin(ticks*0.036+dot(p,vec2(-0.13,0.22))-phase*0.33);
        float flutter=sin(ticks*0.171+dot(p,vec2(0.88,-0.54))+phase*1.3);
        float gust=0.71+0.29*sin(ticks*0.0085+dot(p,vec2(0.10,0.064)));
        vec2 direction=vec2(0.82,0.57);
        vec2 shift=(direction*(sway*0.060+flutter*0.011)+
                   vec2(-direction.y,direction.x)*crossWind*0.028)*upper*gust;
        float buoyancy=0.010*upper*sin(ticks*0.066+p.x*0.31+p.y*0.26+phase);
        return vec3(shift.x,buoyancy,shift.y);
    }
    // Chunk-fluid top vertices are generally ~0.75..0.90 of a block tall.
    // The additional horizontal-corner check avoids arbitrary slabs/plants.
    vec3 fr=abs(localPos-round(localPos));
    float fractional=fract(localPos.y);
    bool fluidTop=fractional>0.68 && fractional<0.918 &&
                  fr.x<0.005 && fr.z<0.005;
    if(!fluidTop) return vec3(0.0);
    bool water=rgba.b>rgba.r*1.22 && rgba.g>rgba.r*1.10 && rgba.b>0.33;
    if(water){
        // R13 Shallow Interference: two diagonal travelling currents plus
        // low-amplitude crestlets. No lateral movement means no shore gaps.
        float longWave=sin(ticks*0.058+dot(p,vec2(0.58,0.31)))*0.022;
        float crossWave=sin(ticks*0.075+dot(p,vec2(-0.35,0.49)))*0.011;
        float crestlet=sin(ticks*0.124+dot(p,vec2(1.10,-0.79)))*0.004;
        return vec3(0.0,longWave+crossWave+crestlet,0.0);
    }
    // Sample original atlas in a vertex shader to avoid moving snow layers,
    // slabs, farmland or translucent stone with a similar fractional height.
    // Lava is orange in the original atlas; fluids remain behind their depth.
    vec3 tex=textureLod(Sampler0,uv,0.0).rgb;
    bool lava=tex.r>0.58 && tex.r>tex.g*1.19 && tex.g>tex.b*1.65 &&
              tex.g>0.19 && rgba.r>=rgba.b*0.85;
    if(lava){
        // R13 Molten Pulse: slow viscosity bands and occasional uplift;
        // deliberately unlike the fast intersecting water surface currents.
        float heavy=sin(ticks*0.025+dot(p,vec2(0.29,0.16)))*0.014;
        float swell=sin(ticks*0.039+dot(p,vec2(-0.17,0.23)))*0.006;
        float pressure=sin(ticks*0.013+dot(p,vec2(0.095,0.11)))*0.004;
        return vec3(0.0,heavy+swell+pressure,0.0);
    }
    return vec3(0.0);
}

void main(){
    vec3 world=Position+ChunkPosition;
    vec3 displaced=Position+nvWavingDisplacement(Position,world,Color,UV0);
    vec3 pos=displaced+(ChunkPosition-CameraBlockPos)+CameraOffset;
    gl_Position=ProjMat*ModelViewMat*vec4(pos,1.0);
    sphericalVertexDistance=fog_spherical_distance(pos);
    cylindricalVertexDistance=fog_cylindrical_distance(pos);
    #ifndef OIT_ALPHA_ONLY
    vertexColor=Color*sample_lightmap(Sampler2,UV2);
    #else
    vertexColor=Color;
    #endif
    texCoord0=UV0;
    const float chunkFullyVisibleRange=16.0;
    float dist=length(pos);
    chunkVisibility=mix(1.0,ChunkVisibility,clamp((dist-chunkFullyVisibleRange)/chunkFullyVisibleRange,0.0,1.0));
}
