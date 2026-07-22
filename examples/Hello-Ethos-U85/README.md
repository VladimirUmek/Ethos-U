# TensorFlow Lite Micro on Ethos-U85 (Corstone-320)

A minimal, ready-to-run CMSIS-Toolbox example: two quantized TensorFlow Lite
Micro models running entirely on an Arm Ethos-U85 NPU, on the Corstone-320
(SSE-320) Fixed Virtual Platform. The firmware runs one golden vector through
each model and compares the result against host-reference outputs, so the
example doubles as a self-checking integration test.

```bash
cbuild Hello-Ethos-U85.csolution.yml --active SSE-320-U85 --update-rte
FVP_Corstone_SSE-320 -f Board/Corstone-320/fvp_config.txt \
                     -a out/Hello-Ethos-U85/SSE-320-U85/Debug/Hello-Ethos-U85.axf
```

## Structure

```
Hello-Ethos-U85.csolution.yml   one target: SSE-320-U85, plus the NPU region defines
Hello-Ethos-U85.cproject.yml    binds the two layers and the test source
Board/Corstone-320/        Layer type: Board     -- device, stdio, Ethos-U driver and wiring
Model/                     Layer type: ML-Model  -- TFLM, the models, the tensor arena
Source/test_main.cpp       the whole test: two models, one golden vector each
```

The solution targets exactly one system. Ethos-U55 (Corstone-300) and
Ethos-U65 (Corstone-315) belong in separate, self-contained solutions, so that
each example stays free of hardware it does not use.

## The models

| | `hello_world` | `tiny_cnn` |
|---|---|---|
| Task | `y = sin(x)` regression | 4-class 16x16 pattern classification |
| Layers | Dense 1-16-16-1 | Conv2D, MaxPool, DepthwiseConv2D, Conv2D 1x1, MaxPool, Dense |
| Operators | `FULLY_CONNECTED` | `CONV_2D`, `DEPTHWISE_CONV_2D`, `MAX_POOL_2D`, `RESHAPE`, `FULLY_CONNECTED` |
| int8 / Vela size | 3240 B / 2784 B | 5824 B / 4688 B |
| Vela ops | 3 NPU, 0 CPU | 6 NPU, 0 CPU |

`hello_world` is the classic TinyML "hello world" — the sine-approximation
model from the TensorFlow Lite Micro examples, popularized by Pete Warden and
Daniel Situnayake's book *TinyML*. It is the smallest thing that proves the
NPU path works end to end. `tiny_cnn` was written for this example: a Dense-only
graph never touches the convolution, depthwise and pooling paths that real
workloads depend on. It classifies synthetic 16x16 stripe patterns generated
in-process, so retraining needs no dataset download.

Both are trained, quantized and Vela-compiled by `Model/gen/generate.py`, and
both compile to **zero CPU operators** — the whole graph runs on the NPU. Only
the Vela builds are linked into the firmware; the original `.tflite` files are
committed beside them so the models can be recompiled for a different NPU
configuration or memory mode.

To regenerate (retrain, re-quantize, re-run Vela — prints fresh golden vectors
to paste into `Source/test_main.cpp`):

```bash
pip install -r Model/gen/requirements.txt
python3 Model/gen/generate.py
```
