#version 330
#extension GL_ARB_separate_shader_objects : require

uniform sampler2D CurrentSampler;
uniform sampler2D PreviousSampler;

layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    float currentLum = texture(CurrentSampler, vec2(0.5)).r;
    float previousLum = texture(PreviousSampler, vec2(0.5)).r;
    previousLum = max(previousLum, 0.002);
    float rate = currentLum < previousLum ? 0.026 : 0.105;
    float adapted = mix(previousLum, currentLum, rate);
    adapted = clamp(adapted, 0.002, 2.5);
    fragColor = vec4(adapted, adapted, adapted, 1.0);
}
