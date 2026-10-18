#version 330
#extension GL_ARB_separate_shader_objects : require

// Chromaglow v8: appearance-only color response. RGB cannot identify block IDs.
uniform sampler2D InSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

const float EMISSION_THRESHOLD = 0.055;
const float EMISSION_SOFTNESS = 0.21;
const float NEUTRAL_GLOW = 0.25;

float lum(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

void main() {
    vec2 px = 1.0 / vec2(textureSize(InSampler, 0));
    vec3 c = max(texture(InSampler, texCoord).rgb, vec3(0.0));
    vec3 x1 = texture(InSampler, clamp(texCoord + vec2(px.x * 2.0, 0.0), vec2(0.0), vec2(1.0))).rgb;
    vec3 x2 = texture(InSampler, clamp(texCoord - vec2(px.x * 2.0, 0.0), vec2(0.0), vec2(1.0))).rgb;
    vec3 x3 = texture(InSampler, clamp(texCoord + vec2(0.0, px.y * 2.0), vec2(0.0), vec2(1.0))).rgb;
    vec3 x4 = texture(InSampler, clamp(texCoord - vec2(0.0, px.y * 2.0), vec2(0.0), vec2(1.0))).rgb;
    float center = lum(c);
    float neighborhood = lum((x1 + x2 + x3 + x4) * 0.25);
    float isolated = smoothstep(EMISSION_THRESHOLD, EMISSION_SOFTNESS, center - neighborhood);
    float bright = smoothstep(0.49, 0.91, center);
    float saturation = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
    float colorful = smoothstep(0.10, 0.33, saturation);

    // Require bright *locally concentrated* pixels before colorful emission.
    float warm = smoothstep(0.045, 0.26, c.r - c.b) * smoothstep(0.02, 0.19, c.g - c.b);
    float cold = smoothstep(0.045, 0.25, c.b - c.r) * smoothstep(0.02, 0.19, c.g - c.r);
    float coloredSource = isolated * bright * colorful;
    vec3 tint = c;
    tint = mix(tint, vec3(center * 1.13, center * 0.75, center * 0.34), warm * coloredSource * 0.35);
    tint = mix(tint, vec3(center * 0.35, center * 0.96, center * 1.14), cold * coloredSource * 0.33);

    // White regions without local peaks only contribute a faint neutral halo.
    float neutralPeak = isolated * smoothstep(0.71, 0.98, center) * (1.0 - colorful);
    float weight = coloredSource * 0.88 + neutralPeak * NEUTRAL_GLOW;
    float areaGuard = 1.0 - smoothstep(0.79, 0.99, neighborhood) * 0.80;
    weight *= areaGuard;
    fragColor = vec4(clamp(tint * weight, 0.0, 2.0), 1.0);
}
