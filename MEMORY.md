# Project Memory - YOLOE Trash NPU

> 最後更新: 2026-05-07

## 環境路徑

### Docker 容器 (allwinner_v2.0.10.1)
| 項目 | 路徑 |
|------|------|
| ACUITY_PATH | `/root/acuity-toolkit-whl-6.30.22/bin` |
| VIV_SDK | `/root/Vivante_IDE/VivanteIDE5.11.0/cmdtools` |
| pegasus | `python3 /root/acuity-toolkit-whl-6.30.22/bin/pegasus.py` |
| ai-sdk | `/workspace/ai-sdk` (clone from ZIFENG278/ai-sdk) |
| common.target | `/workspace/ai-sdk/unified-tina/common.target` |
| 專案掛載 | `/workspace/yoloe_trash_npu` ↔ `C:\Users\yoan3\vscode\yoloe_trash_npu` |

### Conda 環境 (Windows)
| 項目 | 值 |
|------|-----|
| 環境名稱 | `yoloe_trash` |
| Python | 3.10 |
| Conda 路徑 | `C:\Users\yoan3\miniconda3\Scripts\conda.exe` |

### Docker 映像
- 檔案: `C:\Users\yoan3\vscode\docker_images_v2.0.x.zip`
- 映像: `ubuntu-npu:v2.0.10.1`
- 容器: `allwinner_v2.0.10.1`
- NPU: v3 (A733 / Radxa A7A)

## ACUITY 轉換流程

```
1. import:  pegasus import onnx → .json + .data
2. quantize: pegasus quantize int16 → .quantize
3. export:  pegasus export ovxlib --pack-nbg-unify → wksp/
4. make:    make -f makefile.linux → network_binary.nb
```

### 關鍵命令 (Docker 內)
```bash
export ACUITY_PATH=/root/acuity-toolkit-whl-6.30.22/bin
export VIV_SDK=/root/Vivante_IDE/VivanteIDE5.11.0/cmdtools
cd /workspace/ai-sdk/models && source env.sh v3
```

### env.sh v3 設定
- `VSIMULATOR_CONFIG=VIP9000NANODI_PLUS_PID0X1000003B`
- `VSIMULATOR_SHADER_CORE_COUNT=1`

## 模型資訊

### YOLOE-26S ONNX
- 輸入: `images` (1, 3, 640, 640)
- 輸出: `output0` (1, 300, 38), `output1` (1, 32, 160, 160)
- Opset: 12
- 大小: ~40MB
- 35 種垃圾類別

### ACUITY 導入結果
- 0 errors, 0 warnings
- .json: 245KB
- .data: 41.6MB
- int16 .quantize: 131KB

## 已知問題與解決方案

### 1. dataset.txt 不能有註解
ACUITY 量化時 dataset.txt 會被解析為數值，`#` 開頭的註解會導致 `ValueError`。
解決：只放圖片路徑，或用 `echo 'calib_dummy.jpg' > dataset.txt`

### 2. makefile common.target 路徑錯誤
`makefile.linux` 中的 include 路徑指向不存在的 `/root/Vivante_IDE/.../common.target`
解決：`sed -i 's|$(AQROOT)/root/Vivante...|/workspace/ai-sdk/unified-tina/common.target|g' makefile.linux`

### 3. 缺少 aarch64 交叉編譯器
NBG 編譯需要 ARM64 cross-compiler
解決：`apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu`

### 4. PowerShell 中 $ 符號被解析
在 PowerShell 執行 WSL 命令時，`$VAR` 會被 PowerShell 解讀
解決：用腳本檔案 (.sh) 代替 inline bash 命令

### 5. pegasus_import.sh pushd 問題
ai-sdk 腳本假設從父目錄執行，需要 `MODEL_DIR/` 下有同名子目錄
解決：直接使用 pegasus 命令而非 shell 腳本包裝

### 6. conda run 工作目錄問題
`conda run` 的工作目錄不是腳本所在目錄
解決：腳本中使用 `Path(__file__).parent.resolve()` 取得絕對路徑

## 板端部署 (Radxa A7A)
```bash
# 複製 .nb 到板端
scp output/yoloe_26s_trash_int16.nb user@a7a:/path/

# 板端推理
vpm_run network_binary.nb test_image.jpg
```
