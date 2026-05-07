#!/bin/bash
# ACUITY Quantize + Export NBG (run inside Docker container)
set -e

export ACUITY_PATH=/root/acuity-toolkit-whl-6.30.22/bin
export VIV_SDK=/root/Vivante_IDE/VivanteIDE5.11.0/cmdtools
PEGASUS="python3 /root/acuity-toolkit-whl-6.30.22/bin/pegasus.py"

cd /workspace/ai-sdk/models
source env.sh v3

cd /workspace/yoloe_trash_npu/yoloe_26s_trash

# Create dummy calibration image
python3 -c "
import numpy as np
from PIL import Image
img = Image.fromarray(np.zeros((640, 640, 3), dtype=np.uint8))
img.save('calib_dummy.jpg')
"

echo 'calib_dummy.jpg' > dataset.txt

echo "=== Step 1: Quantize int16 ==="
$PEGASUS quantize \
    --model yoloe_26s_trash.json \
    --model-data yoloe_26s_trash.data \
    --device CPU \
    --with-input-meta yoloe_26s_trash_inputmeta.yml \
    --compute-entropy \
    --rebuild \
    --model-quantize yoloe_26s_trash_int16.quantize \
    --quantizer dynamic_fixed_point \
    --qtype int16

echo ""
echo "=== Step 2: Export NBG ==="
$PEGASUS export ovxlib \
    --model yoloe_26s_trash.json \
    --model-data yoloe_26s_trash.data \
    --dtype quantized \
    --model-quantize yoloe_26s_trash_int16.quantize \
    --batch-size 1 \
    --save-fused-graph \
    --target-ide-project linux64 \
    --with-input-meta yoloe_26s_trash_inputmeta.yml \
    --postprocess-file yoloe_26s_trash_postprocess_file.yml \
    --pack-nbg-unify \
    --optimize $VSIMULATOR_CONFIG \
    --viv-sdk $VIV_SDK \
    --output-path wksp/yoloe_26s_trash_int16

echo ""
echo "=== Results ==="
find wksp -name 'network_binary.nb' -ls 2>/dev/null
ls -lh wksp/network_binary.nb 2>/dev/null
