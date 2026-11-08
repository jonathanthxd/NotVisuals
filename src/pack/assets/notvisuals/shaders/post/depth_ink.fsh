#version 330
#extension GL_ARB_separate_shader_objects : require
#include <notvisuals:depth_edges.glsl>

// R17 official integration: depth-based ink is now always enabled in the post chain.
uniform sampler2D InSampler;
uniform sampler2D MainDepthSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 scene = texture(InSampler, texCoord);
    vec2 px = 1.0 / vec2(textureSize(MainDepthSampler, 0));
    float edge = nvDepthEdge(MainDepthSampler, texCoord);
    edge = max(edge, nvDepthEdge(MainDepthSampler, texCoord + vec2(px.x, 0.0)) * 0.60);
    edge = max(edge, nvDepthEdge(MainDepthSampler, texCoord - vec2(px.x, 0.0)) * 0.60);
    edge = max(edge, nvDepthEdge(MainDepthSampler, texCoord + vec2(0.0, px.y)) * 0.60);
    edge = max(edge, nvDepthEdge(MainDepthSampler, texCoord - vec2(0.0, px.y)) * 0.60);
    float light = dot(scene.rgb, vec3(0.2126, 0.7152, 0.0722));
    float protectLight = 1.0 - smoothstep(0.65, 0.95, light);
    vec3 ink = scene.rgb * vec3(0.68, 0.72, 0.78);
    float amount = clamp(edge * protectLight * 0.82, 0.0, 0.72);
    fragColor = vec4(mix(scene.rgb, ink, amount), scene.a);
}
