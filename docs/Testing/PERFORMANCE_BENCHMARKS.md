# Performance Benchmark Plan

## Initial targets
Targets are hypotheses to be measured and ratified in Phase 00; do not claim them as achieved before data exists.

- Warm start: aim for <= 2 seconds on selected reference devices.
- UI: no avoidable main-thread blocking during heavy operations.
- Memory: no unbounded page/image buffering; no release-blocking OOM on agreed test corpus.
- Jobs: progress updates are responsive and cancellation works at safe checkpoints.
- Search: local filename and OCR search should remain responsive on a representative large library.
- Battery/thermal: batch processing is bounded and does not create unnecessary background work.

## Benchmark dimensions
- Image resolution and number of pages.
- PDF page count and source type.
- OCR language and image quality.
- Compression preset.
- Device RAM, CPU, OS and thermal state.
- Cold/warm cache.
- App foreground/background transitions.
- Available storage.

## Required measurements
Median and p95 duration, output size, success/failure rate, peak memory where available, CPU/battery observations, and visual/text integrity.

## Rules
- Compare equivalent inputs and settings.
- Never use fake progress.
- Do not trade away correctness or privacy for a benchmark.
- Record actual measurements and test environment in release reports.
