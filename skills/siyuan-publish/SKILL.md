---
name: siyuan-publish
description: 思源笔记挂件发布到集市的工作流，从打包 zip 到创建 GitHub Release。
---

# 思源挂件发布流程

从打包到上架集市的完整步骤。

## 1. 打包 package.zip

进入挂件目录，将必需文件打包：

```powershell
cd "挂件目录"
Compress-Archive -Path CHANGELOG.md, LICENSE, README.md, icon.png, img, index.html, preview, preview.png, script, static, style.css, widget.json -DestinationPath package.zip -Force
```

**必需文件清单：**

| 文件 | 说明 |
|------|------|
| `icon.png` | 160x160 挂件图标 |
| `preview.png` | 1024x768 预览图 |
| `README*.md` | 自述文件 |
| `widget.json` | 挂件配置 |
| `index.html` | 入口文件 |
| `script/` | JS 脚本目录 |
| `style.css` | 样式文件 |

`widget.json` 格式参考：

```json
{
  "name": "widget-name",
  "author": "your-name",
  "url": "https://github.com/your-name/widget-repo",
  "version": "0.2.0",
  "minAppVersion": "2.9.3",
  "displayName": {
    "default": "Widget Name",
    "zh_CN": "挂件名称"
  },
  "description": {
    "default": "Description.",
    "zh_CN": "描述。"
  },
  "readme": {
    "default": "README.md",
    "zh_CN": "README.md"
  }
}
```

## 2. 提交 Git 并推送

```bash
# 排除无需提交的文件（创建 .gitignore）
echo ".claude/" >> .gitignore
echo "0000.png" >> .gitignore
echo "plan.md" >> .gitignore
echo "CLAUDE.md" >> .gitignore

# 已跟踪的 CLAUDE.md 需要从远端删除
git rm --cached CLAUDE.md

# 提交
git add -A
git commit -m "feat: v版本号 更新说明"
git push
```

## 3. 创建 GitHub Release

```bash
# 确保在挂件目录
cd "挂件目录"

# 创建 Release 并上传 package.zip
gh release create v版本号 \
  --title "v版本号" \
  --notes "## 更新内容

- 更新说明1
- 更新说明2" \
  package.zip
```

示例：

```bash
gh release create v0.2.0 \
  --title "v0.2.0" \
  --notes "## 更新内容

- 新增日历视图
- 修复若干问题" \
  package.zip
```

## 4. 集市自动更新

发布 Release 后无需任何操作，集市会自动拉取更新：

- 同步频率：每 1-3 小时
- 查看状态：https://github.com/siyuan-note/bazaar/actions/workflows/stage.yml

## 首次上架（仅首次）

如果挂件还未上架集市，需要额外提交 PR：

1. Fork [siyuan-note/bazaar](https://github.com/siyuan-note/bazaar)
2. 编辑 `widgets.txt`，添加一行：`你的用户名/仓库名`
3. 提交 PR 到 main 分支
4. 等待审核合并

## 版本号管理

- 遵循 [semver](https://semver.org/lang/zh-CN/) 规范
- 每次发布前检查 `widget.json` 中的 version 字段
- 远程已有相同版本号时，先递增再发布
