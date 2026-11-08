#version 330
#extension GL_ARB_separate_shader_objects : require
// R4: independent exact-material capture. No scene luminance heuristics.
// Seeds: RGB8 packs UV as 12+12 bits; A8 stores class (0 means empty).
uniform sampler2D InSampler;
uniform sampler2D MainDepthSampler;
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

// R4: the GPU marker ID must survive nearest-neighbor sampling and JFA.
// Marker IDs are encoded in the original RGB8 palette; the blue channel encodes a class.
int nvClass(vec4 c) {
    vec3 b=round(clamp(c.rgb,0.0,1.0)*255.0);
    if(abs(b.g-76.0)>2.0) return 0;
    float row=0.0;
    if(abs(b.r-195.0)<=2.0) row=0.0;
    else if(abs(b.r-211.0)<=2.0) row=26.0;
    else if(abs(b.r-227.0)<=2.0) row=52.0;
    else return 0;
    float local=round((b.b-16.0)/9.0);
    if(local<1.0 || local>26.0) return 0;
    if(abs(b.b-(16.0+local*9.0))>2.0) return 0;
    int cls=int(row+local);
    return cls<=53 ? cls : 0;
}

void main() {
    // The output is 512x288; check the complete subcell for small emitters.
    // A fixed grid avoids time-varying random seeds or noise.
    const vec2 GRID=vec2(512.0,288.0);
    const vec2 CELL=1.0/GRID;
    vec2 chosen=vec2(0.0);
    float best=1e20;
    int tag=0;
    for(int y=0;y<6;y++)for(int x=0;x<6;x++){
        vec2 offset=(vec2(float(x)+0.5,float(y)+0.5)/6.0-0.5)*CELL;
        vec2 uv=clamp(texCoord+offset,vec2(0.0001),vec2(0.9999));
        // R12 exact-texel capture: bilinear reads used to average tiny IDs
        // with neighboring pixels and intermittently erase them on motion.
        ivec2 texelXY=clamp(ivec2(floor(uv*vec2(textureSize(InSampler,0)))),
                                ivec2(0),textureSize(InSampler,0)-ivec2(1));
        int cls=nvClass(texelFetch(InSampler,texelXY,0));
        if(cls==0) continue;
        // R20: snap the selected seed to the actual texel center. Sub-cell
        // probe coordinates shifted by fractional pixels on camera motion.
        vec2 texelUV=(vec2(texelXY)+0.5)/vec2(textureSize(InSampler,0));
        float d=texture(MainDepthSampler,texelUV).r;
        if(d<0.00002 || d>0.999999) continue;
        // Prefer a central seed to minimize pixel-jitter at camera movement.
        float metric=dot(texelUV-texCoord,texelUV-texCoord);
        if(metric<best){best=metric;chosen=texelUV;tag=cls;}
    }
    fragColor=tag>0?nvPackSeed(chosen,tag):vec4(0.0);
}
