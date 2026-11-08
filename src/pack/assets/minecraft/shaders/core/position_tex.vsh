#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;

layout(location = 0) out vec2 texCoord0;
layout(location = 1) out vec3 skyRay;
layout(location = 2) out vec4 skyC0;
layout(location = 3) out vec4 skyC1;
layout(location = 4) out vec4 skyC2;
layout(location = 5) out vec4 skyU;
layout(location = 6) out float skyFlag;

vec3 skyViewRay(vec2 p) {
    mat4 inv = inverse(ProjMat);
    vec4 a = ProjMat * vec4(0.0, 0.0, -100.0, 1.0);
    vec4 b = ProjMat * vec4(0.0, 0.0, -50.0, 1.0);
    vec4 fa = inv * vec4(p, a.z / a.w, 1.0);
    vec4 fb = inv * vec4(p, b.z / b.w, 1.0);
    return fa.xyz / fa.w - fb.xyz / fb.w;
}

// Three corners of a full-screen triangle, both windings: the quad's two
// triangles are (0,1,2) and (2,3,0), so one of them always faces the camera and
// the fragment shader drops the other.
vec2 skyCorner(int id) {
    return id == 0 ? vec2(-1.0, -1.0) : (id == 2 ? vec2(-1.0, 3.0) : vec2(3.0, -1.0));
}

// The depth of a point 100 away: far behind everything the sky pass might test against.
float skyDepth() {
    vec4 a = ProjMat * vec4(0.0, 0.0, -100.0, 1.0);
    return a.z / a.w;
}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    texCoord0 = UV0;

    skyFlag = 0.0;
    skyRay = vec3(0.0);
    skyC0 = vec4(0.0);
    skyC1 = vec4(0.0);
    skyC2 = vec4(0.0);
    skyU = vec4(0.0);
    vec4 skyQ = ModelViewMat * vec4(Position, 1.0);
    // The sun quad: 30 x 30 at 100 away, so every corner is 108.63 from the eye (the moon's are 103.92).
    if (ProjMat[2][3] < -0.5 && abs(length(skyQ.xyz) - 108.6278) < 0.3) {
        int id = gl_VertexIndex % 4;
        vec2 p = skyCorner(id);
        gl_Position = vec4(p, skyDepth(), 1.0);
        skyRay = skyViewRay(p);
        skyC0 = id == 0 ? vec4(skyQ.xyz, 1.0) : vec4(0.0);
        skyC1 = id == 1 ? vec4(skyQ.xyz, 1.0) : vec4(0.0);
        skyC2 = id == 2 ? vec4(skyQ.xyz, 1.0) : vec4(0.0);
        skyU = vec4(id == 0 ? UV0 : vec2(0.0), id == 2 ? UV0 : vec2(0.0));
        skyFlag = 1.0;
    }
}
