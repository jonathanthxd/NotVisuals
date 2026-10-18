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

    float blue = smoothstep(0.018, 0.18, c.b - c.r) * smoothstep(0.28, 0.92, lum);
    float cloud = smoothstep(0.67, 0.97, lum) * (1.0 - smoothstep(0.11, 0.28, sat));
    float green = smoothstep(0.018, 0.18, c.g - max(c.r, c.b)) * smoothstep(0.12, 0.78, lum);
    float gold = smoothstep(0.02, 0.20, c.r - c.b) * smoothstep(0.18, 0.84, c.g) * smoothstep(0.38, 0.93, lum);

    vec3 around = 0.25 * (
        texture(InSampler, texCoord + vec2(texel.x, 0.0)).rgb +
        texture(InSampler, texCoord - vec2(texel.x, 0.0)).rgb +
        texture(InSampler, texCoord + vec2(0.0, texel.y)).rgb +
        texture(InSampler, texCoord - vec2(0.0, texel.y)).rgb
    );
    float local = length(c - around);

    c += vec3(-0.006, 0.008, 0.022) * blue * (1.0 - cloud * 0.6);
    c += vec3(0.020, 0.016, 0.008) * cloud * 0.60;
    c += vec3(-0.003, 0.012, 0.001) * green * 0.62;
    c += vec3(0.020, 0.010, -0.006) * gold * 0.68;

    float dark = 1.0 - smoothstep(0.08, 0.42, lum);
    c += vec3(-0.002, 0.002, 0.010) * dark;

    float micro = smoothstep(0.010, 0.15, local) * (1.0 - smoothstep(0.62, 0.96, lum));
    c += (c - around) * 0.025 * micro;

    fragColor = vec4(max(c, vec3(0.0)), src.a);
}
