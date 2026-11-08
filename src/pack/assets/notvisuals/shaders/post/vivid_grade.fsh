#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D InSampler;
uniform sampler2D ExposureSampler;

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

float luma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec4 src = texture(InSampler, texCoord);
    vec3 c = max(src.rgb, vec3(0.0));

    float sceneLum = texture(ExposureSampler, vec2(0.5)).r;
    float darkAdapt = 1.0 - smoothstep(0.055, 0.255, sceneLum);
    float deepAdapt = 1.0 - smoothstep(0.020, 0.105, sceneLum);

    float lum0 = luma709(c);
    float maxC0 = max(c.r, max(c.g, c.b));
    float minC0 = min(c.r, min(c.g, c.b));
    float chroma0 = maxC0 - minC0;

    float localDark = 1.0 - smoothstep(0.34, 0.74, lum0);
    float adaptGain = 1.0 + darkAdapt * 0.20 + deepAdapt * 0.16;
    float adaptGamma = mix(1.0, 0.91, darkAdapt);
    vec3 eye = pow(max(c, vec3(0.0)), vec3(adaptGamma)) * adaptGain;
    c = mix(c, eye, localDark * (0.70 + deepAdapt * 0.20));

    float shadowOpen = 1.0 - smoothstep(0.08, 0.40, lum0);
    float highlightGuard = smoothstep(0.70, 1.00, lum0);
    c *= mix(1.045, 1.020, highlightGuard);
    c += vec3(0.006, 0.008, 0.014) * shadowOpen * (1.0 - darkAdapt * 0.18);

    c = (c - 0.5) * mix(1.085, 1.052, darkAdapt) + 0.5;
    c = max(c, vec3(0.0));

    float lum = luma709(c);
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float chroma = clamp(maxC - minC, 0.0, 1.0);

    float vibrance = 1.0 + 0.23 * (1.0 - chroma);
    c = mix(vec3(lum), c, vibrance);
    lum = luma709(c);
    c = mix(vec3(lum), c, 1.095);

    float greenMask = smoothstep(0.015, 0.19, c.g - max(c.r, c.b));
    float blueMask = smoothstep(0.015, 0.20, c.b - c.r) * smoothstep(-0.05, 0.16, c.b - c.g);
    float warmMask = smoothstep(0.015, 0.20, c.r - c.b) * smoothstep(0.10, 0.72, c.g);

    c += vec3(-0.002, 0.012, 0.002) * greenMask * (1.0 - highlightGuard);
    c += vec3(-0.005, 0.006, 0.020) * blueMask * (1.0 - highlightGuard * 0.6);
    c += vec3(0.020, 0.010, -0.006) * warmMask * (0.45 + 0.55 * lum);

    c = pow(max(c, vec3(0.0)), vec3(0.965));
    lum = luma709(c);

    float highlight = smoothstep(0.48, 0.97, lum);
    float shadow = 1.0 - smoothstep(0.05, 0.56, lum);
    c += vec3(0.021, 0.010, -0.006) * highlight;
    c += vec3(-0.006, 0.003, 0.015) * shadow * (1.0 - darkAdapt * 0.30);

    c = c / (vec3(1.0) + max(c - vec3(0.84), vec3(0.0)) * 0.27);

    float preserve = smoothstep(0.48, 0.88, chroma0) * smoothstep(0.20, 0.82, lum0);
    c = mix(c, max(src.rgb, vec3(0.0)) * 1.035, preserve * 0.06);

    fragColor = vec4(max(c, vec3(0.0)), src.a);
}
