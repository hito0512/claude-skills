# ComfyUI 节点文件模板

```python
import os
import folder_paths
from comfy_api.latest import io


class MyNodeName(io.ComfyNode):
    @classmethod
    def define_schema(cls):
        return io.Schema(
            node_id="MyNodeName",
            display_name="我的节点",
            category="🌸 HanaNode/Utils",
            description="这个节点做了一些有用的事情。",
            inputs=[
                io.String.Input(
                    "text", display_name="文本", multiline=True, default="",
                    tooltip="输入文本。",
                ),
                io.Int.Input(
                    "count", display_name="重复次数", default=1, min=1, max=100, step=1,
                    tooltip="重复次数。",
                ),
                io.String.Input(
                    "extra", display_name="额外参数", default="", optional=True,
                    tooltip="可选的额外参数。",
                ),
            ],
            outputs=[
                io.String.Output(display_name="结果文本"),
                io.String.Output(display_name="文件路径"),
            ],
        )

    @classmethod
    def execute(cls, text, count, extra="") -> io.NodeOutput:
        result = text * count
        return (result, "")


NODE_CLASS_MAPPINGS = {
    "MyNodeName": MyNodeName,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "MyNodeName": "🌸 我的节点",
}
```

## 关键点

- 文件放在 `nodes/` 目录下
- `node_id` 和 `NODE_CLASS_MAPPINGS` 中的 key 必须一致，保持英文 `Hana` 前缀
- `display_name` 和 `NODE_DISPLAY_NAME_MAPPINGS` 的值**必须用中文**
- **每个 `io.*.Input` / `io.*.Output` 都必须传 `display_name="中文"`**：`id` 是英文机读名（与 `execute` 参数名一致），`display_name` 是 UI 上给人看的中文标签
- `category` 统一用 `🌸 HanaNode/xxx` 格式
- `import` 全部放在文件顶部
- **禁止重复硬编码**：**同一个值在多处重复出现**时提为命名常量集中定义，代码只引用常量名，改值只改一处。一次性、语义自明的值（如 `io.Int.Input` 的 `max=100, step=1`）直接写字面量即可，无需提常量
- `execute` 参数名和 schema `inputs` 中的 name 必须完全一致
- 可选参数在 `execute` 中给默认值
- `outputs` 列表顺序决定返回 tuple 的顺序

JS 前端同理：节点尺寸/布局等参数若在 `computeSize`/`setSize`/`onResize`/`onAdded` 等多个回调里重复出现同一数值，必须在 `nodeCreated` / 闭包顶部集中定义 `const MIN_WIDTH = 320;` 等常量，回调里只引用常量名，不要写 `isV3 ? 320 : 220` 这类多处重复的裸值。
