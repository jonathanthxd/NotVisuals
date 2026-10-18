#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>

// Skyflow: sky geometry only. Vanilla supplies environmental colour, not time.
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
layout(location = 0) out vec4 fragColor;

void main() {
    float horizon = total_fog_value(sphericalVertexDistance, cylindricalVertexDistance,
                                  0.0, FogSkyEnd, FogSkyEnd, FogSkyEnd);
    float curve = mix(horizon, smoothstep(0.0, 1.0, horizon), 0.35);
    vec3 sky = ColorModulator.rgb;
    float warm = smoothstep(0.015, 0.20, sky.r - sky.b);
    float chroma = max(sky.r, max(sky.g, sky.b)) - min(sky.r, min(sky.g, sky.b));
    float clear = smoothstep(0.025, 0.18, chroma);
    vec3 zenithTint = mix(vec3(0.93, 0.975, 1.015), vec3(1.015, 0.965, 1.015), warm);
    vec3 zenith = sky * mix(vec3(1.0), zenithTint, clear);
    vec3 horizonColor = FogColor.rgb * mix(vec3(1.0), vec3(1.015, 0.99, 0.985), warm * clear);
    vec3 result = mix(zenith, horizonColor, curve * FogColor.a);
    vec3 baseline = mix(sky, FogColor.rgb, horizon * FogColor.a);
    // Never create an HDR highlight or a large luminance gain in the sky.
    result = clamp(result, max(vec3(0.0), baseline - 0.045), baseline + 0.015);
    fragColor = vec4(result, ColorModulator.a);
}
