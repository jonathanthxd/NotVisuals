#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D SceneSampler;
uniform sampler2D BloomTinySampler;
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
    vec3 tinyGlow = texture(BloomTinySampler, texCoord).rgb;
    vec3 smallGlow = texture(BloomSmallSampler, texCoord).rgb;
    vec3 mediumGlow = texture(BloomMediumSampler, texCoord).rgb;
    vec3 largeGlow = texture(BloomLargeSampler, texCoord).rgb;

    float sceneLum = luma709(scene.rgb);
    float darkScene = 1.0 - smoothstep(0.10, 0.58, sceneLum);
    float brightScene = smoothstep(0.62, 0.96, sceneLum);

    vec3 glow = tinyGlow * 0.54 + smallGlow * 0.38 + mediumGlow * 0.26 + largeGlow * 0.15;
    float glowLum = luma709(glow);
    float colorEnergy = max(glow.r, max(glow.g, glow.b)) - min(glow.r, min(glow.g, glow.b));
    glow = mix(vec3(glowLum), glow, 1.0 + 0.10 * smoothstep(0.05, 0.40, colorEnergy));

    float strength = 0.95 + darkScene * 0.30 - brightScene * 0.06;
    vec3 c = scene.rgb + glow * strength * (vec3(1.0) - scene.rgb * 0.22);

    float halo = smoothstep(0.08, 0.62, glowLum);
    c += largeGlow * halo * 0.040;
    c = c / (vec3(1.0) + max(c - vec3(0.94), vec3(0.0)) * 0.17);

    fragColor = vec4(max(c, vec3(0.0)), scene.a);
}
