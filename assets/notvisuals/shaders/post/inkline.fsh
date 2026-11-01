#version 330
#extension GL_ARB_separate_shader_objects : require

// Inkline v8 preview: conservative image-space contour and apparent contact tone.
// No geometry IDs, depth, normals, shadow map or HUD mask are available here.
uniform sampler2D InSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

const float INK_STRENGTH = 0.34;
const float CONTACT_TONE = 0.12;
const vec3 INK_TINT = vec3(0.77, 0.82, 0.91);

float lum(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

void main() {
    vec2 px = 1.0 / vec2(textureSize(InSampler, 0));
    vec2 uv = clamp(texCoord, px * 0.5, vec2(1.0) - px * 0.5);
    vec4 original = texture(InSampler, uv);
    float y = lum(original.rgb);
    float u = lum(texture(InSampler, clamp(uv + vec2(px.x, 0.0), px, vec2(1.0) - px)).rgb);
    float d = lum(texture(InSampler, clamp(uv - vec2(px.x, 0.0), px, vec2(1.0) - px)).rgb);
    float r = lum(texture(InSampler, clamp(uv + vec2(0.0, px.y), px, vec2(1.0) - px)).rgb);
    float l = lum(texture(InSampler, clamp(uv - vec2(0.0, px.y), px, vec2(1.0) - px)).rgb);

    float upper = max(max(u, d), max(r, l));
    float lower = min(min(u, d), min(r, l));
    // Place ink preferentially on the darker side of a discontinuity.
    float silhouette = smoothstep(0.10, 0.37, upper - y);
    silhouette *= smoothstep(0.13, 0.45, upper - lower);
    silhouette *= 1.0 - smoothstep(0.74, 0.99, y);
    // Suppress small texture microcontrast and white bright emitter edges.
    float neighbourMean = (u + d + r + l) * 0.25;
    float cavity = smoothstep(0.045, 0.22, neighbourMean - y) * (1.0 - smoothstep(0.45, 0.83, y));
    float darkness = clamp(silhouette * INK_STRENGTH + cavity * CONTACT_TONE, 0.0, 0.5);
    vec3 shaded = original.rgb * mix(vec3(1.0), INK_TINT, darkness);
    fragColor = vec4(max(shaded, vec3(0.0)), original.a);
}
