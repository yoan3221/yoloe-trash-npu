# YOLOE Trash Detection NPU Project

使用 **YOLOE-26S** 開放詞彙檢測模型，設定常見垃圾類別為文本提示，匯出 ONNX 後轉換為 **Radxa A7A** NPU 支援的 `.nb` 格式。

## 系統架構

```
Windows/WSL2 (Anaconda)
  step1_export_onnx.py  →  YOLOE-26S + trash prompts → ONNX (40MB)
        │
Docker: ubuntu-npu:v2.0.10.1 (ACUITY v2.0)
  step2_acuity_convert.sh → import → quantize(int16) → export NBG
        │
Radxa A7A (A733, NPU v3)
  vpm_run network_binary.nb → 即時垃圾檢測
```

## 快速開始

### 0. 前置需求
- Windows 10/11 + WSL2 (Ubuntu)
- Anaconda / Miniconda
- Docker (在 WSL 中)
- ACUITY Docker 映像: `docker_images_v2.0.x.zip`

### 1. 建立 Conda 環境並匯出 ONNX
```powershell
cd yoloe_trash_npu
conda env create -f environment.yml
conda activate yoloe_trash
python step1_export_onnx.py
```

### 2. 設定 Docker + ACUITY 並轉換 .nb
```bash
# WSL
cd /mnt/c/Users/yoan3/vscode/yoloe_trash_npu
bash setup_docker.sh
sudo docker exec -it allwinner_v2.0.10.1 bash
cd /workspace/yoloe_trash_npu
bash run_acuity.sh          # import + quantize + export
bash fix_makefile.sh        # fix & compile NBG (needs aarch64 cross-compiler)
```

### 3. 部署到 A7A
```bash
scp output/yoloe_26s_trash_int16.nb user@a7a:/path/
# On A7A: vpm_run network_binary.nb test.jpg
```

## 垃圾類別 (35種)

| 類別 | 項目 |
|------|------|
| 塑膠類 | plastic_bottle, plastic_bag, plastic_cup, styrofoam, plastic_container, plastic_straw |
| 金屬類 | can, aluminum_can, tin_can, metal_scrap, metal_cap |
| 玻璃類 | glass_bottle, glass_jar, broken_glass |
| 紙類 | paper, cardboard, paper_cup, newspaper, carton, paper_bag |
| 食物 | food_waste, fruit_peel, food_packaging |
| 有害 | battery, cigarette_butt, light_bulb |
| 其他 | bottle_cap, snack_wrapper, chip_bag, mask, glove, tissue |

## 技術細節

| 項目 | 設定 |
|------|------|
| 模型 | YOLOE-26S (segmentation) |
| 輸入 | 640×640, RGB |
| ONNX Opset | 12 |
| NPU 版本 | v3 (A733) |
| ACUITY 版本 | v2.0.10.1 |
| 量化 | int16 (dynamic_fixed_point) |
| 輸出格式 | NBG (network_binary.nb) |
| ONNX 大小 | ~40MB |
| ONNX 輸出 | output0 (1,300,38) + output1 (1,32,160,160) |

## 參考
- [Ultralytics YOLOE](https://docs.ultralytics.com/zh/models/yoloe/)
- [Radxa A7A NPU](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev)
- [ACUITY Toolkit](https://docs.radxa.com/cubie/a7a/app-dev/npu-dev/cubie-acuity-usage)
- [ai-sdk](https://github.com/ZIFENG278/ai-sdk)
