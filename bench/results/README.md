# Elixir compiler benchmark (elixir-lang/elixir main)

Produced by `bench/compiler_bench.sh` with hyperfine. See `env.txt` for the exact
commit, OTP and machine; raw data is in `*.json`.

- Commit: elixir-lang/elixir@eaa0e70 (1.21.0-dev, 2026-10-16)
- Erlang/OTP 28.4 (erts 16.3, JIT), built from source
- 4 vCPU Intel Xeon @ 2.10GHz (cloud VM, so expect some noise)

## Full bootstrap (`make clean` then `make compile`), 3 runs + 1 warmup

| Command | Mean [s] | Min [s] | Max [s] | Relative |
|:---|---:|---:|---:|---:|
| `make compile (full bootstrap)` | 61.937 ± 0.284 | 61.624 | 62.178 | 1.00 |

## Recompile each app with the built `elixirc`, 10 runs + 1 warmup

| Command | Mean [s] | Min [s] | Max [s] | Relative |
|:---|---:|---:|---:|---:|
| `elixirc lib/elixir` | 8.482 ± 0.269 | 8.211 | 8.971 | 9.32 ± 0.54 |
| `elixirc lib/eex` | 0.921 ± 0.068 | 0.799 | 1.045 | 1.01 ± 0.09 |
| `elixirc lib/ex_unit` | 1.429 ± 0.070 | 1.300 | 1.542 | 1.57 ± 0.11 |
| `elixirc lib/logger` | 0.910 ± 0.044 | 0.853 | 1.005 | 1.00 |
| `elixirc lib/mix` | 2.563 ± 0.084 | 2.409 | 2.688 | 2.82 ± 0.17 |
| `elixirc lib/iex` | 1.175 ± 0.053 | 1.053 | 1.256 | 1.29 ± 0.09 |

The "Relative" column is relative to the fastest app (logger).
