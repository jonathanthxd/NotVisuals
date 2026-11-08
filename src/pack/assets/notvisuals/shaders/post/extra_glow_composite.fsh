#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D SceneSampler;
uniform sampler2D BloomSmallSampler;
uniform sampler2D BloomMediumSampler;
uniform sampler2D BloomLargeSampler;

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

float luma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec4 scene = texture(SceneSampler, texCoord);
    vec3 smallGlow = texture(BloomSmallSampler, texCoord).rgb;
    vec3 mediumGlow = texture(BloomMediumSampler, texCoord).rgb;
    vec3 largeGlow = texture(BloomLargeSampler, texCoord).rgb;

    vec3 glow = smallGlow * 0.38 + mediumGlow * 0.26 + largeGlow * 0.16;
    float sceneLum = luma709(scene.rgb);
    float boost = 1.0 + (1.0 - smoothstep(0.12, 0.65, sceneLum)) * 0.20;
    vec3 c = scene.rgb + glow * boost * (vec3(1.0) - scene.rgb * 0.18);
    c = c / (vec3(1.0) + max(c - vec3(0.95), vec3(0.0)) * 0.16);

    fragColor = vec4(max(c, vec3(0.0)), scene.a);
}
