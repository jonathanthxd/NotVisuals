#version 330
#extension GL_ARB_separate_shader_objects : require
// NotVisuals R10: independent a-trous-style cross-bilateral smoothing.
// Two fixed scales are implemented as separate shaders to avoid new UBOs.
#define NV_STEP 3
uniform sampler2D InSampler;
uniform sampler2D MainDepthSampler;
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
void main(){
 float center=texture(MainDepthSampler,texCoord).r;
 if(center<=0.00002||center>=0.999999){fragColor=vec4(0.0);return;}
 vec2 pixel=1.0/vec2(textureSize(InSampler,0));
 float weights[3]=float[](.375,.25,.0625);
 vec3 sum=vec3(0.0); float total=0.0;
 for(int y=-2;y<=2;y++)for(int x=-2;x<=2;x++){
   vec2 uv=clamp(texCoord+vec2(x,y)*pixel*float(NV_STEP),pixel*.5,vec2(1.0)-pixel*.5);
   float d=texture(MainDepthSampler,uv).r;
   if(d<=0.00002||d>=0.999999)continue;
   float diff=abs(d-center)/max(center,0.00002);
   float edge=1.0-smoothstep(.045,.28,diff);
   float w=weights[abs(x)]*weights[abs(y)]*edge;
   sum+=max(texture(InSampler,uv).rgb,vec3(0.0))*w;
   total+=w;
 }
 fragColor=vec4(total>0.000001?sum/total:vec3(0.0),1.0);
}
