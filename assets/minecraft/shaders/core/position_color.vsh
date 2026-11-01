#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;

layout(location = 0) out vec4 vertexColor;

void main() {
    vec4 q = ModelViewMat * vec4(Position, 1.0);
    gl_Position = ProjMat * q;

    vertexColor = Color;

    // The sunrise glow: hidden, the picture has its own sky.
    float l = length(q.xyz);
    if (ProjMat[2][3] < -0.5 && (abs(l - 100.0) < 0.02 || (l > 119.98 && l < 126.6))) {
        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
    }
}
