# zig-jq

## Build

```bash
zig build -Doptimize=ReleaseFast
```

## Run

```bash
zig build run -- sample.json
# OR echo "{\"a\": \"b\"}" | zig build run
```