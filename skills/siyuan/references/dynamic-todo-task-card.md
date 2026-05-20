---
name: dynamic-todo-task-card
description: DynamicTodo 挂件任务卡片 JSON 格式说明，供 Agent 通过思源 API 创建/修改任务
---

# DynamicTodo 任务卡片

[DynamicTodo](https://github.com/hito0512/DynamicTodo) 是思源笔记的挂件式任务看板，支持看板、日历、统计、标签等视图。

## 创建任务

通过 `cli-anything-siyuan block update <挂件块ID> <data>` 修改挂件块属性 `custom-tasks` 来添加任务。

```json
{
  "title": "任务标题",
  "description": "支持 **Markdown** 的描述内容",
  "status": "todo",
  "tags": ["工作", "前端"],
  "startDate": 1747612800000,
  "endDate": null,
  "createdAt": 1747612800000
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

## 持久化格式

数据以 JSON 字符串存入思源笔记块属性 `custom-tasks` 中：

```json
{
  "version": "1.0.0",
  "tasks": [
    { "id": "...", "title": "...", "status": "todo", ... }
  ],
  "updatedAt": 1747612800000
}
```

## 操作方法

### 查询现有任务

```bash
cli-anything-siyuan block get <挂件块ID>
# 查看 custom-tasks 属性中的 JSON
```

### 添加任务

1. 用 `block get` 获取当前 `custom-tasks`
2. 解析 JSON，在 `tasks` 数组中追加新任务对象
3. 用 `block update` 写回完整的 `custom-tasks`

### 调试

```bash
# 定位挂件块
cli-anything-siyuan search "DynamicTodo"

# 查看块属性
cli-anything-siyuan block get <block-id>
```
