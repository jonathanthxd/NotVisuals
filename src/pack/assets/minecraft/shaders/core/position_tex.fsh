#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

layout(location = 0) in vec2 texCoord0;
layout(location = 1) in vec3 skyRay;
layout(location = 2) in vec4 skyC0;
layout(location = 3) in vec4 skyC1;
layout(location = 4) in vec4 skyC2;
layout(location = 5) in vec4 skyU;
layout(location = 6) in float skyFlag;

layout(location = 0) out vec4 fragColor;

// Made by createtextures.com/tools/sky
const int SKY_FACE = 1016;
const ivec2 SKY_SIZE = ivec2(3080, 4064);
const int SKY_NIGHT_Y = 2032;
const ivec2 SKY_SUN = ivec2(3048, 8);
const int SKY_MODE = 0; // 0: own night, 1: same as day, 2: Minecraft's night
const bool SKY_SHOW_SUN = true;

bool skyMarker(ivec2 p, vec3 rgb) {
    vec4 c = texelFetch(Sampler0, p, 0);
    return c.a < 0.01 && all(lessThan(abs(c.rgb * 255.0 - rgb), vec3(0.6)));
}

bool skyIsOurs(ivec2 o, ivec2 e) {
    if (e.x - o.x != SKY_SIZE.x || e.y - o.y != SKY_SIZE.y) return false;
    int x0 = o.x + SKY_FACE * 3;
    return skyMarker(ivec2(x0, o.y), vec3(7, 211, 97))
        && skyMarker(ivec2(e.x - 1, o.y), vec3(211, 7, 97))
        && skyMarker(ivec2(x0, e.y - 1), vec3(97, 211, 7))
        && skyMarker(ivec2(e.x - 1, e.y - 1), vec3(7, 97, 211));
}

vec3 skyTexel(ivec2 cell, ivec2 p) {
    return texelFetch(Sampler0, cell + clamp(p, ivec2(0), ivec2(SKY_FACE - 1)), 0).rgb;
}

