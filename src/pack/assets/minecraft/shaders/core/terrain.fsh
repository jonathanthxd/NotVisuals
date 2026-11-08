#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:fog.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:texture_sampling.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:terrainglobals.glsl>
#ifndef MULTIDRAW_TERRAIN
    #include <minecraft:chunksection.glsl>
#endif
uniform sampler2D Sampler0;
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
layout(location = 2) in vec4 vertexColor;
layout(location = 3) in vec2 texCoord0;
layout(location = 4) in float chunkVisibility;
#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

// End fog color in Minecraft Java 26.3 dimension_type is #181318.
// Distinctly match the nearly black/purple End color; never infer dragon state.
bool nvIsEndFog(vec3 c) {
    vec3 endBase=vec3(24.0,19.0,24.0)/255.0;
    return distance(c,endBase)<0.047;
}

// The fight region is centered at 0,0; outer islands begin far away. This is
// a location-based artistic reveal, NOT detection of the dragon being defeated.
vec3 nvEndFogColor(vec3 base) {
    vec2 playerXZ=vec2(float(CameraBlockPos.x),float(CameraBlockPos.z));
    float outer=smoothstep(720.0,1150.0,length(playerXZ));
    vec3 central=vec3(0.073,0.069,0.077); // dark charcoal, almost neutral
    vec3 distant=vec3(0.100,0.079,0.127); // gentle amethyst only outside
    return mix(base,mix(central,distant,outer),0.78);
}

// R19 sulfur cave atmosphere: subdued golden-green fog. Biome-derived
// fog color is only a heuristic; no shader has a block or biome ID here.
bool nvSulfurCaveFog(vec3 c){
    vec3 sulfurAir=vec3(140.0,184.0,49.0)/255.0;
    return distance(c,sulfurAir)<0.12 && c.g>c.r*1.12 &&
           c.b<c.g*0.53;
}
vec4 calculateFinalColor(vec4 color) {
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif
    if(nvIsEndFog(FogColor.rgb)) {
        // Keep vanilla fog start/end and the dragon encounter's fog distance.
        vec3 target=nvEndFogColor(FogColor.rgb);
        #ifdef OIT_ACCUMULATE
        fogColor.rgb=target*color.a;
        #else
        fogColor.rgb=target;
        #endif
    }
    if(nvSulfurCaveFog(FogColor.rgb)){
        vec3 muted=mix(FogColor.rgb,vec3(0.37,0.45,0.19),0.22);
        #ifdef OIT_ACCUMULATE
        fogColor.rgb=muted*color.a;
        #else
        fogColor.rgb=muted;
        #endif
    }
    return apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
}
// R4: the GPU marker ID must survive nearest-neighbor sampling and JFA.
// Marker IDs are encoded in the original RGB8 palette; the blue channel encodes a class.
int nvClass(vec4 c) {
    vec3 b=round(clamp(c.rgb,0.0,1.0)*255.0);
    if(abs(b.g-76.0)>2.0) return 0;
    float row=0.0;
    if(abs(b.r-195.0)<=2.0) row=0.0;
    else if(abs(b.r-211.0)<=2.0) row=26.0;
    else if(abs(b.r-227.0)<=2.0) row=52.0;
    else return 0;
    float local=round((b.b-16.0)/9.0);
    if(local<1.0 || local>26.0) return 0;
    if(abs(b.b-(16.0+local*9.0))>2.0) return 0;
    int cls=int(row+local);
    return cls<=53 ? cls : 0;
}
bool nvIsRadianceMarker(vec4 src) { return nvClass(src) > 0; }

void main() {
    // Probe only Radiance ID texels at atlas mip 0; normal rendering below
    // still uses vanilla RGSS/mipmap sampling. Tiny torches previously lost
    // the exact RGB ID under mipmapping or rotated-grid supersampling.
    ivec2 nvAtlasSize = textureSize(Sampler0, 0);
    ivec2 nvAtlasTexel = clamp(ivec2(floor(texCoord0 * vec2(nvAtlasSize))),
                              ivec2(0), nvAtlasSize - ivec2(1));
    vec4 nvRawMarker = texelFetch(Sampler0, nvAtlasTexel, 0);
    vec4 texel = (UseRgss == 1 ? sampleRGSS(Sampler0, texCoord0, 1.0f / TextureSize) : sampleNearest(Sampler0, texCoord0, 1.0f / TextureSize));
    // R3 probes bypass block light/fog to retain exact marker RGB in raw framebuffer.
    // This is an UNSUPPORTED core shader override, and must be runtime-QAed with ShaderC.
    if (nvIsRadianceMarker(nvRawMarker)) {
        #ifdef OIT_ALPHA_ONLY
        executeAlphaOnlyPhase(gl_FragCoord.z, 1.0);
        #else
        fragColor = vec4(nvRawMarker.rgb, 1.0);
        #endif
        return;
    }
    vec4 color = texel * vertexColor;
    #ifndef OIT_ALPHA_ONLY
    color = mix(FogColor * vec4(1, 1, 1, color.a), color, chunkVisibility);
    #endif
    #ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) discard;
    #endif
    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif
}
