#version 330
#extension GL_ARB_separate_shader_objects : require
// R11 persistent per-pixel light contribution + log-encoded depth; no world data.
uniform sampler2D StableSampler;
uniform sampler2D SceneSampler;
uniform sampler2D MainDepthSampler;
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
float encodeDepth(float z) {return log2(1.0+clamp(z,0.0,1.0)*4096.0)/12.01;}
void main(){
  float z=texture(MainDepthSampler,texCoord).r;
  if(z<=0.00002||z>=0.999999){fragColor=vec4(0.0);return;}
  vec3 delta=max(vec3(0.0),texture(StableSampler,texCoord).rgb-texture(SceneSampler,texCoord).rgb);
  fragColor=vec4(clamp(delta,vec3(0.0),vec3(1.0)),encodeDepth(z));
}
