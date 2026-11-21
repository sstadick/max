# ===----------------------------------------------------------------------=== #
# Copyright (c) 2026, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #
"""Embed source-relative files as compile-time constants."""

comptime include_bytes = __mlir_type.`!lit.file_literal<false>`
"""Embed the exact file bytes as a read-only static span.

Use a literal path relative to the source file containing the expression, or
an absolute path to a regular file. Changes take effect when compiling the
source again. Precompiled packages carry their embedded contents.

Examples:
    ```mojo
    from std.io import include_bytes
    comptime logo = include_bytes["logo.png"]()
    ```
"""

comptime include_string = __mlir_type.`!lit.file_literal<true>`
"""Embed a UTF-8 file as a `StaticString`, resolving paths as in `include_bytes`.

Examples:
    ```mojo
    from std.io import include_string
    comptime theme = include_string["theme.css"]()
    ```
"""


def _embedded_bytes[
    data: __mlir_type.`!kgen.string`
]() -> Span[Byte, ImmStaticOrigin]:
    return StringLiteral[data]().as_bytes()


def _embedded_string[data: __mlir_type.`!kgen.string`]() -> StaticString:
    # The frontend validated the bytes at the source location of the include.
    return StaticString(data)
