# ComfyUI 目录与路径参考

基于 `folder_paths.py`。

## 核心目录

| 目录 | 绝对路径 |
|------|---------|
| 基础目录 (base_path) | ComfyUI 根目录 |
| 模型目录 | `{base_path}/models` |
| 输入目录 (input) | `{base_path}/input` |
| 输出目录 (output) | `{base_path}/output` |
| 临时目录 (temp) | `{base_path}/temp` |
| 用户目录 (user) | `{base_path}/user` |
| 自定义节点 | `{base_path}/custom_nodes` |

可通过 `folder_paths.get_input_directory()` / `get_output_directory()` / `get_temp_directory()` 获取。

## 模型文件夹一览

| 类型名 | 路径 | 支持后缀 |
|--------|------|---------|
| checkpoints | `models/checkpoints` | .ckpt .pt .safetensors .pth 等 |
| loras | `models/loras` | 同上 |
| vae | `models/vae` | 同上 |
| text_encoders | `models/text_encoders`, `models/clip` | 同上 |
| diffusion_models | `models/unet`, `models/diffusion_models` | 同上 |
| clip_vision | `models/clip_vision` | 同上 |
| controlnet | `models/controlnet`, `models/t2i_adapter` | 同上 |
| upscale_models | `models/upscale_models` | 同上 |
| embeddings | `models/embeddings` | 同上 |
| hypernetworks | `models/hypernetworks` | 同上 |
| style_models | `models/style_models` | 同上 |
| gligen | `models/gligen` | 同上 |
| configs | `models/configs` | .yaml |
| diffusers | `models/diffusers` | folder |
| audio_encoders | `models/audio_encoders` | .ckpt .pt 等 |
| frame_interpolation | `models/frame_interpolation` | 同上 |
| detection | `models/detection` | 同上 |
| photomaker | `models/photomaker` | 同上 |
| classifiers | `models/classifiers` | 无特定后缀 |
| model_patches | `models/model_patches` | .ckpt .pt 等 |

## 节点中读写文件的常用方式

```python
import folder_paths

# 输入文件：用户通过 ComfyUI 上传的图片/视频/音频
input_dir = folder_paths.get_input_directory()
file_path = os.path.join(input_dir, "myfile.png")

# 输出文件：节点生成的结果
output_dir = folder_paths.get_output_directory()
save_path = os.path.join(output_dir, "result.txt")

# 模型文件：获取模型文件夹下的文件列表
from folder_paths import get_filename_list
checkpoints = get_filename_list("checkpoints")

# 获取模型的完整路径
from folder_paths import get_full_path
model_path = get_full_path("loras", "my_lora.safetensors")
```

## 路径标注

文件名后缀可以带 `[input]`、`[output]`、`[temp]` 来指定基准目录：
- `myfile.png [input]` → 从 input 目录读取
- `result.png [output]` → 写入 output 目录
