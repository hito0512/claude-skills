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
  "tasks": [
    {
      "title": "任务标题",
      "description": "支持 **Markdown** 的描述内容",
      "status": "todo",
      "tags": ["工作", "前端"],
      "startDate": 1747612800000,
      "endDate": null,
      "createdAt": 1747612800000
    }
  ]
}
```

## 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `title` | `string` | 是 | 任务标题 |
| `description` | `string` | 否 | Markdown 描述 |
| `status` | `string` | 是 | `todo` / `doing` / `done` / `unfinish` |
| `tags` | `string[]` | 否 | 标签数组 |
| `startDate` | `number\|null` | 否 | 开始日期时间戳，默认创建时间 |
| `endDate` | `number\|null` | 否 | 结束日期时间戳 |
| `createdAt` | `number` | 否 | 创建时间戳，自动生成 |
| `archived` | `boolean` | 否 | 归档标记，默认 `false` |

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
# 生成导入文件示例
cat > tasks.json << 'EOF'
{
  "tasks": [
    { "title": "任务1", "status": "todo", "tags": ["工作"] }
  ]
}
EOF
```

### 调试

```bash
# 定位挂件块
cli-anything-siyuan search "DynamicTodo"
```
