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

    vec3 n0 = texture(InSampler, texCoord + vec2(texel.x, 0.0)).rgb;
    vec3 n1 = texture(InSampler, texCoord - vec2(texel.x, 0.0)).rgb;
    vec3 n2 = texture(InSampler, texCoord + vec2(0.0, texel.y)).rgb;
    vec3 n3 = texture(InSampler, texCoord - vec2(0.0, texel.y)).rgb;
    vec3 n4 = texture(InSampler, texCoord + texel).rgb;
    vec3 n5 = texture(InSampler, texCoord - texel).rgb;
    vec3 n6 = texture(InSampler, texCoord + vec2(texel.x, -texel.y)).rgb;
    vec3 n7 = texture(InSampler, texCoord + vec2(-texel.x, texel.y)).rgb;

    float around = (luma709(n0) + luma709(n1) + luma709(n2) + luma709(n3) + luma709(n4) + luma709(n5) + luma709(n6) + luma709(n7)) * 0.125;
    float localPeak = max(lum - around, 0.0);

    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float saturation = maxC - minC;

    float broad = smoothstep(0.48, 0.91, lum) * smoothstep(0.26, 0.73, around);
    float colorful = smoothstep(0.09, 0.43, saturation) * smoothstep(0.43, 0.90, lum);
    float specular = smoothstep(0.025, 0.20, localPeak) * smoothstep(0.54, 0.94, lum);
    float softWhite = smoothstep(0.66, 0.97, lum) * smoothstep(0.48, 0.86, around) * (1.0 - smoothstep(0.12, 0.32, saturation));

    float weight = max(broad, max(colorful * 0.82, specular * (0.34 + saturation * 0.85)));
    weight = max(weight, softWhite * 0.92);
    weight *= smoothstep(0.34, 0.56, lum);

    vec3 hueGlow = mix(vec3(lum), c, 1.12);
    float energy = 0.72 + 0.28 * smoothstep(0.60, 1.00, lum);
    fragColor = vec4(max(hueGlow, vec3(0.0)) * weight * energy, 1.0);
}
