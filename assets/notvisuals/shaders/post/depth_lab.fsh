#version 330
#extension GL_ARB_separate_shader_objects : require

// Explicit, opt-in laboratory: overlay cyan at depth discontinuities.
// This file deliberately makes no claim of depth reconstruction or SSAO.
uniform sampler2D InSampler;
uniform sampler2D MainDepthSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

const float EDGE_THRESHOLD = 0.003;
void main() {
    vec2 px = 1.0 / vec2(textureSize(MainDepthSampler, 0));
    float z = texture(MainDepthSampler, texCoord).r;
    float za = texture(MainDepthSampler, clamp(texCoord + vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).r;
    float zb = texture(MainDepthSampler, clamp(texCoord - vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).r;
    float zc = texture(MainDepthSampler, clamp(texCoord + vec2(0.0, px.y), vec2(0.0), vec2(1.0))).r;
    float zd = texture(MainDepthSampler, clamp(texCoord - vec2(0.0, px.y), vec2(0.0), vec2(1.0))).r;
    float jump = max(max(abs(z - za), abs(z - zb)), max(abs(z - zc), abs(z - zd)));
    // Reject extreme clearing values until runtime establishes API depth conventions.
    float valid = step(0.001, z) * (1.0 - step(0.999, z));
    float edge = smoothstep(EDGE_THRESHOLD, EDGE_THRESHOLD * 8.0, jump) * valid;
    vec4 original = texture(InSampler, texCoord);
    fragColor = vec4(mix(original.rgb, vec3(0.05, 0.85, 1.0), edge * 0.75), original.a);
}
