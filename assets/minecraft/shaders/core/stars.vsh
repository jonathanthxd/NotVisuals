#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;

void main() {
    // Hidden: the picture has its own sky. (Outside the clip volume, so nothing is drawn.)
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0) + 0.0 * ProjMat * ModelViewMat * vec4(Position, 1.0);
}
