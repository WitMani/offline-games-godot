#!/usr/bin/env bash
set -euo pipefail

# Godot 4 Web exports require a WebGL2 context. The generic evaluator defaults
# to --disable-gpu for ordinary HTML games, which leaves Chrome with WebGL1
# only. Keep the evaluator isolated while opting this Godot build into the
# software SwiftShader WebGL2 path.
args=()
for arg in "$@"; do
  [[ "$arg" == "--disable-gpu" ]] && continue
  args+=("$arg")
done
exec /usr/bin/google-chrome "${args[@]}" \
  --enable-unsafe-swiftshader \
  --use-angle=swiftshader \
  --use-gl=angle \
  --enable-webgl \
  --ignore-gpu-blocklist
