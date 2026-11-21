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

# Run the compiler outside the directory holding the imported module and assets.
# RUN: rm -rf %t && mkdir -p %t/src
# RUN: cp %s %t/src/theme.mojo
# RUN: printf 'from theme import show\n\ndef main():\n    show()\n' > %t/src/main.mojo
# RUN: printf 'blue' > %t/src/theme.css
# RUN: printf '\000\377\200' > '%t/src/icon file.bin'
# RUN: touch %t/src/empty
# RUN: env MODULAR_CACHE_DIR=%t/cache %mojo-build %t/src/main.mojo -o %t/app
# RUN: %t/app | FileCheck %s --check-prefix=BLUE
# BLUE: blue 3 255
# RUN: kgen --elaborate %t/src/main.mojo -o %t/result.mlirbc -d=%t/result.d
# RUN: FileCheck %s --check-prefix=DEP < %t/result.d
# DEP: /icon\ file.bin
#
# The saved parsing graph records assets on the module that read them. Inspect
# it separately so the dirtiness check runs against the original snapshot.
# RUN: env MODULAR_CACHE_DIR=%t/cache %mojo-build --experimental-incr-parsing %t/parsed.mojoc %t/src/main.mojo -o %t/app
# RUN: kgen-opt %t/parsed.mojoc | sed -n '/^  depgraph.graph root/,/^  }/p' > %t/graph.mlir
# RUN: kgen-opt --depgraph-mark-dirty %t/graph.mlir | FileCheck %s --check-prefix=CLEAN
# CLEAN: depgraph.graph root @main
# CLEAN-NOT: depgraph.dirty
# CLEAN: depgraph.module @theme
# CLEAN-SAME: embedded_files
# CLEAN-NOT: depgraph.dirty
#
# Change only the asset bytes, preserving length and modification time.
# RUN: cp -p %t/src/theme.css %t/stamp
# RUN: printf 'lime' > %t/src/theme.css && touch -r %t/stamp %t/src/theme.css
# RUN: env MODULAR_CACHE_DIR=%t/cache %mojo-build %t/src/main.mojo -o %t/app
# RUN: %t/app | FileCheck %s --check-prefix=LIME
# LIME: lime 3 255
# RUN: kgen-opt --depgraph-mark-dirty %t/graph.mlir | FileCheck %s --check-prefix=DIRTY
# DIRTY: depgraph.module @main{{.*}}depgraph.dirty
# DIRTY: depgraph.module @theme{{.*}}depgraph.dirty
#
# RUN: rm '%t/src/icon file.bin'
# RUN: %t/app | FileCheck %s --check-prefix=LIME
# RUN: not env MODULAR_CACHE_DIR=%t/cache %mojo-build %t/src/main.mojo -o %t/app 2>&1 | FileCheck %s --check-prefix=MISSING
# MISSING: cannot read embedded file '{{.*}}icon file.bin'
# RUN: printf '\000\377\200' > '%t/src/icon file.bin'
# RUN: printf '\377' > %t/src/theme.css
# RUN: not env MODULAR_CACHE_DIR=%t/cache %mojo-build %t/src/main.mojo -o %t/app 2>&1 | FileCheck %s --check-prefix=UTF8
# UTF8: embedded file contains invalid UTF-8
#
# RUN: printf 'from std.io import include_bytes\ncomptime name = "icon file.bin"\ndef main():\n    print(len(include_bytes[name]()))\n' > %t/src/main.mojo
# RUN: not %mojo-build %t/src/main.mojo -o %t/app 2>&1 | FileCheck %s --check-prefix=LITERAL
# LITERAL: expected one literal file path

from std.io import include_bytes, include_string as text


def show():
    comptime css: StaticString = text["theme.css"]()
    comptime logo = include_bytes["icon file.bin"]()
    comptime assert len(logo) == 3 and logo[0] == 0 and logo[2] == 128
    comptime assert text["empty"]() == ""
    print(css, len(logo), logo[1])
