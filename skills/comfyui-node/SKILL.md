---
name: comfyui-node
description: 创建/重构 ComfyUI 自定义节点（Python + JS 前端）。使用 io.ComfyNode + define_schema 新版 API。当用户说"创建节点"、"写一个节点"、"ComfyUI node"、"重构节点"、新建 .py 节点文件时触发。
---

# ComfyUI Node Skill

## 硬规则

1. **文件位置**：所有 `.py` 节点文件必须放在 `nodes/` 目录下
2. **必须继承** `io.ComfyNode`（from `comfy_api.latest import io`）
3. **必须用** `define_schema()` 定义输入输出，**禁止**旧式 `INPUT_TYPES`/`RETURN_TYPES`/`RETURN_NAMES`/`FUNCTION`/`CATEGORY`
4. **必须用** `execute()` 类方法写执行逻辑，参数名和 schema input name 完全一致
5. **文件末尾必须有** `NODE_CLASS_MAPPINGS` 和 `NODE_DISPLAY_NAME_MAPPINGS` 两个字典注册
6. **分类统一**：`category` 使用 `🌸 HanaNode/xxx` 格式（如 `🌸 HanaNode/IO`、`🌸 HanaNode/Image`）
7. **显示名用中文**：`display_name`（Schema 字段）和 `NODE_DISPLAY_NAME_MAPPINGS` 的值都必须用中文（如 `"显存清理"`、`"🎈 显存清理"`），node_id 仍保持英文 `Hana` 前缀
8. **import 放顶部**：所有 import 写入文件顶部，不在函数体内导入
9. **必须检查 JS 前端文件**：重构/迁移节点时，必须检查源目录下是否有匹配的 JS 前端文件，一并复制到 `js/` 目录并更新 `nodeData.name` 匹配 `Hana` 前缀的 node_id

## 完整文件模板

见 [references/template.md](references/template.md)。

## IO 类型速查

### 输入

| 类型 | 关键参数 |
|------|---------|
| `io.String.Input("name", multiline=True/False, default="")` | 文本 |
| `io.Int.Input("name", default=0, min=0, max=100, step=1)` | 整数 |
| `io.Float.Input("name", default=0.0, min=0.0, max=1.0, step=0.01)` | 浮点 |
| `io.Boolean.Input("name", default=False)` | 布尔 |
| `io.Combo.Input("name", options=["a","b"], default="a")` | 下拉 |
| `io.Image.Input("name")` | 图像 |
| `io.Model.Input("name")` | 模型 |
| `io.Clip.Input("name")` | CLIP |
| `io.Vae.Input("name")` | VAE |
| `io.Latent.Input("name")` | 潜变量 |

加 `optional=True` 可将输入变为可选。

### 输出

`io.String.Output`, `io.Image.Output`, `io.Model.Output`, `io.Conditioning.Output`, `io.Latent.Output`, `io.Float.Output`, `io.Audio.Output`

## 模型路径与目录

涉及模型加载、文件读写、路径获取时，见 [references/folder_paths.md](references/folder_paths.md)。

## execute 返回

返回类型注解 `io.NodeOutput`，返回值数量和顺序必须和 `outputs` 列表一致：

```python
@classmethod
def execute(cls, text, count) -> io.NodeOutput:
    return (text, count)
```
