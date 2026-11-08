#version 330
#extension GL_ARB_separate_shader_objects : require
// R11 upgraded spatial stability without changing RGB hue / range. Does not use screen-space history, which
// would ghost when the player turns without motion vectors / camera matrices.
// Filter only the small Radiance contribution, never the original scene detail.
uniform sampler2D LitSampler;
uniform sampler2D SceneSampler;
uniform sampler2D MainDepthSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;
void main() {
    vec4 base=texture(SceneSampler,texCoord);
    vec3 current=max(vec3(0.0),texture(LitSampler,texCoord).rgb-base.rgb);
    float z=texture(MainDepthSampler,texCoord).r;
    if(z<0.00002 || z>0.999999){fragColor=base;return;}
    vec2 px=1.0/vec2(textureSize(MainDepthSampler,0));
    vec3 integrated=vec3(0.0);
    float total=0.0;
    // 5x5 cross-bilateral, sparse 17-tap footprint: 3x3 inner ring +
    // 8 outer samples. Zero stochastic noise, depth/material silhouette guards.
    for(int y=-2;y<=2;++y)for(int x=-2;x<=2;++x){
        if((abs(x)==2 || abs(y)==2) && !(x==0 || y==0 || (abs(x)==2&&abs(y)==2)))continue;
        vec2 uv=clamp(texCoord+vec2(x,y)*px,px*0.5,vec2(1.0)-px*0.5);
        float d=texture(MainDepthSampler,uv).r;
        if(d<0.00002 || d>0.999999)continue;
        float difference=abs(d-z)/max(z,0.00002);
        float depthWeight=1.0-smoothstep(0.025,0.12,difference);
        vec3 neighborBase=texture(SceneSampler,uv).rgb;
        // Guard bright emissive edges and outlines while preserving the
        // colored atmosphere on ordinary surfaces and subtle texture detail.
        float sceneDifference=length(neighborBase-base.rgb);
        float materialWeight=1.0-smoothstep(0.18,0.70,sceneDifference);
        float gaussian=exp(-0.27*float(x*x+y*y));
        float w=gaussian*depthWeight*materialWeight;
        vec3 delta=max(vec3(0.0),texture(LitSampler,uv).rgb-neighborBase);
        // Reject blending across strongly different RGB hues: preserving cyan,
        // copper green and violet saturation is more important than a blur.
        float cLen=length(current), dLen=length(delta);
        if(cLen>0.018 && dLen>0.018){
            float similarity=dot(current,delta)/max(cLen*dLen,0.000001);
            w*=smoothstep(0.75,0.96,similarity);
        }
        integrated+=delta*w;
        total+=w;
    }
    vec3 smoothDelta=total>0.0001?integrated/total:current;
    // Keep some unsmoothed signal to avoid flat areas or excessive bleeding.
    vec3 resolved=mix(current,smoothDelta,0.84);
    // Keep the original bright-source peak at least as intense as before the
    // filter. Filtering may fill tiny gaps, but must not dim vivid lights.
    float peakNow=max(current.r,max(current.g,current.b));
    float peakResolved=max(resolved.r,max(resolved.g,resolved.b));
    if(peakNow>0.01 && peakResolved<peakNow){
        resolved*=peakNow/max(peakResolved,0.00001);
    }
    fragColor=vec4(base.rgb+resolved,base.a);
}
