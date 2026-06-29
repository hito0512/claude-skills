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
7. **显示名用中文 + emoji 前缀**：`display_name`（Schema 字段）和 `NODE_DISPLAY_NAME_MAPPINGS` 的值都必须用中文，并按类别加 emoji 前缀（见下表），node_id 仍保持英文 `Hana` 前缀
8. **每个输入必须有中文 display_name**：`define_schema` 的 `inputs` 列表中**每一个** `io.*.Input` 都必须传 `display_name="中文"` 参数（id 是英文机读名，display_name 是给人看的中文标签）。`outputs` 同样必须有中文 `display_name`
9. **import 放顶部**：所有 import 写入文件顶部，不在函数体内导入
10. **必须检查 JS 前端文件**：重构/迁移节点时，必须检查源目录下是否有匹配的 JS 前端文件，一并复制到 `js/` 目录并更新 `nodeData.name` 匹配 `Hana` 前缀的 node_id
11. **不要重写源逻辑**：重构现有节点时，**完整照搬源码逻辑**，只改类名（加 `Hana` 前缀）、node_id、category、display_name。不要自己重新实现算法
12. **类名与映射必须一致**：`NODE_CLASS_MAPPINGS` 里引用的类名必须和实际定义的类名完全一致（改名时三处都要改：class 定义、node_id、NODE_CLASS_MAPPINGS value）
13. **模块内导入用绝对导入**：`__init__.py` 把 `nodes/` 加到 `sys.path`，所以节点间互相导入用 `from xxx import Yyy`，**不要用** `from .xxx import Yyy` 相对导入
14. **禁止重复硬编码（仅限 JS 前端）**：JS 前端里**同一个值在多处重复出现**时，必须提取为命名常量集中定义（在 `nodeCreated` / 闭包顶部 `const UPPER_CASE = ...`），后续全部引用常量名，改值只改一处。典型场景：节点尺寸/布局参数在 `computeSize`/`setSize`/`onResize`/`onAdded` 等多个回调里重复出现同一数值，必须提 `const MIN_WIDTH = 320;` 之类常量，不要写 `isV3 ? 320 : 220` 这类多处重复裸值。**Python 端 `define_schema` 不适用此规则**——`min`/`max`/`step`/`default` 等一律直接写字面量数值，不提常量

## 类别 emoji 前缀表

| 类别 (category) | emoji | 示例 display_name |
|----------------|-------|------------------|
| `🌸 HanaNode/Image` | 🖼️ | `🖼️ 图片缩放` |
| `🌸 HanaNode/GGUF` | ⚡ | `⚡ Unet 加载器 (GGUF)` |
| `🌸 HanaNode/Lora` | ✨ | `✨ Lora 堆叠加载器` |
| `🌸 HanaNode/LTX` | 🎬 | `🎬 导演台 VLM` |
| `🌸 HanaNode/Memory` | ♻️ | `♻️ 显存清理` |
| `🌸 HanaNode/IO` | 💾 | `💾 保存字符串到文件` |

## 完整文件模板

见 [references/template.md](references/template.md)。

## IO 类型速查

### 输入

每个 `io.*.Input` 第二个位置参数（`id`，英文机读名）之后，必须用关键字传 `display_name="中文"`。

| 类型 | 示例 |
|------|---------|
| `io.String.Input("name", display_name="名称", multiline=True, default="")` | 文本 |
| `io.Int.Input("name", display_name="数量", default=0, min=0, max=100, step=1)` | 整数 |
| `io.Float.Input("name", display_name="强度", default=0.0, min=0.0, max=1.0, step=0.01)` | 浮点 |
| `io.Boolean.Input("name", display_name="启用", default=False)` | 布尔 |
| `io.Combo.Input("name", display_name="方式", options=["a","b"], default="a")` | 下拉 |
| `io.Image.Input("name", display_name="图像")` | 图像 |
| `io.Model.Input("name", display_name="模型")` | 模型 |
| `io.Clip.Input("name", display_name="CLIP")` | CLIP |
| `io.Vae.Input("name", display_name="VAE")` | VAE |
| `io.Latent.Input("name", display_name="潜变量")` | 潜变量 |

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

## 重构 Checklist

重构/迁移一个现有节点到 NodeNest 时，按顺序检查：

- [ ] **照搬源码逻辑**：不要自己重写算法，只改包装
- [ ] **类名加 Hana 前缀**：`class HanaXxx(io.ComfyNode)`
- [ ] **node_id 加 Hana 前缀**：`node_id="HanaXxx"`
- [ ] **category 改为** `🌸 HanaNode/xxx`
- [ ] **display_name 中文 + emoji**
- [ ] **每个输入/输出都有中文 display_name**（`io.*.Input`/`Output` 都传 `display_name="中文"`）
- [ ] **NODE_CLASS_MAPPINGS / NODE_DISPLAY_NAME_MAPPINGS 同步更新**
- [ ] **检查 JS 前端**：有则复制到 `js/`，更新 `nodeData.name` 匹配
- [ ] **JS 依赖检查**：若 JS 依赖原项目内部模块（如 rgthree 的 base_node.js），要么写简化独立版，要么确认原项目仍启用
- [ ] **模块间导入用绝对导入**（`from xxx import` 而非 `from .xxx import`）
- [ ] **JS 前端无重复硬编码**：JS 里同一值多处重复出现时提为命名常量集中定义，只引用常量名（Python `define_schema` 不适用，直接写字面量）
- [ ] **节点必须有输出端口或必填输入**，否则右键不显示"执行"按钮和"执行到选定节点"
- [ ] **可选输入 + 无输出** 的节点不会出现在右键菜单，需加输出端口或把输入改必填
