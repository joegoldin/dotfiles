#!/usr/bin/env python3
"""Compile the real AOTriton helper without requiring a running GPU.

Run with AOTriton's Python build dependencies and its tritonsrc on PYTHONPATH.
"""

import unittest

import triton
import triton.language as tl
from composed_tensors import composed_ptrs
from triton.backends.compiler import GPUTarget
from triton.compiler import ASTSource


@triton.jit
def pointer_kernel(Input, Output, D0: tl.constexpr, D1: tl.constexpr,
                   D2: tl.constexpr, TRANSPOSED: tl.constexpr):
    rows = tl.arange(0, 16)
    x, y, z = composed_ptrs(
        Input, 0, 0, 128, 1, 0, 0, rows, D0, D1, D2, TRANSPOSED
    )
    # Keep each present part in the compiled program, not just the first part.
    axis: tl.constexpr = 0 if TRANSPOSED else 1
    result = tl.sum(tl.load(x), axis=axis)
    if D1 > 0:
        result += tl.sum(tl.load(y), axis=axis)
    if D2 > 0:
        result += tl.sum(tl.load(z), axis=axis)
    tl.store(Output + rows, result.to(tl.int32))


class ComposedPointersTest(unittest.TestCase):
    def test_empty_and_present_segments_compile(self):
        for arch in ("gfx1100", "gfx1201"):
            for transposed in (False, True):
                for dims in ((16, 0, 0), (32, 16, 0), (64, 32, 16)):
                    with self.subTest(arch=arch, transposed=transposed, dims=dims):
                        source = ASTSource(
                            fn=pointer_kernel,
                            signature={"Input": "*fp32", "Output": "*i32"},
                            constexprs={
                                "D0": dims[0], "D1": dims[1], "D2": dims[2],
                                "TRANSPOSED": transposed,
                            },
                        )
                        compiled = triton.compile(
                            source,
                            target=GPUTarget("hip", arch, 32),
                            options={"num_warps": 4},
                        )
                        self.assertTrue(compiled.asm["amdgcn"])


if __name__ == "__main__":
    unittest.main()
