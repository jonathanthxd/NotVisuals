#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D InSampler;

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

float luma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 filmic(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

float grain(vec2 p) {
    return fract(sin(dot(floor(p), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
}

void main() {
    vec2 size = vec2(textureSize(InSampler, 0));
    vec2 texel = 1.0 / size;
    vec4 source = texture(InSampler, texCoord);
    vec3 c = max(source.rgb, vec3(0.0));

    vec3 near4 = 0.25 * (
        texture(InSampler, texCoord + vec2(texel.x, 0.0)).rgb +
        texture(InSampler, texCoord - vec2(texel.x, 0.0)).rgb +
        texture(InSampler, texCoord + vec2(0.0, texel.y)).rgb +
        texture(InSampler, texCoord - vec2(0.0, texel.y)).rgb
    );

    vec3 far4 = 0.25 * (
        texture(InSampler, texCoord + vec2(texel.x * 2.0, 0.0)).rgb +
        texture(InSampler, texCoord - vec2(texel.x * 2.0, 0.0)).rgb +
        texture(InSampler, texCoord + vec2(0.0, texel.y * 2.0)).rgb +
        texture(InSampler, texCoord - vec2(0.0, texel.y * 2.0)).rgb
    );

    float localDifference = length(c - near4);
    float distantDifference = length(c - far4);
    float detail = smoothstep(0.010, 0.19, localDifference + distantDifference * 0.42);
    float lumBefore = luma709(c);

    float sharpen = 0.075 * detail * (1.0 - smoothstep(0.72, 0.98, lumBefore));
    c += (c - near4) * sharpen;

    c = filmic(c * 1.025);

    float lum = luma709(c);
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float chroma = maxC - minC;
    float vibrance = 1.0 + 0.050 * (1.0 - chroma);
    c = mix(vec3(lum), c, vibrance);

    float shadow = 1.0 - smoothstep(0.06, 0.45, lum);
    float highlight = smoothstep(0.62, 0.97, lum);
    c += vec3(-0.004, 0.002, 0.010) * shadow * 0.52;
    c += vec3(0.009, 0.004, -0.002) * highlight * 0.50;

    vec2 p = texCoord * 2.0 - 1.0;
    float vignette = 1.0 - smoothstep(0.60, 1.43, dot(p, p)) * 0.018;
    c *= vignette;

    float g = grain(texCoord * size) / 1700.0;
    c += vec3(g);

    fragColor = vec4(clamp(c, 0.0, 1.0), source.a);
}
