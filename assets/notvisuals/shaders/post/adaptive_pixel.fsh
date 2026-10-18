#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D InSampler;

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

float luma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float orderedDither(vec2 p) {
    vec2 q = mod(floor(p), 4.0);
    float index = q.x + q.y * 4.0;
    float pattern[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
    return pattern[int(index)] / 16.0 - 0.5;
}

vec3 pixelSample(sampler2D s, vec2 uv, vec2 size, float scale) {
    vec2 p = floor(uv * size / scale) * scale + scale * 0.5;
    return texture(s, p / size).rgb;
}

void main() {
    vec2 size = vec2(textureSize(InSampler, 0));
    vec2 texel = 1.0 / size;
    vec4 source = texture(InSampler, texCoord);
    vec3 orig = source.rgb;
    float center = luma709(orig);

    float e1 = luma709(texture(InSampler, texCoord + vec2(texel.x, 0.0)).rgb);
    float w1 = luma709(texture(InSampler, texCoord - vec2(texel.x, 0.0)).rgb);
    float n1 = luma709(texture(InSampler, texCoord + vec2(0.0, texel.y)).rgb);
    float s1 = luma709(texture(InSampler, texCoord - vec2(0.0, texel.y)).rgb);
    float ne = luma709(texture(InSampler, texCoord + texel).rgb);
    float nw = luma709(texture(InSampler, texCoord + vec2(-texel.x, texel.y)).rgb);
    float se = luma709(texture(InSampler, texCoord + vec2(texel.x, -texel.y)).rgb);
    float sw = luma709(texture(InSampler, texCoord - texel).rgb);

    vec2 texel2 = texel * 2.0;
    float e2 = luma709(texture(InSampler, texCoord + vec2(texel2.x, 0.0)).rgb);
    float w2 = luma709(texture(InSampler, texCoord - vec2(texel2.x, 0.0)).rgb);
    float n2 = luma709(texture(InSampler, texCoord + vec2(0.0, texel2.y)).rgb);
    float s2 = luma709(texture(InSampler, texCoord - vec2(0.0, texel2.y)).rgb);

    float gradient = abs(e1 - w1) + abs(n1 - s1);
    float diagonal = abs(ne - sw) + abs(nw - se);
    float variance1 = abs(center - e1) + abs(center - w1) + abs(center - n1) + abs(center - s1);
    float variance2 = abs(center - e2) + abs(center - w2) + abs(center - n2) + abs(center - s2);
    float frequency = gradient * 0.80 + diagonal * 0.34 + variance1 * 0.46 + variance2 * 0.23;

    float detail = smoothstep(0.030, 0.30, frequency);
    float highDetail = smoothstep(0.16, 0.58, frequency);

    float maxC = max(orig.r, max(orig.g, orig.b));
    float minC = min(orig.r, min(orig.g, orig.b));
    float saturation = maxC - minC;
    float skyBlue = smoothstep(0.015, 0.18, orig.b - orig.r) * smoothstep(0.30, 0.90, center);
    float softBright = smoothstep(0.72, 0.98, center) * (1.0 - smoothstep(0.18, 0.42, saturation));
    float skyLike = max(skyBlue * 0.72, softBright * 0.55);

    vec3 coarse = pixelSample(InSampler, texCoord, size, 2.70);
    vec3 medium = pixelSample(InSampler, texCoord, size, 2.05);
    vec3 fine = pixelSample(InSampler, texCoord, size, 1.38);

    vec3 pix = mix(coarse, medium, detail);
    pix = mix(pix, fine, highDetail);

    float levels = mix(44.0, 58.0, highDetail);
    vec2 basePixel = floor(texCoord * size / 2.70) * 2.70 + 1.35;
    float dither = orderedDither(basePixel) * (1.0 - highDetail) * (1.0 - skyLike * 0.55) * 0.26;
    pix = floor(pix * levels + 0.5 + dither) / levels;

    float recovery = smoothstep(0.08, 0.52, frequency) * 0.68;
    recovery += highDetail * 0.20;
    recovery += skyLike * 0.10;
    recovery = clamp(recovery, 0.0, 0.91);

    vec3 c = mix(pix, orig, recovery);
    fragColor = vec4(max(c, vec3(0.0)), source.a);
}
