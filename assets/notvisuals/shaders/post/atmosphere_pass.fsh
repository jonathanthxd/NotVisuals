#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D InSampler;

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

float luma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec2 texel = 1.0 / vec2(textureSize(InSampler, 0));
    vec4 src = texture(InSampler, texCoord);
    vec3 c = src.rgb;
    float lum = luma709(c);

    vec3 n1 = texture(InSampler, texCoord + vec2(texel.x * 2.0, 0.0)).rgb;
    vec3 n2 = texture(InSampler, texCoord - vec2(texel.x * 2.0, 0.0)).rgb;
    vec3 n3 = texture(InSampler, texCoord + vec2(0.0, texel.y * 2.0)).rgb;
    vec3 n4 = texture(InSampler, texCoord - vec2(0.0, texel.y * 2.0)).rgb;
    vec3 fine = (n1 + n2 + n3 + n4) * 0.25;

    float detail = length(c - fine);

    float blue = smoothstep(0.018, 0.17, c.b - c.r) * smoothstep(-0.02, 0.13, c.g - c.r);
    float mid = smoothstep(0.12, 0.31, lum) * (1.0 - smoothstep(0.60, 0.82, lum));
    float textured = smoothstep(0.006, 0.055, detail) * (1.0 - smoothstep(0.16, 0.38, detail));
    float water = blue * mid * textured;

    float waterLum = luma709(c);
    vec3 tameWater = mix(c, vec3(waterLum), 0.16);
    tameWater *= vec3(1.015, 1.005, 0.945);
    tameWater *= 0.975;
    c = mix(c, tameWater, water * 0.72);

    // Cloud styling now belongs to core/clouds.fsh, never to white-pixel masks.

    fragColor = vec4(max(c, vec3(0.0)), src.a);
}
