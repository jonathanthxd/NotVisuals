#version 330
#extension GL_ARB_separate_shader_objects : require

// Toon Grade v8: subtle quantization of midtone luminance with protected extremes.
uniform sampler2D InSampler;
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

const float TOON_STRENGTH = 0.12;
const float TONAL_LEVELS = 15.0;
const float SATURATION = 1.045;

float lum(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

void main() {
    vec4 src = texture(InSampler, texCoord);
    vec3 c = max(src.rgb, vec3(0.0));
    float y = lum(c);
    float mid = smoothstep(0.10, 0.23, y) * (1.0 - smoothstep(0.65, 0.90, y));
    // Two-dimensional ordered dither is stable in screen space, not stochastic frame noise.
    ivec2 p = ivec2(gl_FragCoord.xy) & 1;
    float dither = (float(p.x) + float(p.y) * 2.0 - 1.5) / TONAL_LEVELS * 0.25;
    float band = floor((y + dither) * TONAL_LEVELS + 0.5) / TONAL_LEVELS;
    c += vec3((band - y) * TOON_STRENGTH * mid);
    float y2 = lum(c);
    c = mix(vec3(y2), c, SATURATION * (1.0 - 0.020 * (1.0 - mid)));
    fragColor = vec4(max(c, vec3(0.0)), src.a);
}
