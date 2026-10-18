"""Execute real GLSL on synthetic buffers; these are NOT Minecraft gameplay tests."""
from __future__ import annotations

import math
import json
import os
import struct
import unittest
from pathlib import Path

from shader_sources import ROOT, expand

try:
    import moderngl
    import numpy as np
except ImportError:
    moderngl = np = None

VERTEX = """#version 330
#extension GL_ARB_separate_shader_objects : require
layout(location=0) out vec2 texCoord;
void main() {
    vec2 uv = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
    texCoord = uv;
    gl_Position = vec4(uv * 2.0 - 1.0, 0.0, 1.0);
}
"""
SKY_VERTEX = VERTEX.replace('layout(location=0) out vec2 texCoord;',
    'layout(location=0) out float sphericalVertexDistance;\n'
    'layout(location=1) out float cylindricalVertexDistance;').replace(
    'texCoord = uv;', 'sphericalVertexDistance = uv.x * 1000.0; cylindricalVertexDistance = uv.x * 1000.0;')
CLOUD_VERTEX = VERTEX.replace('layout(location=0) out vec2 texCoord;',
    'layout(location=0) out float vertexDistance;\n'
    'layout(location=1) out vec4 vertexColor;\nuniform vec4 TestColor;\nuniform float TestDistance;').replace(
    'texCoord = uv;', 'vertexDistance = TestDistance; vertexColor = TestColor;')


class ShaderBufferTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if moderngl is None:
            if os.environ.get('NV_REQUIRE_GPU') == '1':
                raise RuntimeError('NV_REQUIRE_GPU requires moderngl and numpy')
            raise unittest.SkipTest('optional GPU tests: install scripts/requirements-gpu.txt')
        # Missing EGL or a compiler is a failure once the dependencies are installed.
        cls.ctx = moderngl.create_standalone_context(backend='egl', require=330)
        cls.vanilla = Path(os.environ.get('NV_VANILLA_ROOT', '/tmp/notvisuals-26.3'))
        print('\nSynthetic GLSL renderer:', cls.ctx.info['GL_RENDERER'])

    @classmethod
    def tearDownClass(cls):
        cls.ctx.release()

    def program(self, path, *, vertex=VERTEX, defines=''):
        source = expand(Path(path).read_text(), self.vanilla)
        source = source.replace('#version 330', '#version 330\n' + defines, 1)
        return self.ctx.program(vertex_shader=vertex, fragment_shader=source)

    def render(self, program, textures=None, uniforms=None, blocks=None, size=(64, 64), linear=()):
        resources = []
        try:
            for unit, (name, data) in enumerate((textures or {}).items()):
                data = np.asarray(data, dtype='f4')
                if data.ndim == 2:
                    data = data[:, :, None]
                tex = self.ctx.texture((data.shape[1], data.shape[0]), data.shape[2], data.tobytes(), dtype='f4')
                tex.filter = ((moderngl.LINEAR, moderngl.LINEAR) if name in linear
                              else (moderngl.NEAREST, moderngl.NEAREST))
                tex.repeat_x = tex.repeat_y = False
                tex.use(unit)
                resources.append(tex)
                if name in program:
                    program[name].value = unit
            for name, value in (uniforms or {}).items():
                if name in program:
                    program[name].value = value
            for binding, (name, values) in enumerate((blocks or {}).items()):
                if name not in program:
                    continue
                raw = struct.pack(f'{len(values)}f', *values)
                block = program[name]
                buffer = self.ctx.buffer(raw.ljust(block.size, b'\0'))
                block.binding = binding
                buffer.bind_to_uniform_block(binding)
                resources.append(buffer)
            output = self.ctx.texture(size, 4, dtype='f4')
            fb = self.ctx.framebuffer([output])
            vao = self.ctx.vertex_array(program, [])
            resources.extend([output, fb, vao])
            fb.use()
            self.ctx.viewport = (0, 0, *size)
            fb.clear()
            vao.render(mode=moderngl.TRIANGLES, vertices=3)
            return np.frombuffer(output.read(), dtype='f4').reshape(size[1], size[0], 4).copy()
        finally:
            for resource in reversed(resources):
                resource.release()

    def post(self, name, image, depth=None):
        program = self.program(ROOT / f'assets/notvisuals/shaders/post/{name}.fsh')
        textures = {'InSampler': image}
        if depth is not None:
            textures['MainDepthSampler'] = depth
        try:
            return self.render(program, textures, size=(image.shape[1], image.shape[0]))
        finally:
            program.release()

    def test_all_post_shaders_compile(self):
        for shader in sorted((ROOT / 'assets/notvisuals/shaders/post').glob('*.fsh')):
            with self.subTest(shader=shader.name):
                self.program(shader).release()

    def test_depth_flat_noise_invalid_and_screen_edges(self):
        image = np.full((64, 64, 4), 0.25, dtype='f4')
        image[:, :, 3] = 0.7
        depth = np.full((64, 64), 0.4, dtype='f4')
        for value in [0.4, 0.0, 1.0, float('nan'), float('inf')]:
            depth[32, 32] = value
            out = self.post('depth_lab', image, depth)
            np.testing.assert_allclose(out, image, atol=1e-6)
        depth[:] = 0.4
        depth[:, 0] = 0.8
        out = self.post('depth_lab', image, depth)
        np.testing.assert_allclose(out[:, 0], image[:, 0], atol=1e-6)

    def test_depth_preserves_supported_edges_and_reversed_z(self):
        image = np.full((64, 64, 4), 0.25, dtype='f4')
        for near, far in [(0.35, 0.65), (0.998, 0.999), (0.001, 0.002)]:
            depth = np.full((64, 64), near, dtype='f4')
            depth[:, 32:] = far
            out = self.post('depth_lab', image, depth)
            self.assertGreater(float(out[32, 31, 1]), 0.5)
            np.testing.assert_allclose(out[16:48, 10], image[16:48, 10], atol=1e-6)
            reversed_out = self.post('depth_lab', image, 1.0 - depth)
            np.testing.assert_allclose(out, reversed_out, atol=1e-5)

    def test_depth_ink_is_dark_and_preserves_alpha(self):
        image = np.full((64, 64, 4), 0.4, dtype='f4')
        depth = np.full((64, 64), 0.4, dtype='f4')
        depth[:, 32:] = 0.7
        out = self.post('depth_ink', image, depth)
        self.assertLess(float(out[32, 31, 0]), 0.4)
        self.assertTrue(np.all(out[:, :, :3] <= image[:, :, :3] + 1e-6))
        np.testing.assert_allclose(out[:, :, 3], image[:, :, 3])

    def test_depth_preserves_diagonal_silhouettes(self):
        y, x = np.mgrid[:64, :64]
        image = np.full((64, 64, 4), 0.25, dtype='f4')
        for flip in [False, True]:
            mask = x > (63 - y if flip else y)
            depth = np.where(mask, 0.7, 0.4).astype('f4')
            out = self.post('depth_lab', image, depth)
            for row in range(8, 56):
                column = 63 - row if flip else row
                self.assertGreater(float(out[row, column, 1]), 0.5)

    def test_chromaglow_large_warm_cold_neutral_and_special_surfaces(self):
        for rgb in [(1.0, 0.8, 0.35), (0.35, 0.9, 1.0), (0.94, 0.94, 0.94), (0.95, 0.55, 0.95)]:
            with self.subTest(rgb=rgb):
                image = np.full((64, 64, 4), 0.06, dtype='f4')
                image[28:36, 28:36, :3] = rgb
                out = self.post('highlight_extract', image)
                self.assertGreater(float(out[32, 32, :3].max()), 0.02)
                # The emitted RGB retains the source hue, including violet/green.
                ratios = out[32, 32, :3] / np.array(rgb)
                self.assertLess(float(ratios.max() - ratios.min()), 1e-4)

    def test_compact_glow_matches_previous_candidate_response(self):
        # Measured by executing the previous candidate's shader at 33fafc5.
        for rgb, expected in [((1.0, 0.8, 0.35), (0.73501146, 0.55979037, 0.24708426)),
                              ((0.35, 0.9, 1.0), (0.23346882, 0.60921842, 0.68775052))]:
            image = np.full((64, 64, 4), 0.06, dtype='f4')
            image[31:34, 31:34, :3] = rgb
            out = self.post('highlight_extract', image)
            np.testing.assert_allclose(out[32, 32, :3], expected, atol=5e-5)

    def test_chromaglow_uniform_whites_sky_and_smooth_gradient_do_not_glow(self):
        for rgb in [(0.95, 0.95, 0.95), (0.35, 0.65, 0.95), (0.1, 0.1, 0.1)]:
            image = np.ones((64, 64, 4), dtype='f4')
            image[:, :, :3] = rgb
            np.testing.assert_allclose(self.post('highlight_extract', image)[:, :, :3], 0, atol=1e-6)
        image = np.ones((128, 128, 4), dtype='f4')
        for channel, (low, high) in enumerate([(0.25, 0.4), (0.4, 0.6), (0.7, 0.9)]):
            image[:, :, channel] = np.linspace(low, high, 128)[:, None]
        np.testing.assert_allclose(self.post('highlight_extract', image)[:, :, :3], 0, atol=1e-6)

    def test_repeatability_without_temporal_noise(self):
        rng = np.random.default_rng(1234)
        image = rng.random((64, 64, 4), dtype='f4')
        one = self.post('highlight_extract', image)
        two = self.post('highlight_extract', image)
        np.testing.assert_array_equal(one, two)

    def test_subthreshold_depth_jitter_does_not_flash(self):
        rng = np.random.default_rng(458)
        image = np.full((64, 64, 4), 0.3, dtype='f4')
        for frame in range(8):
            depth = np.full((64, 64), 0.4, dtype='f4')
            depth += rng.uniform(-0.001, 0.001, depth.shape).astype('f4')
            np.testing.assert_allclose(self.post('depth_lab', image, depth), image, atol=1e-6)

    def test_complete_post_effect_graphs_render_synthetic_scene(self):
        self.core_available()
        image = np.ones((64, 64, 4), dtype='f4')
        image[:, :, :3] = (0.2, 0.4, 0.7)
        image[:32, :, :3] = (0.12, 0.1, 0.08)
        image[15:23, 20:28, :3] = (1.0, 0.8, 0.3)
        image[15:23, 40:48, :3] = (0.3, 0.8, 1.0)
        depth = np.full((64, 64), 0.4, dtype='f4')
        depth[:, 32:] = 0.7
        for path in sorted((ROOT / 'assets').glob('*/post_effect/*.json')):
            with self.subTest(effect=path.name):
                graph = json.loads(path.read_text())
                buffers = {'minecraft:main': image.copy()}
                for name, target in graph['targets'].items():
                    buffers[name] = np.full((target.get('height', 64), target.get('width', 64), 4), 0.18, dtype='f4')
                for step in graph['passes']:
                    namespace, name = step['fragment_shader'].split(':')
                    if namespace == 'minecraft':
                        shader = self.vanilla / 'shaders' / (name + '.fsh')
                    else:
                        shader = ROOT / 'assets' / namespace / 'shaders' / (name + '.fsh')
                    program = self.program(shader)
                    try:
                        inputs = {i['sampler_name']+'Sampler': depth if i.get('use_depth_buffer') else buffers[i['target']]
                                  for i in step['inputs']}
                        linear = {i['sampler_name']+'Sampler' for i in step['inputs'] if i.get('bilinear')}
                        target = buffers[step['output']]
                        h, w = target.shape[:2]
                        first = next(iter(inputs.values()))
                        blocks = {'SamplerInfo': [w, h, first.shape[1], first.shape[0]]}
                        for block, fields in step.get('uniforms', {}).items():
                            values = []
                            for field in fields:
                                value = field['value']
                                values.extend(value if isinstance(value, list) else [value])
                            blocks[block] = values
                        output = self.render(program, inputs, blocks=blocks, size=(w, h), linear=linear)
                        self.assertTrue(np.isfinite(output).all(), step['fragment_shader'])
                        buffers[step['output']] = output
                    finally:
                        program.release()
                self.assertGreater(float(buffers['minecraft:main'][:, :, :3].max()), 0.1)
                self.assertEqual(buffers['minecraft:main'].shape, image.shape)

    def core_available(self):
        if not (self.vanilla / 'shaders/include/fog.glsl').is_file():
            if os.environ.get('NV_REQUIRE_GPU') == '1':
                self.fail('Fetch verified renderer inputs with scripts/shader_sources.py --fetch')
            self.skipTest('fetch pinned Vanilla shader includes to run core tests')

    def test_cloud_oit_variants_compile(self):
        self.core_available()
        cloud = ROOT / 'assets/minecraft/shaders/core/clouds.fsh'
        for count in [4, 8, 16]:
            common = f'#define OIT\n#define OIT_COEFF_COUNT {count}\n#define OIT_WAVELET_RANK {int(math.log2(count))-1}\n#define OIT_COEFF_ATTACHMENT_COUNT {count//4}\n'
            for variant in ['#define OIT_ALPHA_ONLY\n#define OIT_DEPTH_BOUNDS',
                            '#define OIT_ALPHA_ONLY\n#define OIT_TRANSMITTANCE',
                            '#define OIT_ACCUMULATE',
                            '#define OIT_ACCUMULATE\n#define OIT_ADDITIVE']:
                for depth_mode in ['', '#define RENDERPEARL_DEPTH_IS_ZERO_TO_ONE\n']:
                    with self.subTest(count=count, variant=variant, depth_mode=depth_mode):
                        self.program(cloud, vertex=CLOUD_VERTEX, defines=common+depth_mode+variant).release()

    def test_cloud_shading_keeps_vanilla_alpha(self):
        self.core_available()
        program = self.program(ROOT / 'assets/minecraft/shaders/core/clouds.fsh', vertex=CLOUD_VERTEX)
        vanilla = self.program(self.vanilla / 'shaders/core/clouds.fsh', vertex=CLOUD_VERTEX)
        try:
            for light in [(0.9, 0.9, 0.95), (0.65, 0.4, 0.3), (0.05, 0.06, 0.09)]:
                for face in [0.7, 0.8, 0.9, 1.0]:
                    for distance in [0.0, 300.0, 999.0, 1100.0]:
                        blocks = {'Fog': [0.4, 0.5, 0.6, 1.0, 0, 1000, 0, 1000, 1000, 1000, 0, 0],
                                  'CloudInfo': [*light, 0.8, 0, 0, 0, 0, 12, 4, 12, 0]}
                        uniforms = {'TestColor': (*[v*face for v in light], 0.8), 'TestDistance': distance}
                        out = self.render(program, uniforms=uniforms, blocks=blocks)
                        old = self.render(vanilla, uniforms=uniforms, blocks=blocks)
                        np.testing.assert_allclose(out[:, :, 3], old[:, :, 3], atol=1e-6)
                        self.assertTrue(np.isfinite(out).all())
                        self.assertLessEqual(float(np.max(out[:, :, :3] - old[:, :, :3])), 0.02501)
        finally:
            program.release()
            vanilla.release()

    def test_cloud_oit_coverage_matches_vanilla_on_synthetic_buffers(self):
        self.core_available()
        projection = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1.01, -1, 0, 0, -0.1, 0]
        blocks = {'Fog': [0.4, 0.5, 0.6, 1, 0, 1000, 0, 1000, 1000, 1000, 0, 0],
                  'CloudInfo': [0.8, 0.8, 0.9, 0.8, 0, 0, 0, 0, 12, 4, 12, 0],
                  'Projection': projection}
        bounds = np.empty((64, 64, 4), dtype='f4')
        bounds[:] = (-0.01, 1.0, 0.5, 0.5)
        textures = {'DepthBoundsSampler': bounds, 'Coeff0': np.zeros((64, 64, 4), dtype='f4')}
        for phase in ['#define OIT_ALPHA_ONLY\n#define OIT_DEPTH_BOUNDS',
                      '#define OIT_ALPHA_ONLY\n#define OIT_TRANSMITTANCE', '#define OIT_ACCUMULATE']:
            defines = '#define OIT\n#define OIT_COEFF_COUNT 4\n#define OIT_WAVELET_RANK 1\n#define OIT_COEFF_ATTACHMENT_COUNT 1\n' + phase
            program = self.program(ROOT / 'assets/minecraft/shaders/core/clouds.fsh', vertex=CLOUD_VERTEX, defines=defines)
            vanilla = self.program(self.vanilla / 'shaders/core/clouds.fsh', vertex=CLOUD_VERTEX, defines=defines)
            try:
                for distance in [0.0, 350.0, 999.0]:
                    uniforms = {'TestColor': (0.56, 0.56, 0.63, 0.8), 'TestDistance': distance}
                    out = self.render(program, textures, uniforms, blocks)
                    old = self.render(vanilla, textures, uniforms, blocks)
                    self.assertTrue(np.isfinite(out).all())
                    if 'OIT_ALPHA_ONLY' in phase:
                        np.testing.assert_allclose(out, old, atol=1e-6)
                    else:
                        np.testing.assert_allclose(out[:, :, 3], old[:, :, 3], atol=1e-6)
            finally:
                program.release()
                vanilla.release()

    def test_sky_day_dusk_night_weather_bounded_vs_vanilla(self):
        self.core_available()
        program = self.program(ROOT / 'assets/minecraft/shaders/core/sky.fsh', vertex=SKY_VERTEX)
        vanilla = self.program(self.vanilla / 'shaders/core/sky.fsh', vertex=SKY_VERTEX)
        identity = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
        try:
            for sky, fog in [((0.3, 0.55, 0.85), (0.65, 0.75, 0.9)),
                             ((0.65, 0.3, 0.25), (0.8, 0.5, 0.3)),
                             ((0.02, 0.03, 0.08), (0.04, 0.05, 0.09)),
                             ((0.25, 0.26, 0.28), (0.32, 0.33, 0.35))]:
                blocks = {'Fog': [*fog, 1, 0, 1000, 0, 1000, 1000, 1000, 0, 0],
                          'DynamicTransforms': identity + identity + [*sky, 0.6] + [0, 0, 0, 0]}
                out = self.render(program, blocks=blocks)
                old = self.render(vanilla, blocks=blocks)
                delta = out[:, :, :3] - old[:, :, :3]
                self.assertGreater(float(np.abs(delta).max()), 0.0001)
                self.assertLessEqual(float(delta.max()), 0.01501)
                self.assertGreaterEqual(float(delta.min()), -0.04501)
                np.testing.assert_allclose(out[:, :, 3], old[:, :, 3], atol=1e-6)
        finally:
            program.release()
            vanilla.release()


if __name__ == '__main__':
    unittest.main()
