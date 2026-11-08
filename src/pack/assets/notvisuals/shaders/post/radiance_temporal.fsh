#version 330
#extension GL_ARB_separate_shader_objects : require
// NotVisuals R14: conservative motion-aware-by-rejection temporal stabilization.
// No camera matrices/motion vectors are available: REJECT history across
// disocclusions, large RGB direction changes and depth discontinuities.
// RGB intensity/hue settings of R9/R10 remain unmodified.
uniform sampler2D LitSampler;
uniform sampler2D SceneSampler;
uniform sampler2D MainDepthSampler;
uniform sampler2D HistorySampler;
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
float encodeDepth(float z) {return log2(1.0+clamp(z,0.0,1.0)*4096.0)/12.01;}
void main() {
    vec4 base=texture(SceneSampler,texCoord);
    vec4 lit=texture(LitSampler,texCoord);
    float depth=texture(MainDepthSampler,texCoord).r;
    if(depth<=0.00002||depth>=0.999999){fragColor=lit;return;}
    vec3 current=max(vec3(0.0),lit.rgb-base.rgb);
    // R13: force one exact history pixel for packed depth and RGB; gather only
    // neighbors whose geometry matches when the camera slides by a few pixels.
    ivec2 hSize=textureSize(HistorySampler,0);
    ivec2 hCenter=clamp(ivec2(floor(texCoord*vec2(hSize))),ivec2(0),hSize-ivec2(1));
    vec4 previous=texelFetch(HistorySampler,hCenter,0);
    vec3 old=max(vec3(0.0),previous.rgb);
    float nowDepth=encodeDepth(depth);
    float depthDifference=abs(previous.a-nowDepth);
    float depthConfidence=1.0-smoothstep(0.006,0.030,depthDifference);
    float curLen=length(current),oldLen=length(old);
    // R12 luminance-only continuity: never mix old and new RGB channels when
    // current light exists. This keeps the current cyan/green/violet chroma.
    float hueCos=dot(current,old)/max(curLen*oldLen,0.000001);
    float colorConfidence=smoothstep(0.82,0.975,hueCos);
    float confidence=depthConfidence*colorConfidence;
    // 3x3 previous-frame candidates only for movement by ~1 screen pixel;
    // search by depth and light hue, not RGB magnitude, so saturated emitters
    // keep their current hue regardless of neighbouring light classes.
    if(curLen>0.012){
        float best=confidence;
        for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
            if(x==0&&y==0)continue;
            ivec2 xy=clamp(hCenter+ivec2(x,y),ivec2(0),hSize-ivec2(1));
            vec4 history=texelFetch(HistorySampler,xy,0);
            vec3 candidate=max(vec3(0.0),history.rgb);
            float clen=length(candidate);
            if(clen<0.007)continue;
            float geometry=1.0-smoothstep(0.0028,0.016,abs(history.a-nowDepth));
            float hue=dot(candidate,current)/max(clen*curLen,0.000001);
            float matchHue=smoothstep(0.90,0.99,hue);
            float spatial=0.90;
            float score=geometry*matchHue*spatial;
            if(score>best){best=score;old=candidate;oldLen=clen;confidence=score;}
        }
    }
    vec3 stabilized=current;
    if(curLen>0.003 && oldLen>0.003){
        // Match color, smooth only fluctuations in energy; never shrink a
        // vivid bright emitter or warm its cyan/green/violet hue.
        // R14: symmetric temporal energy blending. R13 only filled dark dips,
        // leaving sudden overbright spikes untouched; those are conspicuous
        // around crowded glowstone walls. Smooth BOTH directions when depth
        // and chroma agree; steady-state energy is unchanged.
        float matchedOld=clamp(oldLen,curLen*0.68,curLen*1.48);
        float response=0.52*confidence;
        float stableEnergy=mix(curLen,matchedOld,response);
        stabilized=current*(stableEnergy/max(curLen,0.000001));
    } else if(curLen<=0.003 && oldLen>0.027 && depthDifference<0.014){
        // One-frame marker/particle occlusion relief. At most ~48% of the
        // previous contribution survives; decay is exponential, not permanent.
        // It may still ghost for a few frames on equal-depth camera pans.
        float missConfidence=1.0-smoothstep(0.003,0.014,depthDifference);
        // Short recovery for intermittent marker/particle occlusion. No
        // motion vectors: a strict depth threshold guards against ghosting.
        // R14: firefly/golden low-energy emitters can disappear for a frame
        // behind particles. Hold them slightly longer but reject depth jumps.
        // Does not change their steady-state color/intensity or world radius.
        bool gentleWarm=old.r>old.b*1.35 && old.g>old.b*1.17;
        float hold=(gentleWarm && oldLen<0.22)?0.70:0.54;
        stabilized=old*(hold*missConfidence);
    }
    fragColor=vec4(base.rgb+stabilized,lit.a);
}
