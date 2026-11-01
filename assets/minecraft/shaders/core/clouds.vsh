#version 330
#extension GL_ARB_separate_shader_objects : require
// The custom Aurora Sky sheet already contains cloud shapes.
// Keep the 26.3 cloud fragment interface intact, but clip Vanilla cloud geometry.
// This is a deliberate source-level opt-out from duplicate native clouds.
layout(location = 0) out float vertexDistance;
layout(location = 1) out vec4 vertexColor;
void main() {
    vertexDistance = 0.0;
    vertexColor = vec4(0.0);
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
}