// The colour along world direction d. Faces as lib/sky/faces.ts OPTIFINE_FRAMES:
// 0 bottom, 1 top, 2 south, 3 west, 4 north, 5 east; cell (face % 3, face / 3).
vec3 skySheet(ivec2 base, vec3 d) {
    vec3 a = abs(d);
    int face;
    vec3 c;
    vec3 r;
    vec3 dn = vec3(0.0, -1.0, 0.0);
    if (a.y >= a.x && a.y >= a.z) {
        r = vec3(1.0, 0.0, 0.0);
        if (d.y < 0.0) { face = 0; c = vec3(0.0, -1.0, 0.0); dn = vec3(0.0, 0.0, 1.0); }
        else { face = 1; c = vec3(0.0, 1.0, 0.0); dn = vec3(0.0, 0.0, -1.0); }
    } else if (a.x >= a.z) {
        if (d.x < 0.0) { face = 3; c = vec3(-1.0, 0.0, 0.0); r = vec3(0.0, 0.0, -1.0); }
        else { face = 5; c = vec3(1.0, 0.0, 0.0); r = vec3(0.0, 0.0, 1.0); }
    } else {
        if (d.z > 0.0) { face = 2; c = vec3(0.0, 0.0, 1.0); r = vec3(-1.0, 0.0, 0.0); }
        else { face = 4; c = vec3(0.0, 0.0, -1.0); r = vec3(1.0, 0.0, 0.0); }
    }
    float w = dot(d, c);
    vec2 ab = (vec2(dot(d, r), dot(d, dn)) / w + 1.0) * 0.5;
    ivec2 cell = base + ivec2(face % 3, face / 3) * SKY_FACE;
    vec2 p = ab * float(SKY_FACE) - 0.5;
    ivec2 i0 = ivec2(floor(p));
    vec2 f = p - vec2(i0);
    vec3 c00 = skyTexel(cell, i0);
    vec3 c10 = skyTexel(cell, i0 + ivec2(1, 0));
    vec3 c01 = skyTexel(cell, i0 + ivec2(0, 1));
    vec3 c11 = skyTexel(cell, i0 + ivec2(1, 1));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

// R11: aurora moved another 10% upward relative to R9: 1.25 * 1.10 = 1.375.
// Horizon/zenith stay continuous, day sky and sun geometry unchanged.
vec3 nvHigherNightSky(vec3 d) {
    float elevation=asin(clamp(d.y,-1.0,1.0));
    if(elevation<=0.0) return d;
    float preserveZenith=smoothstep(1.03,1.49,elevation);
    float sampleElevation=mix(elevation/1.375,elevation,preserveZenith);
    float horizontal=length(d.xz);
    if(horizontal<0.00001) return d;
    vec2 compass=d.xz/horizontal;
    return vec3(compass.x*cos(sampleElevation),sin(sampleElevation),compass.y*cos(sampleElevation));
}

// R12: graduated Aurora-Foot Blend. Preserve the night atlas, star points,
// and upper aurora, but gently blend the FIRST ~30 degrees into the local sky.
// Separate tone softening from opacity to avoid an abrupt dark line at the base.
vec3 nvSoftAuroraFoot(vec3 night, vec3 d) {
    float elevation = asin(clamp(d.y,-1.0,1.0));
    float foot = smoothstep(0.015, 0.535, elevation);
    float green = max(night.g - night.r*1.20, 0.0);
    float cyan = max(night.b - night.r*2.10, 0.0);
    float violet = max(night.b - night.g*1.32, 0.0)
                 * smoothstep(0.10, 0.31, night.r);
    float curtain = smoothstep(0.065, 0.20, max(max(green,cyan),violet));
    float peak=max(max(night.r,night.g),night.b);
    float neutral=1.0-smoothstep(0.13,0.38,
                      (peak-min(min(night.r,night.g),night.b))/max(peak,0.001));
    float star=smoothstep(0.22,0.62,peak)*neutral;
    float fringe=(1.0-foot)*curtain*(1.0-star);
    // Calm over-saturated green/cyan transitions without removing the curtain.
    float light=dot(night,vec3(0.2126,0.7152,0.0722));
    vec3 calm=vec3(light*0.72,light*0.93,light*1.17);
    vec3 softened=mix(night,calm,0.70*fringe);
    // Opacity reduction is feathered independently. Constant night tint is
    // kept low-strength to prevent the R11 abrupt hard-blue strip.
    vec3 nightBase=vec3(0.027,0.046,0.089);
    return mix(softened,nightBase,0.32*fringe);
}

// R19 Celestial Depth: small world-direction starlight points and deep dust.
// No lat/long projection and no extra texture atlas; keeps existing night atlas.
float nvSkyHash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);}
vec3 nvNightDepth(vec3 d){
    vec3 a=abs(d);vec2 plane;float face;
    if(a.x>=a.y && a.x>=a.z){plane=vec2(d.z,d.y)/a.x;face=d.x>0.0?1.0:2.0;}
    else if(a.y>=a.z){plane=vec2(d.x,d.z)/a.y;face=d.y>0.0?3.0:4.0;}
    else{plane=vec2(d.x,d.y)/a.z;face=d.z>0.0?5.0:6.0;}
    vec2 cellUV=(plane*0.5+0.5)*148.0;
    vec2 cell=floor(cellUV);
    vec2 starPos=vec2(nvSkyHash(cell+vec2(face*31.0,7.9)),nvSkyHash(cell+vec2(13.7,face*41.0)));
    float dist=length(fract(cellUV)-mix(vec2(0.24),vec2(0.76),starPos));
    float aa=max(0.017,fwidth(dist)*0.74);
    float point=(1.0-smoothstep(0.023,0.023+aa,dist))*step(0.993,nvSkyHash(cell+vec2(5.2,face*13.6)));
    float seamGuard=smoothstep(0.006,0.025,min(min(plane.x+1.0,1.0-plane.x),min(plane.y+1.0,1.0-plane.y)));
    float altitude=smoothstep(0.06,0.22,d.y);
    vec3 far=normalize(vec3(-0.26,0.80,-0.53));
    float dust=0.013*exp(-pow((1.0-dot(d,far))/0.14,2.0));
    return (vec3(0.10,0.12,0.15)*point*seamGuard + vec3(0.30,0.36,0.50)*dust)*altitude;
}

// Sky corona is intentionally directional and affects only the celestial discs,
// rather than boosting Chromaglow on every bright block/texture in the world.
vec3 nvCelestialHalo(vec3 dir, vec3 sunDirection, float daytime, float weather) {
    float sunAngle=acos(clamp(dot(dir,sunDirection),-1.0,1.0));
    float moonAngle=acos(clamp(dot(dir,-sunDirection),-1.0,1.0));
    float solarCore=exp(-pow(sunAngle/0.105,2.0));
    float solarRim=exp(-pow(max(sunAngle-0.080,0.0)/0.17,1.7));
    float lunarCore=exp(-pow(moonAngle/0.058,2.0));
    float lunarRim=exp(-pow(max(moonAngle-0.042,0.0)/0.12,1.65));
    // R13: brighter *corona*, not a white opaque disk; the real celestial
    // texture is still drawn after this and remains the protagonist.
    float solarOuter=exp(-pow(sunAngle/0.41,1.55));
    float lunarOuter=exp(-pow(moonAngle/0.31,1.55));
    // R20: soften only the wide atmospheric skirt before four-scale bloom.
    // Keep celestial discs, color, core and near halo untouched.
    vec3 sunlight=(vec3(1.00,0.82,0.60)*(solarCore*0.29+solarRim*0.21+solarOuter*0.039))*daytime;
    vec3 moonlight=(vec3(0.67,0.79,1.00)*(lunarCore*0.22+lunarRim*0.16+lunarOuter*0.044))*(1.0-daytime);
    return (sunlight+moonlight)*weather;
}

