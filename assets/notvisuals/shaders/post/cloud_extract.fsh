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
    vec3 c = texture(InSampler, texCoord).rgb;
    float lum = luma709(c);
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float sat = maxC - minC;

    vec3 a = texture(InSampler, texCoord + vec2(texel.x * 4.0, 0.0)).rgb;
    vec3 b = texture(InSampler, texCoord - vec2(texel.x * 4.0, 0.0)).rgb;
    vec3 d = texture(InSampler, texCoord + vec2(0.0, texel.y * 4.0)).rgb;
    vec3 e = texture(InSampler, texCoord - vec2(0.0, texel.y * 4.0)).rgb;
    float around = (luma709(a) + luma709(b) + luma709(d) + luma709(e)) * 0.25;

    float white = smoothstep(0.60, 0.94, lum) * (1.0 - smoothstep(0.10, 0.30, sat));
    float body = smoothstep(0.48, 0.78, around);
    float rim = smoothstep(0.015, 0.15, abs(lum - around));
    float mask = white * (0.70 + body * 0.30) * (0.82 + rim * 0.18);

    vec3 cloudColor = mix(vec3(lum), c, 0.35);
    fragColor = vec4(cloudColor * mask, 1.0);
}
