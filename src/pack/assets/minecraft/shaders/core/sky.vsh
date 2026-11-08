#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
layout(location = 2) out vec3 skyRay;
layout(location = 3) out float skyFlag;

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

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);

    skyFlag = 0.0;
    skyRay = vec3(0.0);
    if (ProjMat[2][3] < -0.5) {
        if (Position.y == 16.0 && length(Position.xz) < 513.0) {
            int id = gl_VertexIndex;
            vec2 p = id == 0 ? vec2(-1.0, -1.0) : ((id % 2) == 1 ? vec2(3.0, -1.0) : vec2(-1.0, 3.0));
            gl_Position = vec4(p, skyDepth(), 1.0);
            skyRay = transpose(mat3(ModelViewMat)) * skyViewRay(p);
            skyFlag = 1.0;
        }
    }
}
