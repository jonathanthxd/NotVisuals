#version 330
#extension GL_ARB_separate_shader_objects : require

// NotVisuals R18 | unified vanilla 26.3 entity pipeline.
// Orange damage overlay independently adapted from the MIT Custom Damage Overlay Color idea.
// Trim fullbright detection independently adapted for 26.3; not copied from Emissive Library.
#ifdef GLINT
#include <minecraft:globals.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>

uniform sampler2D Sampler0;
#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif
#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
layout(location = 2) in vec4 vertexPerFaceColorBack;
layout(location = 3) in vec4 vertexPerFaceColorFront;
#else
layout(location = 2) in vec4 vertexColor;
#endif
#ifndef EMISSIVE
layout(location = 4) in vec4 lightMapColor;
#endif
#ifndef NO_OVERLAY
layout(location = 5) in vec4 overlayColor;
#endif
layout(location = 6) in vec2 texCoord0;
#ifdef GLINT
layout(location = 7) in vec2 texCoordGlint;
#endif
#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

// R18: Atlas-only check. Do not use alpha=254/255 as a global material marker;
// that technique accidentally lights arbitrary translucent entity textures.
bool nvIsArmorTrimAtlas() {
    ivec2 sz = textureSize(Sampler0, 0);
    if (sz.x == 512 && sz.y >= 512 && (sz.y % 512) == 0) {
        vec4 corner = texelFetch(Sampler0, ivec2(0, 0), 0);
        return max(max(corner.r,corner.g),corner.b) < 0.003;
    }
    // Older trim atlases in some client resource arrangements.
    if (sz.x == 2048 && sz.y >= 1024 && (sz.y % 1024) == 0) {
        vec4 corner = texelFetch(Sampler0, ivec2(70, 5), 0);
        vec4 stamp  = texelFetch(Sampler0, ivec2(70, 13), 0);
        return max(max(corner.r, corner.g), corner.b) < 0.003 &&
            distance(stamp.rgb, vec3(248.0 / 255.0, 0.0, 248.0 / 255.0)) < 0.008;
    }
    return false;
}

vec4 nvRpgOrangeDamage(vec4 overlay) {
    // Vanilla entity hurt overlay alpha encoded as 178/255; other overlays
    // (e.g. white flash, rendering layers) are not modified.
    float vanillaHitAlpha = 178.0 / 255.0;
    if (abs(overlay.a - vanillaHitAlpha) < 0.012) {
        // Warm amber-orange damage tint reminiscent of action RPGs.
        overlay.rgb = vec3(1.0, 0.45, 0.13);
        overlay.a = 0.62;
    }
    return overlay;
}

vec4 calculateFinalColor(vec4 color) {
#ifndef NO_OVERLAY
    vec4 hitColor = nvRpgOrangeDamage(overlayColor);
    bool nvHit = abs(overlayColor.a - (178.0 / 255.0)) < 0.012;
    if (!nvHit) color.rgb = mix(hitColor.rgb, color.rgb, hitColor.a);
#endif
#ifndef EMISSIVE
    if (nvIsArmorTrimAtlas()) {
        // Fullbright trim pass without changing its natural material palette.
        color.rgb = min(color.rgb * 1.08, vec3(1.0));
    } else {
        color *= lightMapColor;
    }
#endif
#ifndef NO_OVERLAY
    // The orange hit flash is applied after lightmap shading. This maintains
    // an unmistakable warm RPG hit accent even in caves without making the
    // underlying armor or skin permanently emissive.
    if (nvHit) color.rgb = mix(color.rgb, hitColor.rgb, 0.38);
#endif
#ifdef GLINT
    vec4 glintColor = GlintAlpha * texture(GlintSampler, texCoordGlint);
    color.rgb += glintColor.rgb * glintColor.rgb;
#endif
#ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
#else
    vec4 fogColor = FogColor;
#endif
    return apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance,
                     FogEnvironmentalStart, FogEnvironmentalEnd,
                     FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
}

void main() {
    vec4 color = texture(Sampler0, texCoord0);
#ifdef OIT_ADDITIVE
    color.a = min(0.99, color.a);
#endif
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) discard;
#endif
#ifdef PER_FACE_LIGHTING
    vec4 faceVertexColor = gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack;
#else
    vec4 faceVertexColor = vertexColor;
#endif
#ifdef DISSOLVE
    if (faceVertexColor.a < texture(DissolveMaskSampler, texCoord0).a) discard;
    faceVertexColor.a = 1.0;
#endif
    color *= faceVertexColor * ColorModulator;
#ifdef GLINT
    color.a = max(color.a, GlintAlpha);
#endif
#ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
#else
    fragColor = calculateFinalColor(color);
#endif
}
