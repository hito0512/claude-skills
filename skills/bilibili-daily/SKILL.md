---
name: bilibili-daily
description: B站每日AI动态追踪。在用户提到 b站/bilibili/哔哩哔哩/bili/哔哩/开源大模型/DeepSeek/Qwen/LLaMA/Mistral/ChatGLM/GGUF/llama.cpp/vllm/视频生成/Open-Sora/CogVideo/扩散模型/Stable Diffusion/Flux/ComfyUI/每日AI日报 时触发。通过B站公开 API 搜索开源大模型相关的最新视频，支持日报生成和关键词追踪。
---

# B站 AI 动态追踪 (bilibili-daily)

通过 B站 公开 API 获取开源大模型方向的最新视频资讯，生成每日动态日报。

关注方向（以开源大模型为核心）：
- **开源大模型** (DeepSeek, Qwen, LLaMA, ChatGLM, Mistral, Gemma, Yi, Baichuan)
- **推理部署** (llama.cpp, vllm, Ollama, GGUF, TensorRT-LLM)
- **视频生成** (Open-Sora, CogVideo, VideoCrafter, LTX, Wan, 开源视频模型)
- **图像生成** (Stable Diffusion, Flux, DiT, ComfyUI, 开源扩散模型)
- **多模态** (LLaVA, DeepSeek-VL, Qwen-VL, 开源视觉语言模型)

## 触发条件

用户提到以下关键词时触发：
- b站 / bilibili / 哔哩哔哩 / bili / 哔哩
- "每日日报" / "今天有什么新视频" / "AI 动态"
- 关注方向中的具体关键词（开源大模型、DeepSeek、推理部署、llama.cpp、vllm、视频生成、扩散模型等）
- "看看B站上XXX的最新进展"

## 核心流程

### 1. 搜索指定关键词的最新视频

```powershell
# 按发布时间排序搜索视频
$url = "https://api.bilibili.com/x/web-interface/search/type?search_type=video&keyword=$([System.Web.HttpUtility]::UrlEncode($keyword))&page=1&order=pubdate"
$result = Invoke-RestMethod $url -Headers @{ "User-Agent" = "Mozilla/5.0" }
$result.data.result | Select-Object title, author, play, video_review, pubdate, bvid, description
```

返回字段说明：
- `title` - 视频标题（HTML 实体编码，需解码）
- `author` - UP 主名称
- `play` - 播放量
- `video_review` - 弹幕数
- `pubdate` - 发布时间（Unix 时间戳）
- `bvid` - BV 号，视频地址为 `https://www.bilibili.com/video/{bvid}`
- `description` - 视频简介
- `tag` - 标签
- `pic` - 封面图 URL
- `duration` - 视频时长（秒）
- `mid` - UP 主 ID

向用户呈现结果时，**每条视频必须附带可点击的 B站 地址**，格式为 `https://www.bilibili.com/video/{bvid}`。

### 2. 获取视频详情

```powershell
$url = "https://api.bilibili.com/x/web-interface/view?bvid=$bvid"
$detail = Invoke-RestMethod $url -Headers @{ "User-Agent" = "Mozilla/5.0" }
$detail.data | Select-Object title, desc, stat, owner, aid, tid
```

返回关键字段：
- `stat.view` - 播放数
- `stat.like` - 点赞数
- `stat.coin` - 硬币数
- `stat.favorite` - 收藏数
- `stat.share` - 分享数
- `stat.danmaku` - 弹幕数
- `owner.name` - UP 主名称

### 3. 获取热搜榜单

```powershell
$url = "https://api.bilibili.com/x/web-interface/search/square?limit=50"
$hot = Invoke-RestMethod $url -Headers @{ "User-Agent" = "Mozilla/5.0" }
$hot.data | Select-Object show_name, keyword, status
```

### 4. 生成每日 AI 日报

遍历关注方向列表，对每个方向搜索最近 24 小时内的视频，汇总为结构化的日报。

```powershell
# 核心方向配置
$topics = @(
    @{ name = "开源大模型"; keywords = @("开源大模型", "DeepSeek", "Qwen", "LLaMA", "ChatGLM", "Mistral", "Gemma", "开源LLM") },
    @{ name = "推理部署"; keywords = @("llama.cpp", "vllm", "Ollama", "GGUF", "推理部署", "模型量化") },
    @{ name = "视频生成"; keywords = @("视频生成", "Open-Sora", "CogVideo", "VideoCrafter", "文生视频", "开源视频模型", "LTX", "Wan") },
    @{ name = "图像生成"; keywords = @("Stable Diffusion", "Flux", "DiT", "ComfyUI", "扩散模型", "图像生成") },
    @{ name = "多模态"; keywords = @("多模态", "LLaVA", "视觉语言模型", "VLM", "DeepSeek-VL", "Qwen-VL") }
)
```

脚本 `scripts/fetch_bilibili_daily.ps1` 会自动完成以下工作：
1. 遍历关注方向及其关键词
2. 对每个关键词搜索按发布时间排序的最新视频
3. 过滤出 24 小时内的结果
4. 按方向分组输出结构化日报
5. 结果写入 `E:\workspace\daily-report\bilibili-daily\daily-report-YYYY-MM-DD.md`

### 5. 深入查看单个视频

当用户对日报中的某个视频感兴趣时：

```powershell
# 查看视频详情
Invoke-RestMethod "https://api.bilibili.com/x/web-interface/view?bvid=<bvid>" -Headers @{ "User-Agent" = "Mozilla/5.0" }

# 查看 UP 主信息
Invoke-RestMethod "https://api.bilibili.com/x/space/acc/info?mid=<mid>" -Headers @{ "User-Agent" = "Mozilla/5.0" }

# 查看视频评论（可选）
Invoke-RestMethod "https://api.bilibili.com/x/v2/medialist/resource/list?type=1&biz_id=<aid>&ps=20" -Headers @{ "User-Agent" = "Mozilla/5.0" }
```

## 资源

### scripts/fetch_bilibili_daily.ps1

PowerShell 脚本，执行每日动态获取。功能：
1. 遍历所有关注方向及其关键词
2. 对每个关键词搜索 B站 最新视频（按发布时间排序）
3. 过滤出 24 小时内发布的结果
4. 汇总去重后输出结构化日报
5. 保存到 `E:\workspace\daily-report\bilibili-daily\` 目录

### 输出目录

日报文件保存到 `E:\workspace\daily-report\bilibili-daily\`：
- `daily-report-YYYY-MM-DD.md` - 当日日报
- `daily-report-YYYY-MM-DD.json` - 原始数据（可选）

## 注意事项

- B站 API 无需认证，但需要设置 `User-Agent` 请求头
- 注意请求频率限制，避免过快请求（建议每次请求间隔 1-2 秒）
- 视频标题可能包含 HTML 实体编码（`&amp;`、`&lt;` 等），需要解码
- `pubdate` 为 Unix 时间戳（秒），用 PowerShell 转换：`(Get-Date -Date "1970-01-01").AddSeconds($pubdate).ToLocalTime()`
- B站对未登录的 API 访问有一定限流，如果返回 412 状态码，说明需要更换策略
- 搜索结果中 `title` 字段可能包含 `<em>` 标签高亮关键词，需要去除
- 数据目录 `E:\workspace\bilibili-daily\` 由脚本自动创建
