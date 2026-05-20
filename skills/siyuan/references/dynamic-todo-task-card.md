---
name: dynamic-todo-task-card
description: DynamicTodo 挂件任务卡片 JSON 格式说明，供 Agent 生成导入用 JSON 文件
---

# DynamicTodo 任务卡片

[DynamicTodo](https://github.com/hito0512/DynamicTodo) 是思源笔记的挂件式任务看板，支持看板、日历、统计、标签等视图。

## JSON 格式（导入用）

生成以下 JSON 文件，用户在思源挂件中通过 **设置 → 导入数据** 导入。

```json
{
  "version": "1.0.0",
  "exportTime": "2026-05-20T03:33:26.128Z",
  "tasks": [
    {
      "id": "1779175153949-5rvsvbyc8",
      "title": "任务标题",
      "description": "支持 **Markdown** 的描述内容",
      "status": "todo",
      "createdAt": 1747612800000,
      "updatedAt": 1747612800000,
      "order": 0,
      "startDate": 1747612800000,
      "endDate": null,
      "archived": false,
      "tags": ["工作", "前端"]
    }
  ],
  "statusTexts": {
    "todo": "计划中",
    "doing": "进行中",
    "done": "已完成",
    "unfinish": "未完成"
  }
}
```

## 字段说明

### 顶层字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `version` | `string` | 是 | 数据格式版本，固定 `"1.0.0"` |
| `exportTime` | `string` | 是 | 导出时间 ISO 格式 |
| `tasks` | `object[]` | 是 | 任务数组 |
| `statusTexts` | `object` | 是 | 状态文字映射，如 `{"todo":"计划中","doing":"进行中","done":"已完成","unfinish":"未完成"}` |

### 任务字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | `string` | 是 | 唯一标识，格式 `时间戳-随机串` |
| `title` | `string` | 是 | 任务标题 |
| `description` | `string` | 否 | Markdown 描述 |
| `status` | `string` | 是 | `todo` / `doing` / `done` / `unfinish` |
| `createdAt` | `number` | 否 | 创建时间戳 |
| `updatedAt` | `number` | 否 | 更新时间戳 |
| `order` | `number` | 否 | 排序值 |
| `startDate` | `number\|null` | 否 | 开始日期时间戳 |
| `endDate` | `number\|null` | 否 | 结束日期时间戳 |
| `archived` | `boolean` | 否 | 归档标记，默认 `false` |
| `tags` | `string[]` | 否 | 标签数组 |

## 状态说明

| 状态值 | 显示文本 | 说明 |
|--------|----------|------|
| `todo` | 计划中 | 待办任务 |
| `doing` | 进行中 | 执行中任务 |
| `done` | 已完成 | 已完成任务 |
| `unfinish` | 未完成 | 未完成任务（如逾期） |

## 操作方法

### 生成导入文件

生成 JSON 文件（如 `tasks.json`）提供给用户，用户在 DynamicTodo 挂件中点击 **⚙️ → 导入数据** 选择文件即可导入。

```bash
# 1. 导出文档 markdown
cli-anything-siyuan export md <doc-id> > /tmp/doc.md

# 2. 生成 tasks.json 到桌面
cat > ~/Desktop/tasks.json << 'EOF'
{
  "version": "1.0.0",
  "exportTime": "2026-05-20T03:33:26.128Z",
  "tasks": [
    {
      "id": "生成时的时间戳-随机串",
      "title": "任务标题",
      "description": "",
      "status": "todo",
      "createdAt": 1747612800000,
      "updatedAt": 1747612800000,
      "order": 0,
      "startDate": null,
      "endDate": null,
      "archived": false,
      "tags": []
    }
  ],
  "statusTexts": {
    "todo": "计划中",
    "doing": "进行中",
    "done": "已完成",
    "unfinish": "未完成"
  }
}
EOF
```

### 调试

```bash
# 定位挂件块
cli-anything-siyuan search "DynamicTodo"
```
