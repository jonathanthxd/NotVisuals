#version 330
#extension GL_ARB_separate_shader_objects : require
#ifdef GLINT
#include <minecraft:globals.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>
uniform sampler2D Sampler0;
#ifdef GLINT
uniform sampler2D GlintSampler;
#endif
#ifndef OIT_ALPHA_ONLY
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#endif
layout(location = 2) in vec4 vertexColor;
#ifndef OIT_ALPHA_ONLY
layout(location = 3) in vec4 lightMapColor;
layout(location = 4) in vec4 overlayColor;
#endif
layout(location = 5) in vec2 texCoord0;
#ifdef GLINT
layout(location = 6) in vec2 texCoordGlint;
#endif
#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif
#ifndef OIT_ALPHA_ONLY
vec4 calculateFinalColor(vec4 color) {
 color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
 color *= lightMapColor;
 #ifdef GLINT
 vec4 glintColor = GlintAlpha * texture(GlintSampler, texCoordGlint);
 color.rgb += glintColor.rgb * glintColor.rgb;
 #endif
 #ifdef OIT_ACCUMULATE
 color = sampleColorForAccumulation(color);
 vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
 #else
 vec4 fogColor = FogColor;
 #endif
 return apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance,FogEnvironmentalStart,FogEnvironmentalEnd,FogRenderDistanceStart,FogRenderDistanceEnd,fogColor);
}
#endif
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
bool nvItemMarker(vec4 src) { return nvClass(src) > 0; }

void main() {
 // Mip-zero marker probe for held item models; normal item sampling below unchanged.
 ivec2 nvAtlasSize = textureSize(Sampler0,0);
 ivec2 nvAtlasTexel=clamp(ivec2(floor(texCoord0*vec2(nvAtlasSize))),ivec2(0),nvAtlasSize-ivec2(1));
 vec4 nvRawMarker=texelFetch(Sampler0,nvAtlasTexel,0);
 vec4 color=texture(Sampler0,texCoord0);
 if (nvItemMarker(nvRawMarker)) {
   #ifdef OIT_ALPHA_ONLY
   executeAlphaOnlyPhase(gl_FragCoord.z,1.0);
   #else
   fragColor=vec4(nvRawMarker.rgb,1.0);
   #endif
   return;
 }
 #ifdef ALPHA_CUTOUT
 if(color.a<ALPHA_CUTOUT) discard;
 #endif
 color*=vertexColor*ColorModulator;
 #ifdef GLINT
 color.a=max(color.a,GlintAlpha);
 #endif
 #ifdef OIT_ALPHA_ONLY
 executeAlphaOnlyPhase(gl_FragCoord.z,color.a);
 #else
 fragColor=calculateFinalColor(color);
 #endif
}
