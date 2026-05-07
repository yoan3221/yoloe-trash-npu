# Project Memory - YOLOE Trash NPU

> 最後更新: 2026-05-07

## ✅ 輸出模型

| 檔案 | 大小 | 說明 |
|------|------|------|
| `output/yoloe_26s_trash.onnx` | 40MB | ONNX 模型 (opset=12) |
| `output/yoloe_26s_trash_int16.nb` | **19MB** | int16 量化 NBG (Radxa A7A 可用) |

## NBG 輸出位置 (重要!)

`--pack-nbg-unify` 生成的 `.nb` 在 **`wksp_nbg_unify/network_binary.nb`**，不在 `wksp/` 內！
```
yoloe_26s_trash/
├── wksp/                          ← OpenVX 項目 (simulator)
│   └── yoloe_26s_trash_int16.export.data (20MB)
├── wksp_nbg_unify/                ← NBG 預編譯項目
│   └── network_binary.nb (19MB)   ← 這就是部署到 A7A 的檔案!
```

## 環境路徑

### Docker 容器 (allwinner_v2.0.10.1)
| 項目 | 路徑 |
|------|------|
| ACUITY_PATH | `/root/acuity-toolkit-whl-6.30.22/bin` |
| VIV_SDK | `/root/Vivante_IDE/VivanteIDE5.11.0/cmdtools` |
| pegasus | `python3 /root/acuity-toolkit-whl-6.30.22/bin/pegasus.py` |
| ai-sdk | `/workspace/ai-sdk` |
| common.target | `/workspace/ai-sdk/unified-tina/common.target` |

### env.sh v3 設定
- `VSIMULATOR_CONFIG=VIP9000NANODI_PLUS_PID0X1000003B`
- `VSIMULATOR_SHADER_CORE_COUNT=1`

## 模型資訊
- 輸入: `images` (1, 3, 640, 640)
- 輸出: `output0` (1, 300, 38), `output1` (1, 32, 160, 160)
- Opset: 12
- 35 種垃圾類別

## 板端部署 (Radxa A7A)
```bash
scp output/yoloe_26s_trash_int16.nb user@a7a:/path/
# On A7A:
vpm_run network_binary.nb test_image.jpg
```

## 已知問題

1. **NBG 在 wksp_nbg_unify/ 不是 wksp/** - pegasus export 的 `--output-path` 只影響 OpenVX 項目
2. **dataset.txt 不能有註解** - 量化時會被當成數值解析
3. **Docker 無網路** - apt 源指向 allwinnertech.com，無法安裝額外套件
