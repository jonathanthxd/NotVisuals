#!/usr/bin/env python3
"""Compile post/core entry points and cloud OIT variants using glslangValidator."""
from __future__ import annotations

import argparse
import math
import subprocess
import tempfile
from pathlib import Path

from shader_sources import ROOT, expand


def check(compiler: str, vanilla: Path) -> int:
    jobs = []
    for path in sorted((ROOT / 'assets').glob('*/shaders/**/*.fsh')):
        jobs.append((str(path.relative_to(ROOT)), expand(path.read_text(), vanilla)))
    cloud = expand((ROOT / 'assets/minecraft/shaders/core/clouds.fsh').read_text(), vanilla)
    for count in [4, 8, 16]:
        common = (f'#define OIT\n#define OIT_COEFF_COUNT {count}\n'
                  f'#define OIT_WAVELET_RANK {int(math.log2(count))-1}\n'
                  f'#define OIT_COEFF_ATTACHMENT_COUNT {count//4}\n')
        for label, macros in [
            ('bounds', '#define OIT_ALPHA_ONLY\n#define OIT_DEPTH_BOUNDS\n'),
            ('transmittance', '#define OIT_ALPHA_ONLY\n#define OIT_TRANSMITTANCE\n'),
            ('accumulate', '#define OIT_ACCUMULATE\n'),
            ('additive', '#define OIT_ACCUMULATE\n#define OIT_ADDITIVE\n'),
        ]:
            for zero_to_one in [False, True]:
                defines = common + macros
                if zero_to_one:
                    defines += '#define RENDERPEARL_DEPTH_IS_ZERO_TO_ONE\n'
                jobs.append((f'clouds {label} coefficients={count} zero_to_one={zero_to_one}',
                             cloud.replace('#version 330', '#version 330\n' + defines, 1)))
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / 'shader.frag'
        for label, source in jobs:
            path.write_text(source)
            result = subprocess.run([compiler, '-S', 'frag', str(path)], text=True, capture_output=True)
            if result.returncode:
                raise RuntimeError(f'{label}\n{result.stdout}\n{result.stderr}')
    print(f'PASS: {len(jobs)} GLSL fragment/variant compilations (generic compiler, not ShaderC)')
    return len(jobs)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compiler', default='glslangValidator')
    parser.add_argument('--vanilla-root', type=Path, default=Path('/tmp/notvisuals-26.3'))
    args = parser.parse_args()
    check(args.compiler, args.vanilla_root)
