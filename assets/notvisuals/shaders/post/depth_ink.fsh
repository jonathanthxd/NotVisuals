#version 330
#extension GL_ARB_separate_shader_objects : require
#include <notvisuals:depth_edges.glsl>

// Opt-in until first-person and transparency depth are validated in Minecraft.
uniform sampler2D InSampler;
uniform sampler2D MainDepthSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 scene = texture(InSampler, texCoord);
    float edge = nvDepthEdge(MainDepthSampler, texCoord);
    float light = dot(scene.rgb, vec3(0.2126, 0.7152, 0.0722));
    float protectLight = 1.0 - smoothstep(0.65, 0.95, light);
    vec3 ink = scene.rgb * vec3(0.73, 0.76, 0.81);
    fragColor = vec4(mix(scene.rgb, ink, edge * protectLight * 0.65), scene.a);
}
