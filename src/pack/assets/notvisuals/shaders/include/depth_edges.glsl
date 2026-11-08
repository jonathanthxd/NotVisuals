#ifndef NOTVISUALS_DEPTH_EDGES
#define NOTVISUALS_DEPTH_EDGES

// Device-space comparison only: no near/far, linear-depth or hand-ID claim.
bool nvUsableDepth(float z) {
    return !isnan(z) && !isinf(z) && z > 0.0000001 && z < 0.9999999;
}

float nvDepthJump(float a, float b) {
    if (!nvUsableDepth(a) || !nvUsableDepth(b)) return 0.0;
    // Relative to the nearest depth endpoint; symmetric under reversed Z.
    float scale = max(min(min(a, 1.0 - a), min(b, 1.0 - b)), 0.00001);
    return smoothstep(0.08, 0.28, abs(a - b) / scale);
}

float nvDepthEdge(sampler2D depths, vec2 uv) {
    ivec2 size = textureSize(depths, 0);
    ivec2 p = ivec2(floor(uv * vec2(size)));
    // Do not duplicate/wrap edge texels to manufacture contour support.
    if (any(lessThan(p, ivec2(2))) || any(greaterThanEqual(p, size - 2))) return 0.0;
    float z = texelFetch(depths, p, 0).r;
    if (!nvUsableDepth(z)) return 0.0;
    float edge = 0.0;
    const ivec2 directions[4] = ivec2[](ivec2(1, 0), ivec2(-1, 0), ivec2(0, 1), ivec2(0, -1));
    for (int i = 0; i < 4; ++i) {
        ivec2 d = directions[i];
        ivec2 t = ivec2(-d.y, d.x);
        float jump = nvDepthJump(z, texelFetch(depths, p + d, 0).r);
        // Search across a short normal span in each tangent row: diagonal
        // edges shift by a pixel between rows and must not lose their support.
        float before = nvDepthJump(texelFetch(depths, p - d + t, 0).r, texelFetch(depths, p + 2 * d + t, 0).r);
        float after = nvDepthJump(texelFetch(depths, p - d - t, 0).r, texelFetch(depths, p + 2 * d - t, 0).r);
        // A one-pixel impulse has no continuing edge in either tangent row.
        float support = min(before, after);
        edge = max(edge, min(jump, support));
    }
    return edge;
}
#endif
