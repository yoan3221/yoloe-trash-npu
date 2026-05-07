#!/usr/bin/env python3
"""
Step 1: YOLOE-26S 匯出 ONNX (垃圾檢測文本提示)
==============================================
將 YOLOE-26S 模型設定常見垃圾類別提示後，匯出為 ONNX 格式。
輸出: output/yoloe_26s_trash.onnx

使用方式:
    conda activate yoloe_trash
    python step1_export_onnx.py
"""

import os
import sys
from pathlib import Path

try:
    import onnx
    import onnxsim
    HAS_ONNX_SIM = True
except ImportError:
    HAS_ONNX_SIM = False

from ultralytics import YOLOE


def load_trash_categories(filepath="trash_categories.txt"):
    """載入垃圾類別列表 (去除空白行和註解)"""
    categories = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                categories.append(line)
    return categories


def simplify_onnx(onnx_path, output_path=None):
    """使用 onnx-simplifier 簡化 ONNX 模型"""
    if output_path is None:
        output_path = onnx_path
    print(f"[INFO] Simplifying ONNX model: {onnx_path}")
    model = onnx.load(onnx_path)
    model_simp, check = onnxsim.simplify(
        model, check_n=3, perform_optimization=True, skip_fuse_bn=False,
    )
    if check:
        onnx.save(model_simp, output_path)
        print(f"[OK] Simplified ONNX saved to: {output_path}")
    else:
        print("[WARN] ONNX simplification check failed, keeping original")
    return output_path


def main():
    script_dir = Path(__file__).parent.resolve()
    os.chdir(script_dir)
    
    output_dir = Path("output")
    output_dir.mkdir(exist_ok=True)
    
    print("[1/4] Loading trash categories...")
    trash_categories = load_trash_categories(script_dir / "trash_categories.txt")
    print(f"       Categories ({len(trash_categories)}): {trash_categories[:10]}...")
    
    print("[2/4] Loading YOLOE-26S model...")
    model = YOLOE("yoloe-26s-seg.pt")
    
    print(f"[3/4] Setting text prompts for {len(trash_categories)} trash categories...")
    model.set_classes(trash_categories)
    
    onnx_path = output_dir / "yoloe_26s_trash.onnx"
    print(f"[4/4] Exporting to ONNX: {onnx_path}")
    
    export_result = model.export(
        format="onnx", imgsz=640, opset=12,
        dynamic=False, simplify=True, nms=False,
    )
    
    exported_file = Path(export_result)
    if exported_file != onnx_path and exported_file.exists():
        import shutil
        shutil.copy2(exported_file, onnx_path)
        print(f"[OK] ONNX copied to: {onnx_path}")
    else:
        print(f"[OK] ONNX exported to: {onnx_path}")
    
    if HAS_ONNX_SIM:
        simplify_onnx(str(onnx_path))
    
    print("\n" + "=" * 60)
    onnx_model = onnx.load(str(onnx_path))
    print(f"IR version: {onnx_model.ir_version}, Opset: {onnx_model.opset_import[0].version}")
    print(f"Inputs:")
    for inp in onnx_model.graph.input:
        shape = [d.dim_value if d.dim_value else d.dim_param for d in inp.type.tensor_type.shape.dim]
        print(f"  - {inp.name}: {shape}")
    print(f"Outputs:")
    for out in onnx_model.graph.output:
        shape = [d.dim_value if d.dim_value else d.dim_param for d in out.type.tensor_type.shape.dim]
        print(f"  - {out.name}: {shape}")
    print("=" * 60)


if __name__ == "__main__":
    main()
