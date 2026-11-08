#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D InSampler;

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

float luma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    float logSum = 0.0;
    float weightSum = 0.0;
    for (int y = 0; y < 5; ++y) {
        for (int x = 0; x < 5; ++x) {
            vec2 uv = vec2(0.12 + float(x) * 0.19, 0.12 + float(y) * 0.19);
            vec3 c = texture(InSampler, uv).rgb;
            float lum = clamp(luma709(c), 0.002, 4.0);
            float centerWeight = 1.0 - 0.18 * length(uv - vec2(0.5));
            logSum += log(lum) * centerWeight;
            weightSum += centerWeight;
        }
    }
    float avgLum = exp(logSum / max(weightSum, 0.001));
    fragColor = vec4(avgLum, avgLum, avgLum, 1.0);
}
