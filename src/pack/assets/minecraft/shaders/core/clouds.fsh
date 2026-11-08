#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:fog.glsl>
#include <minecraft:oit.glsl>

layout(std140) uniform CloudInfo {
    vec4 CloudColor;
    vec3 CloudOffset;
    vec3 CellSize;
};
layout(location = 0) in float vertexDistance;
layout(location = 1) in vec4 vertexColor;
#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

void main() {
    vec4 color = vertexColor;
    // Coverage is kept identical to Vanilla in every transparency phase.
    #ifndef OIT_DEPTH_BOUNDS
    color.a *= 1.0 - linear_fog_value(vertexDistance, 0.0, FogCloudsEnd);
    #endif
    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    // CloudInfo is the existing 26.3 block also read by clouds.vsh.
    // Recover face shading instead of classifying white world pixels as clouds.
    float ambient = dot(CloudColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    float face = clamp(dot(vertexColor.rgb, vec3(0.2126, 0.7152, 0.0722)) / max(ambient, 0.0001), 0.0, 1.0);
    float underside = 1.0 - smoothstep(0.68, 0.98, face);
    float warm = smoothstep(0.02, 0.22, CloudColor.r - CloudColor.b);
    vec3 shadowTint = mix(vec3(0.95, 0.975, 1.025), vec3(0.985, 0.95, 1.02), warm);
    vec3 topTint = mix(vec3(1.0), vec3(1.015, 0.99, 0.98), warm);
    vec3 tint = mix(topTint, shadowTint, underside);
    // A small lift softens Vanilla's dark base without washing out its top.
    color.rgb *= tint * (1.0 + underside * 0.035);
    color.rgb = min(color.rgb, vertexColor.rgb + vec3(0.025));
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    #endif
    fragColor = color;
    #endif
}
