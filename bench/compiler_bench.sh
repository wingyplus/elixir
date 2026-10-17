#!/usr/bin/env bash
# Benchmarks the Elixir compiler from an Elixir checkout using hyperfine.
#
# Usage: bench/compiler_bench.sh [ELIXIR_SRC_DIR] [RESULTS_DIR]
#
# ELIXIR_SRC_DIR defaults to a fresh clone of elixir-lang/elixir main.
# Requires: erl/erlc (OTP 27+) on PATH, hyperfine, make, git.
set -euo pipefail
export LC_ALL=${LC_ALL:-C.UTF-8}

SRC=${1:-}
OUT=${2:-$(pwd)/bench/results}
BOOTSTRAP_RUNS=${BOOTSTRAP_RUNS:-3}
APP_RUNS=${APP_RUNS:-10}
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)

if [ -z "$SRC" ]; then
  SRC=$(mktemp -d)/elixir
  git clone --depth 1 https://github.com/elixir-lang/elixir.git "$SRC"
fi
cd "$SRC"

{
  echo "elixir commit: $(git rev-parse HEAD) ($(git log -1 --format=%cd))"
  echo "elixir version: $(cat VERSION)"
  echo "otp: $(erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().')"
  echo "erts: $(erl -noshell -eval 'io:format("~s", [erlang:system_info(version)]), halt().')"
  echo "cpu: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs) x $(nproc)"
  echo "hyperfine: $(hyperfine --version)"
} | tee "$OUT/env.txt"

# 1. Full bootstrap: erlc the compiler, then build stdlib and all apps.
hyperfine --warmup 1 --runs "$BOOTSTRAP_RUNS" \
  --prepare 'make clean >/dev/null 2>&1' \
  --command-name 'make compile (full bootstrap)' 'make compile' \
  --export-json "$OUT/bootstrap.json" --export-markdown "$OUT/bootstrap.md"

# Leave a built tree for the per-app benchmarks.
make compile >/dev/null

# 2. Compile each app's sources with the already built elixirc,
#    into a scratch dir so the built tree stays intact.
TMP=$(mktemp -d)
cmds=()
for app in elixir eex ex_unit logger mix iex; do
  cmds+=(--command-name "elixirc lib/$app"
         "cd lib/$app && ../../bin/elixirc --ignore-module-conflict 'lib/**/*.ex' -o $TMP/$app")
done
hyperfine --warmup 1 --runs "$APP_RUNS" \
  --prepare "rm -rf $TMP/*" \
  "${cmds[@]}" \
  --export-json "$OUT/apps.json" --export-markdown "$OUT/apps.md"
rm -rf "$TMP"
