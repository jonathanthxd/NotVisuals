#version 330
#extension GL_ARB_separate_shader_objects : require
// NotVisuals R14 - exact End-sky geometry guard, preserving vanilla UI and overlays.
// Shader compiled at startup: include no external files / Globals UBO.
layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    mat4 TextureMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
};
layout(std140) uniform Projection { mat4 ProjMat; };
layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;
layout(location = 2) in vec4 Color;
layout(location = 0) out vec2 texCoord0;
layout(location = 1) out vec4 vertexColor;
layout(location = 2) flat out float nvEndSky;
layout(location = 3) out vec3 nvEndDirection;
void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    texCoord0 = UV0;
    vertexColor = Color;
    // Minecraft 26.3 End sky: six inward-facing faces of +/-100 cube,
    // tint #282828, UV 0..16, world perspective. All must match.
    float cube = 1.0 - step(0.09,max(max(abs(abs(Position.x)-100.0),abs(abs(Position.y)-100.0)),abs(abs(Position.z)-100.0)));
    float tint = 1.0 - step(0.022,max(max(abs(Color.r-40.0/255.0),abs(Color.g-40.0/255.0)),abs(Color.b-40.0/255.0)));
    float uvOK = step(-0.001,min(UV0.x, UV0.y)) * step(max(UV0.x,UV0.y),16.001);
    float perspective = 1.0 - step(-0.5,ProjMat[2][3]);
    nvEndSky = cube*tint*uvOK*perspective;
    nvEndDirection = Position / 100.0;
}
