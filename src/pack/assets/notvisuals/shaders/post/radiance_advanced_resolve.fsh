#version 330
#extension GL_ARB_separate_shader_objects : require
// NotVisuals R10: wide, colored bounce + contact-depth response.
// Intentionally preserves R9 source colors and all of its direct lighting.
uniform sampler2D DirectSampler;
uniform sampler2D BaseSampler;
uniform sampler2D BounceSampler;
uniform sampler2D MainDepthSampler;
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
void main(){
 vec4 direct=texture(DirectSampler,texCoord);
 float z=texture(MainDepthSampler,texCoord).r;
 if(z<=0.00002||z>=0.999999){fragColor=direct;return;}
 // Bilateral upsample of 512x288 radiance, preserving depth silhouettes.
 vec2 lowPix=1.0/vec2(textureSize(BounceSampler,0));
 vec3 gathered=vec3(0.0);float norm=0.0;
 for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){
    vec2 uv=clamp(texCoord+vec2(i,j)*lowPix*.70,lowPix*.5,vec2(1.0)-lowPix*.5);
    float nd=texture(MainDepthSampler,uv).r;
    if(nd<=0.00002||nd>=0.999999)continue;
    float relative=abs(nd-z)/max(z,0.00002);
    float edge=1.0-smoothstep(.04,.30,relative);
    float w=exp(-.5*float(i*i+j*j))*edge;
    gathered+=texture(BounceSampler,uv).rgb*w;
    norm+=w;
 }
 vec3 bounced=(norm>0.0001)?gathered/norm:vec3(0.0);
 vec3 base=texture(BaseSampler,texCoord).rgb;
 // Colored reflectance makes indirect light recognizable on neutral stone,
 // but keeps existing Minecraft textures and R9 chroma front and center.
 vec3 reflectance=mix(vec3(.74),clamp(base*1.15,vec3(.0),vec3(1.0)),.35);
 vec3 secondary=bounced*reflectance*.92;
 // Local contact shadow: small depth creases are shaded, not a global vignette.
 // Depth-only approximation; never marketed as world-space ray traced shadows.
 vec2 dp=1.0/vec2(textureSize(MainDepthSampler,0));
 float contact=0.0;float tested=0.0;
 const vec2 taps[8]=vec2[](vec2(1.,0.),vec2(-1.,0.),vec2(0.,1.),vec2(0.,-1.),
      vec2(.707,.707),vec2(-.707,.707),vec2(.707,-.707),vec2(-.707,-.707));
 for(int k=0;k<8;k++){
   vec2 uv=clamp(texCoord+taps[k]*dp*5.0,dp*.5,vec2(1.0)-dp*.5);
   float nd=texture(MainDepthSampler,uv).r;
   if(nd<=0.00002||nd>=0.999999)continue;
   // reversed-Z: larger depth = nearer obstacle.
   float diff=(nd-z)/max(z,0.00002);
   contact+=smoothstep(.08,.85,diff);
   tested+=1.0;
 }
 float ao=(tested>0.0)?contact/tested:0.0;
 vec3 outputColor=direct.rgb+secondary;
 outputColor*=1.0-0.105*ao;
 // Resist blowout where many lights overlap while keeping saturated colors.
 fragColor=vec4(max(outputColor,vec3(0.0)),direct.a);
}