void main() {

    if (skyFlag > 0.5) {
        if (!gl_FrontFacing) discard;
        vec3 q0 = skyC0.xyz / skyC0.w;
        vec3 q1 = skyC1.xyz / skyC1.w;
        vec3 q2 = skyC2.xyz / skyC2.w;
        vec2 uv0 = skyU.xy / skyC0.w;
        vec2 uv2 = skyU.zw / skyC2.w;
        vec2 ts = vec2(textureSize(Sampler0, 0));
        ivec2 o = ivec2(floor(min(uv0, uv2) * ts + 0.5));
        ivec2 e = ivec2(floor(max(uv0, uv2) * ts + 0.5));

        // Where this pixel's ray meets the sun quad (u along corner 0->1, v along 1->2).
        vec3 ex = q1 - q0;
        vec3 ez = q2 - q1;
        vec3 ctr = (q0 + q2) * 0.5;
        vec3 nrm = cross(ex, ez);
        float dn = dot(skyRay, nrm);
        vec2 sunUV = vec2(-1.0);
        if (abs(dn) > 1e-9) {
            float t = dot(ctr, nrm) / dn;
            if (t > 0.0) {
                vec3 h = skyRay * t;
                sunUV = vec2(dot(h - q0, ex) / dot(ex, ex), dot(h - q1, ez) / dot(ez, ez));
            }
        }
        bool onSun = sunUV.x >= 0.0 && sunUV.y >= 0.0 && sunUV.x < 1.0 && sunUV.y < 1.0;

        if (!skyIsOurs(o, e)) {
            // Some other sun (another pack's): draw it as the game would.
            if (!onSun) discard;
            vec4 color = texture(Sampler0, mix(uv0, uv2, sunUV)) * vec4(1.0);
            if (color.a == 0.0) discard;
            fragColor = color * ColorModulator;
            return;
        }

        // World axes as seen from the camera.
        vec3 south = normalize(ex);
        vec3 sunView = normalize(ctr);
        mat3 mv = mat3(ModelViewMat);
        bool folded = length(ModelViewMat[3].xyz) > 50.0;
        bool plain = abs(mv[0][0] - 1.0) + abs(mv[1][1] - 1.0) + abs(mv[2][2] - 1.0) < 1e-5;
        mat3 w2v;
        if (!folded && !plain) {
            w2v = mv;
        } else {
            vec3 up = vec3(0.0, -south.z, south.y);
            float l = length(up);
            up = l > 1e-5 ? up / l : normalize(vec3(0.0, 1.0, 0.0) - south * south.y);
            if (up.y - 0.001 * up.z < 0.0) up = -up;
            w2v = mat3(cross(up, south), up, south);
        }
        mat3 v2w = transpose(w2v);
        vec3 dir = normalize(v2w * skyRay);
        float sunY = (v2w * sunView).y;

        // The game's own day curve: full day with the sun 14.5 degrees up, full night 14.5 degrees down.
        float day = clamp(sunY * 2.0 + 0.5, 0.0, 1.0);
        vec3 col;
        if (SKY_MODE == 1) {
            col = skySheet(o, dir);
        } else if (SKY_MODE == 2) {
            col = day > 0.0 ? skySheet(o, dir) * day : vec3(0.0);
        } else {
            vec3 dayCol = day > 0.0 ? skySheet(o, dir) : vec3(0.0);
            vec3 nightCol = day < 1.0 ? skySheet(o + ivec2(0, SKY_NIGHT_Y), nvHigherNightSky(dir)) : vec3(0.0);
            if(day<1.0) nightCol=nvSoftAuroraFoot(nightCol,dir);
            col = mix(nightCol, dayCol, day);
        }
        // Faint angular depth; fades completely by day, never touches sun quad.
        if(SKY_MODE == 0) col += nvNightDepth(dir) * pow(1.0-day,2.5);
        // Rain greys the sky as the game greys its own.
        float rainB = clamp(ColorModulator.a * vec4(1.0).a, 0.0, 1.0);
        float grey = dot(col, vec3(0.3, 0.59, 0.11)) * 0.6;
        col = mix(col, vec3(grey), (1.0 - rainB) * 0.75);
        // Increased sun/moon corona, independent of nearby scene brightness.
        // The result still feeds the original Chromaglow post pipeline.
        col += nvCelestialHalo(dir,normalize(v2w*sunView),day,rainB);
        if (SKY_SHOW_SUN && onSun) {
            vec4 s = texelFetch(Sampler0, o + SKY_SUN + ivec2(sunUV * 32.0), 0);
            col += s.rgb * s.a * rainB;
        }
        fragColor = vec4(col, 1.0);
        return;
    }

    vec4 color = texture(Sampler0, texCoord0);
    if (color.a == 0.0) {
        discard;
    }
    fragColor = color * ColorModulator;
}
