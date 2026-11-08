#version 330
#extension GL_ARB_separate_shader_objects : require
// Jump Flood on the 512x288 packed R4 source field. RGBA8 stores 12-bit
// per-axis UV and the emitter class; no bilinear filtering is permitted.
uniform sampler2D SeedsSampler;
layout(std140) uniform RadianceJumpConfig { float JumpSize; };
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;
// R4 high-precision seed data: normalized source UV is stored in 12 bits/axis,
// 24 bits encoded in RGB bytes; alpha is the exact 8-bit material class.
// No dependence on undocumented float-render-target extensions.
vec4 nvPackSeed(vec2 uv, int cls) {
    ivec2 q=ivec2(round(clamp(uv,vec2(0.0),vec2(1.0))*4095.0));
    int packedUVBits=(q.x<<12)|q.y;
    ivec3 rgb=ivec3((packedUVBits>>16)&255,(packedUVBits>>8)&255,packedUVBits&255);
    return vec4(vec3(rgb)/255.0,float(cls)/255.0);
}
vec2 nvUnpackUV(vec4 seed) {
    ivec3 c=ivec3(round(clamp(seed.rgb,0.0,1.0)*255.0));
    int packedUVBits=(c.x<<16)|(c.y<<8)|c.z;
    return vec2(float((packedUVBits>>12)&4095),float(packedUVBits&4095))/4095.0;
}
int nvUnpackClass(vec4 seed) {
    return int(round(clamp(seed.a,0.0,1.0)*255.0));
}

void main() {
    ivec2 sz = textureSize(SeedsSampler, 0);
    // R13: JFA coordinates and packed marker class are discrete data, not color.
    // Bilinear filtering here corrupts UV/class bytes and creates rapidly
    // changing source identities when moving the camera.
    ivec2 center=clamp(ivec2(floor(texCoord*vec2(sz))),ivec2(0),sz-ivec2(1));
    ivec2 stride=ivec2(int(round(JumpSize)));
    vec4 best=vec4(0.0);
    float bestDistance=1e20;
    int bestId=2147483647;
    for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
        ivec2 xy=clamp(center+ivec2(x,y)*stride,ivec2(0),sz-ivec2(1));
        vec4 seed=texelFetch(SeedsSampler,xy,0);
        int cls=nvUnpackClass(seed);
        if(cls==0)continue;
        vec2 delta=(nvUnpackUV(seed)-texCoord)*vec2(sz);
        float metric=dot(delta,delta);
        // Stable deterministic tie-break: prefer lower encoded source ID.
        ivec3 rgb=ivec3(round(seed.rgb*255.0));
        int id=(rgb.x<<16)|(rgb.y<<8)|rgb.z;
        if(metric<bestDistance-0.00001 || (abs(metric-bestDistance)<=0.00001 && id<bestId)){
            bestDistance=metric;best=seed;bestId=id;
        }
    }
    fragColor=best;
}
