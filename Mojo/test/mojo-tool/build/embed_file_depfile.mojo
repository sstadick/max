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

# RUN: mkdir -p %t && cp %s %t/theme.mojo
# RUN: printf 'blue' > '%t/theme:dark.css'
# RUN: printf 'logo' > '%t/badge #1;dark|light.svg'
# RUN: printf 'other' > '%t/themeXdark.css'
# Keep ordinary compiler depfiles readable by consumers of GCC-style escaping.
# RUN: cd %t && kgen --elaborate theme.mojo -o out:theme.mlirbc -d=deps.d
# RUN: FileCheck %s --check-prefix=DEP < %t/deps.d
# DEP: theme\:dark.css
# RUN: cd %t && kgen --elaborate theme.mojo -o out:theme.mlirbc -d=deps.381 --make-3.81-depfile
# RUN: cd %t && if make --version | grep -q "^GNU Make 3\.81"; then cp deps.381 deps.mk; else cp deps.d deps.mk; fi
# Give the target a recipe so Make can report whether it needs rebuilding.
# RUN: cd %t && printf '\t@echo rebuild\n' >> deps.mk
# RUN: cd %t && make -q -f deps.mk out:theme.mlirbc
# RUN: cd %t && make -q -f deps.mk -W "$PWD/themeXdark.css" out:theme.mlirbc
# RUN: cd %t && make -s -f deps.mk -W "$PWD/badge #1;dark|light.svg" out:theme.mlirbc | FileCheck %s
# -W gives the edited file a fresh timestamp even on coarse filesystems.
# RUN: cd %t && printf 'lime' > 'theme:dark.css'
# RUN: cd %t && make -s -f deps.mk -W "$PWD/theme:dark.css" out:theme.mlirbc | FileCheck %s
# CHECK: rebuild

from std.io import include_string

comptime theme = include_string["theme:dark.css"]()
comptime badge = include_string["badge #1;dark|light.svg"]()
