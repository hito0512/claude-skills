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
                    "text", multiline=True, default="",
                    tooltip="输入文本。",
                ),
                io.Int.Input(
                    "count", default=1, min=1, max=100, step=1,
                    tooltip="重复次数。",
                ),
                io.String.Input(
                    "extra", default="", optional=True,
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
- `category` 统一用 `🌸 HanaNode/xxx` 格式
- `import` 全部放在文件顶部
- `execute` 参数名和 schema `inputs` 中的 name 必须完全一致
- 可选参数在 `execute` 中给默认值
- `outputs` 列表顺序决定返回 tuple 的顺序
