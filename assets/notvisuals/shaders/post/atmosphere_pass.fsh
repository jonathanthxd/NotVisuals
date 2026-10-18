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
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float sat = maxC - minC;

    vec3 n1 = texture(InSampler, texCoord + vec2(texel.x * 2.0, 0.0)).rgb;
    vec3 n2 = texture(InSampler, texCoord - vec2(texel.x * 2.0, 0.0)).rgb;
    vec3 n3 = texture(InSampler, texCoord + vec2(0.0, texel.y * 2.0)).rgb;
    vec3 n4 = texture(InSampler, texCoord - vec2(0.0, texel.y * 2.0)).rgb;
    vec3 fine = (n1 + n2 + n3 + n4) * 0.25;

    vec3 f1 = texture(InSampler, texCoord + vec2(texel.x * 7.0, 0.0)).rgb;
    vec3 f2 = texture(InSampler, texCoord - vec2(texel.x * 7.0, 0.0)).rgb;
    vec3 f3 = texture(InSampler, texCoord + vec2(0.0, texel.y * 7.0)).rgb;
    vec3 f4 = texture(InSampler, texCoord - vec2(0.0, texel.y * 7.0)).rgb;
    vec3 wide = (f1 + f2 + f3 + f4) * 0.25;

    float fineLum = luma709(fine);
    float wideLum = luma709(wide);
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

    lum = luma709(c);
    maxC = max(c.r, max(c.g, c.b));
    minC = min(c.r, min(c.g, c.b));
    sat = maxC - minC;

    float cloud = smoothstep(0.60, 0.90, lum) * (1.0 - smoothstep(0.11, 0.28, sat));
    float cloudContext = smoothstep(0.50, 0.82, max(fineLum, wideLum));
    cloud *= 0.58 + cloudContext * 0.42;

    float puffCore = smoothstep(0.72, 0.98, lum) * cloud;
    float puffEdge = smoothstep(0.008, 0.14, abs(lum - fineLum)) * cloud;
    float underside = smoothstep(0.58, 0.76, wideLum) * (1.0 - smoothstep(0.74, 0.91, lum)) * cloud;

    c += vec3(0.032, 0.030, 0.026) * puffCore;
    c += (c - fine) * (0.070 + puffEdge * 0.065) * cloud;
    c = mix(c, c * vec3(0.982, 0.992, 1.020), underside * 0.20);
    c = mix(c, wide * 1.018, cloud * 0.045);

    fragColor = vec4(max(c, vec3(0.0)), src.a);
}
