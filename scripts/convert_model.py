"""Convert a PyTorch model to Core ML (lesson 59.4). Run outside the app.

    pip install coremltools torch torchvision
    python scripts/convert_model.py --out MobileNetV3.mlpackage --compress float16
"""
import argparse

import coremltools as ct
import torch
import torchvision


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="MobileNetV3.mlpackage")
    p.add_argument("--compress", choices=["none", "float16", "int8"], default="float16")
    args = p.parse_args()

    net = torchvision.models.mobilenet_v3_small(weights="DEFAULT").eval()
    traced = torch.jit.trace(net, torch.rand(1, 3, 224, 224))
    model = ct.convert(
        traced,
        inputs=[ct.ImageType(shape=(1, 3, 224, 224), scale=1 / 255.0)],
        minimum_deployment_target=ct.target.iOS26,
        compute_precision=ct.precision.FLOAT16 if args.compress == "float16" else ct.precision.FLOAT32,
    )
    if args.compress == "int8":
        import coremltools.optimize.coreml as cto
        cfg = cto.OptimizationConfig(global_config=cto.OpLinearQuantizerConfig(mode="linear_symmetric"))
        model = cto.linear_quantize_weights(model, cfg)
    model.save(args.out)


if __name__ == "__main__":
    main()
