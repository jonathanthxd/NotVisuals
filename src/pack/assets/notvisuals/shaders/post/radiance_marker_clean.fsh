#version 330
#extension GL_ARB_separate_shader_objects : require
uniform sampler2D InSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;
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
bool nvTag(vec4 c) { return nvClass(c)>0; }
// R20: inpaint exact markers and their short anti-aliased fringe only when
// a confirmed marker is nearby. Never recolor unrelated magenta world pixels.
// Non-marker pixels elsewhere remain byte-identical at shader level.
bool nvFringeCandidate(vec3 col) {
 vec3 b=clamp(col,vec3(0.0),vec3(1.0))*255.0;
 // AA, light and fog blend the encoded color with the surface below it.
 // Include partially dimmed marker pixels, but ONLY remove candidates whose
 // 2-pixel neighbourhood has a class-ID anchor.
 float rowDistance=min(abs(b.r-195.0),min(abs(b.r-211.0),abs(b.r-227.0)));
 return rowDistance<76.0 && abs(b.g-76.0)<76.0 &&
        b.r>b.g+39.0 && b.r>78.0 && b.b>14.0 && b.b<252.0;
}
void main(){
 vec2 px=1.0/vec2(textureSize(InSampler,0));
 vec4 c=texture(InSampler,texCoord);
 bool marker=nvTag(c);
 if(!marker && nvFringeCandidate(c.rgb)) {
   // Resolve a 1-2px tinted ring only beside an exact source ID.
   // A pure pink block with no encoded ID is intentionally untouched.
   for(int y=-2;y<=2 && !marker;y++)for(int x=-2;x<=2;x++) {
      if(abs(x)==2 && abs(y)==2) continue;
      if(x==0 && y==0)continue;
      vec2 uv=clamp(texCoord+vec2(x,y)*px,px*0.5,vec2(1.0)-px*0.5);
      if(nvTag(texture(InSampler,uv))){marker=true;break;}
   }
 }
 if(!marker){fragColor=c;return;}
 vec3 sum=vec3(0.0);float count=0.0;
 // Wider 12-direction search resolves isolated magenta pixels on tiny candles
 // and lichens. We only sample source scene, not previously inpainted pixels.
 const float rings[7]=float[](1.65,3.20,5.10,7.40,10.2,13.4,17.0);
 for(int k=0;k<7;k++) {
   float r=rings[k];
   for(int i=0;i<12;i++) {
      float a=6.28318530718*(float(i)+float(k)*0.31)/12.0;
      vec2 uv=clamp(texCoord+vec2(cos(a),sin(a))*r*px,px*0.5,vec2(1.0)-px*0.5);
      vec4 n=texture(InSampler,uv);
      if(!nvTag(n) && !nvFringeCandidate(n.rgb)) {
         float w=1.0/(1.0+r*0.12);
         sum+=n.rgb*w;count+=w;
      }
   }
   if(count>4.0)break;
 }
 // A marker cannot survive as magenta even in a fully covered tiny source.
 // Use the surrounding scene if possible; dark neutral fallback otherwise.
 fragColor=vec4(count>0.0?sum/count:vec3(0.17,0.15,0.14),c.a);
}
