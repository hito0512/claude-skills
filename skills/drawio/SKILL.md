---
name: drawio
description: 使用 cli-anything-drawio 创建 draw.io 树形图/流程图/拓扑图/架构图，确保节点不重叠的排布方法。当用户提到 draw、drawio、draw.io、绘图、画图、图表、树形图、流程图、拓扑图、架构图、思维导图、脑图、节点图、关系图、UML、连接线、多级树、多层结构时触发。
success_criteria:
  - 所有节点位置经过计算，水平/垂直方向互不重叠
  - 连线正确连接父→子节点
  - draw.io 桌面应用能正常打开生成的 .drawio 文件
---

# Draw.io CLI (cli-anything-drawio)

基于 [cli-anything](https://github.com/HKUDS/CLI-Anything) 的 draw.io 图表生成 CLI。

**CLI 位置**：`C:\QuickTools\cli-anything\cli-anything-drawio.exe`
**源码**：`E:\workspace\github\CLI-Anything\drawio\agent-harness`

## 基本命令

```bash
# 创建新项目
cli-anything-drawio --session <会话> project new -o "<路径>.drawio"

# 添加形状
cli-anything-drawio --session <会话> --project "<路径>.drawio" shape add <类型> -l "<标签>" --x X --y Y -w 宽 -h 高

# 添加连线
cli-anything-drawio --session <会话> --project "<路径>.drawio" connect add <源ID> <目标ID> --style orthogonal

# 查看帮助
cli-anything-drawio shape add --help
cli-anything-drawio connect add --help
```

### 形状类型

`rectangle`, `rounded`（推荐树形图）, `ellipse`, `diamond`, `triangle`, `hexagon`, `cylinder`, `cloud`, `paragraph`, `process`, `document`, `callout`, `note`, `actor`, `text`

## 不重叠排布方法

### 核心原则

节点位置由 **(x, y, width, height)** 四个参数决定。不重叠的条件：

```
相邻节点间距离 ≥ (节点A宽度/2 + 间距 + 节点B宽度/2)   # 水平方向
相邻节点间距离 ≥ (节点A高度/2 + 间距 + 节点B高度/2)   # 垂直方向
```

最小间距建议 **30px**。

### 布局模板

#### 模板 1：水平树形图（根在左，子在右）— 推荐多子节点

根节点竖排在左侧，所有子节点在右侧排成一列。子节点可继续向右延伸下级。

```
根  ─── 子1 ─── 子11
节  ─── 子2 ─── 子21
点  ─── 子3    子22
    ─── 子4 ─── 子41
    ─── ...    子42
    ─── 子N    子43
```

排布公式（逐层递归）：

```python
# 第一层：根 → 子
根x, 根y = 50, 画布高/2 - 根高/2
子x = 根x + 根宽 + 水平间距(≈150)
子起始y = 画布高/2 - (子数量 * (子高 + 间距)) / 2
子y_i = 子起始y + i * (子高 + 间距)

# 第二层：子 → 孙（递归）
孙x = 子x + 子宽 + 水平间距(≈150)
# 孙节点在其父节点附近垂直排列
孙起始y = 子y_i - (孙数量 * (孙高 + 间距)) / 2 + 子高/2
孙y_j = 孙起始y + j * (孙高 + 间距)
```

#### 模板 2：垂直单行树形图（根在上，子在下）— 首层 ≤5 子节点

首层子节点在同一水平行上。子节点可在下方继续垂直展开。

```
        根节点 (居中, y=30~50)
              │
    ┌────┬────┬────┬────┐
   子1  子2  子3  子4  子5
   /\
子11 子12           子51 子52 子53
```

排布公式：

```python
节点高度 = 50, 间距 = 30

# 第一层：水平展开
总宽度 = Σ(子i宽度) + (N-1) * 间距
起始x = (画布宽度 - 总宽度) / 2
子i的x = 起始x + Σ(前i-1宽度) + i * 间距
子i的y = 根y + 根高 + 垂直间距(≈80)

# 第二层：在父节点下方垂直展开
孙j的x = 父x + (父宽 - 孙宽) / 2   # 在父节点下方居中
孙j的y = 父y + 父高 + 行间距 + j * (孙高 + 行间距)
```

#### 模板 3：垂直单列 + 子树展开

首层子节点在根下方排成一列，每个子节点可在右侧水平展开自己的下级。

```
        根节点 (居中, y=30)
              │
    ┌─────────┴─────────┐
   子1 ─── 孙11 孙12    子2 ─── 孙21
   子3                 子4 ─── 孙41 孙42 孙43
   子5 ─── 孙51
   ...
```

排布公式：

```python
# 第一层：垂直单列
子y_i = 根y + 根高 + 垂直间距 + i * (子高 + 行间距)
子x = (画布宽度 - 子宽) / 2

# 第二层：在父节点右侧水平展开
孙j的x = 子x + 子宽 + 水平间距
孙起始y = 子y_i - (孙数量 * (孙高 + 间距)) / 2 + 子高/2
孙j的y = 孙起始y + j * (孙高 + 间距)
```

## 完整工作流示例

```powershell
# 1. 确定布局：文本宽度 ≈ 字数 × 16px，计算总宽度确保不溢出画布
# 2. 创建项目
& "C:\QuickTools\cli-anything\cli-anything-drawio.exe" --session my-sess project new -o "图表.drawio"

# 3. 添加所有形状（按布局计算 x,y）
& "C:\QuickTools\cli-anything\cli-anything-drawio.exe" --session my-sess --project "图表.drawio" shape add rounded -l "根节点" --x 325 --y 30 -w 200 -h 50

# 为每个子节点执行 shape add
# shape add 返回的 id 用于后续连线

# 4. 添加连线（根 → 每个子节点）
& "C:\QuickTools\cli-anything\cli-anything-drawio.exe" --session my-sess --project "图表.drawio" connect add <根ID> <子ID> --style orthogonal
# 连线使用 orthogonal 样式，自动走直角路径

# 5. 导出 PNG（超清：scale=2，边框 20px）
& "C:\QuickTools\cli-anything\cli-anything-drawio.exe" --session my-sess --project "图表.drawio" export render "图表.png" --crop --border 20 --scale 2 --overwrite

# 6. 用桌面应用打开验证（可选）
Start-Process "C:\Program Files\draw.io\draw.io.exe" -ArgumentList "图表.drawio"
```

## Export（导出）

默认导出为 **PNG** 格式。支持 `png`、`pdf`、`svg`、`vsdx`、`xml`。

常用参数：

| 参数 | 说明 |
|------|------|
| `-f png` | 格式（默认 PNG） |
| `--crop` | 裁剪到内容边界 |
| `--border 20` | 边框留白宽度（像素） |
| `--scale 2` | 缩放倍数（2x 超清，默认） |
| `--transparent` | 透明背景 |
| `--overwrite` | 覆盖已有文件 |

```powershell
# 标准导出（PNG + 裁剪 + 超清 2x + 边框 20px）
& "C:\QuickTools\cli-anything\cli-anything-drawio.exe" export render "输出.png" --crop --border 20 --scale 2 --overwrite

# 更高清（3x 缩放）
& "C:\QuickTools\cli-anything\cli-anything-drawio.exe" export render "输出.png" --crop --border 20 --scale 3 --overwrite

# PDF 导出
& "C:\QuickTools\cli-anything\cli-anything-drawio.exe" export render "输出.pdf" -f pdf --crop --overwrite
```

## 注意事项

1. **节点 ID**：`shape add` 返回的 id 保存在输出中，需记录用于 `connect add`
2. **画布大小**：默认 850×1100，超过需在 draw.io 中手动调整
3. **中文宽度**：每个中文字 ≈ 14-16px，标签越长宽度需越大
4. **连接线样式**：`--style orthogonal` 生成直角连线，树形图推荐；`straight` 直线；`curved` 曲线
5. **会话管理**：所有命令需带相同 `--session` 和 `--project` 保持状态
6. **文件格式**：`.drawio` 文件是 XML 格式，可直接被 draw.io 桌面应用打开
