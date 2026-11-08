#version 330
#extension GL_ARB_separate_shader_objects : require
// NotVisuals Aurora Sky: the atlas provides the cloud silhouettes.
// Preserve the input layout required by clouds.fsh/OIT, but emit no cloud geometry.
// Remove this override to opt back into native Fancy Clouds.
layout(location = 0) out float vertexDistance;
layout(location = 1) out vec4 vertexColor;
void main() {
    vertexDistance = 0.0;
    vertexColor = vec4(0.0);
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
}
