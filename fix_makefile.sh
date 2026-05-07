#!/bin/bash
# Fix makefile and compile NBG inside Docker container
# Usage: sudo docker exec allwinner_v2.0.10.1 bash /workspace/yoloe_trash_npu/fix_makefile.sh
set -e
cd /workspace/yoloe_trash_npu/yoloe_26s_trash/wksp
sed -i 's|include $(AQROOT)/root/Vivante_IDE/VivanteIDE5.11.0/cmdtools/common/common.target|include /workspace/ai-sdk/unified-tina/common.target|g' makefile.linux
echo "Fixed makefile common.target path"
export AQROOT=/workspace/ai-sdk/unified-tina
make -f makefile.linux 2>&1
if [ -s network_binary.nb ]; then
    NB_SIZE=$(ls -lh network_binary.nb | awk '{print $5}')
    echo "*** NBG COMPILED! Size: $NB_SIZE ***"
    cp network_binary.nb /workspace/yoloe_trash_npu/output/yoloe_26s_trash_int16.nb
else
    echo "NBG needs aarch64 cross-compiler. Install: apt-get install gcc-aarch64-linux-gnu"
fi
