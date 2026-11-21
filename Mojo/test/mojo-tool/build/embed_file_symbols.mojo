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

# RUN: mkdir -p %t && cp %s %t/test.mojo && printf 'purple' > %t/theme.css
# RUN: %mojo-build -O0 --emit=object %t/test.mojo -o %t/test.o
# RUN: llvm-objdump -t %t/test.o | FileCheck %s --implicit-check-not=_embedded_bytes --implicit-check-not=_embedded_string
# CHECK: embedded_byte_at

from std.io import include_bytes, include_string


@export
def embedded_byte_at(index: Int) abi("C") -> UInt8:
    return include_bytes["theme.css"]()[index]


@export
def embedded_text_byte_at(index: Int) abi("C") -> UInt8:
    return include_string["theme.css"]().as_bytes()[index]
