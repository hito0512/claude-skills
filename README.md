# claude-skills

Claude Code 技能合集仓库。

## 技能列表

| 技能 | 目录 | 说明 |
|------|------|------|
| gitkb | `skills/gitkb/` | GitHub 仓库知识库 + HuggingFace/ModelScope 搜索 |
| dockb | `skills/dockb/` | 本地文件知识库管理工具 |
| siyuan | `skills/siyuan/` | 思源笔记 CLI 工具操作知识库 |

## 安装

```bash
# 安装所有技能（全局）
npx skills add hito0512/claude-skills -g -y

# 安装单个技能
npx skills add hito0512/claude-skills --skill siyuan -g -y

# 查看已安装技能
npx skills ls -g
```
