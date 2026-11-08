#version 330
#extension GL_ARB_separate_shader_objects : require
#include <notvisuals:depth_edges.glsl>

// Explicit, opt-in laboratory: overlay cyan at depth discontinuities.
// This file deliberately makes no claim of depth reconstruction or SSAO.
uniform sampler2D InSampler;
uniform sampler2D MainDepthSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    float edge = nvDepthEdge(MainDepthSampler, texCoord);
    vec4 original = texture(InSampler, texCoord);
    fragColor = vec4(mix(original.rgb, vec3(0.05, 0.85, 1.0), edge * 0.75), original.a);
}
