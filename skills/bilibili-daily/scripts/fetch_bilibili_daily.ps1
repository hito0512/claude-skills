#Requires -Version 5.1

<#
.SYNOPSIS
    B站 AI 方向每日动态日报生成脚本。
.DESCRIPTION
    遍历预设的关注方向及其关键词，通过 B站 公开 API 搜索每个关键词的最新视频，
    过滤出 24 小时内发布的结果，汇总去重后生成结构化日报。
.PARAMETER OutputDir
    日报输出目录。默认 E:\workspace\bilibili-daily
.PARAMETER HoursBack
    搜索时间范围（小时）。默认 24
.PARAMETER MaxPerKeyword
    每个关键词最多返回结果数。默认 10
.PARAMETER Date
    指定日期（yyyy-MM-dd）。默认当天
.EXAMPLE
    # 生成今日日报
    .\fetch_bilibili_daily.ps1

    # 生成最近 48 小时的日报
    .\fetch_bilibili_daily.ps1 -HoursBack 48
#>

param(
    [string]$OutputDir = "E:\workspace\bilibili-daily",
    [int]$HoursBack = 24,
    [int]$MaxPerKeyword = 10,
    [string]$Date = (Get-Date -Format "yyyy-MM-dd")
)

$ErrorActionPreference = "Stop"

# 关注方向配置（以开源大模型为核心）
$topics = @(
    @{
        name = "开源大模型"
        keywords = @("开源大模型", "DeepSeek", "Qwen", "LLaMA", "ChatGLM", "Mistral", "Gemma", "开源LLM")
    },
    @{
        name = "推理部署"
        keywords = @("llama.cpp", "vllm", "Ollama", "GGUF", "推理部署", "模型量化")
    },
    @{
        name = "视频生成"
        keywords = @("视频生成", "Open-Sora", "CogVideo", "VideoCrafter", "文生视频", "开源视频模型", "LTX", "Wan")
    },
    @{
        name = "图像生成"
        keywords = @("Stable Diffusion", "Flux", "DiT", "ComfyUI", "扩散模型", "图像生成")
    },
    @{
        name = "多模态"
        keywords = @("多模态", "LLaVA", "视觉语言模型", "VLM", "DeepSeek-VL", "Qwen-VL")
    }
)

# 请求头（模拟浏览器）
$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
    "Referer" = "https://www.bilibili.com/"
    "Accept" = "application/json, text/plain, */*"
}

# 确保输出目录存在
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$results = @{}  # topicName -> @{ bvid -> videoInfo }
$allBvids = @{} # 全局去重
$cutoffTime = (Get-Date).AddHours(-$HoursBack)
$totalRequests = 0
$maxRequests = 60  # 软限制，防止被 ban

function Write-Log {
    param([string]$Message)
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] $Message"
}

function Decode-HtmlEntities {
    param([string]$Text)
    $text = $Text -replace '&amp;', '&'
    $text = $text -replace '&lt;', '<'
    $text = $text -replace '&gt;', '>'
    $text = $text -replace '&quot;', '"'
    $text = $text -replace '&#39;', "'"
    $text = $text -replace '#39;', "'"
    # 去除 <em> 等 HTML 标签
    $text = $text -replace '<[^>]+>', ''
    return $text
}

function Convert-UnixTime {
    param([long]$UnixTimestamp)
    return (Get-Date -Date "1970-01-01").AddSeconds($UnixTimestamp).ToLocalTime()
}

function Format-Duration {
    param([int]$Seconds)
    $h = [Math]::Floor($Seconds / 3600)
    $m = [Math]::Floor(($Seconds % 3600) / 60)
    $s = $Seconds % 60
    if ($h -gt 0) { return "${h}h${m}m" }
    elseif ($m -gt 0) { return "${m}m${s}s" }
    else { return "${s}s" }
}

function Invoke-BilibiliSearch {
    param([string]$Keyword, [int]$Page = 1, [int]$PageSize = 20)

    $encoded = [System.Web.HttpUtility]::UrlEncode($Keyword)
    $url = "https://api.bilibili.com/x/web-interface/search/type?search_type=video&keyword=$encoded&page=$Page&pagesize=$PageSize&order=pubdate"

    try {
        $resp = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 10
        return $resp
    }
    catch {
        Write-Log "搜索 '$Keyword' 失败: $_"
        return $null
    }
}

# ---- 主循环 ----
Write-Log "开始抓取 B站 AI 方向动态（最近 ${HoursBack}h）"
Write-Log "关注方向: $($topics.name -join ', ')"

foreach ($topic in $topics) {
    $topicName = $topic.name
    $topicResults = @{}
    Write-Log "--- [$topicName] ---"

    foreach ($kw in $topic.keywords) {
        if ($totalRequests -ge $maxRequests) {
            Write-Log "达到请求上限 ($maxRequests)，停止搜索"
            break
        }

        Write-Log "  搜索关键词: $kw"
        Start-Sleep -Milliseconds 1500  # 请求间隔，避免限流
        $resp = Invoke-BilibiliSearch -Keyword $kw
        $totalRequests++

        if ($null -eq $resp -or $resp.code -ne 0) {
            Write-Log "  搜索失败，跳过 (code=$($resp.code))"
            continue
        }

        $items = $resp.data.result
        if ($null -eq $items -or $items.Count -eq 0) {
            Write-Log "  无结果"
            continue
        }

        $count = 0
        foreach ($item in $items) {
            if ($count -ge $MaxPerKeyword) { break }

            $bvid = $item.bvid
            if ([string]::IsNullOrEmpty($bvid)) { continue }

            $pubTime = Convert-UnixTime -UnixTimestamp $item.pubdate
            if ($pubTime -lt $cutoffTime) { continue }  # 跳过超时范围的

            # 全局去重
            if ($allBvids.ContainsKey($bvid)) { continue }
            $allBvids[$bvid] = $true

            # 构建视频信息
            $video = @{
                bvid = $bvid
                title = Decode-HtmlEntities -Text $item.title
                author = $item.author
                mid = $item.mid
                play = [long]$item.play
                danmaku = [int]$item.video_review
                duration = [int]$item.duration
                pubdate = $pubTime
                tag = if ($item.tag) { Decode-HtmlEntities -Text $item.tag } else { "" }
                description = if ($item.description) { Decode-HtmlEntities -Text $item.description.Substring(0, [Math]::Min($item.description.Length, 120)) } else { "" }
                pic = $item.pic
                arcurl = "https://www.bilibili.com/video/$bvid"
            }

            $topicResults[$bvid] = $video
            $count++
        }

        Write-Log "  本次新增: $count 条"
    }

    if ($topicResults.Count -gt 0) {
        $results[$topicName] = $topicResults.Values | Sort-Object pubdate -Descending
    }

    if ($totalRequests -ge $maxRequests) { break }
}

# ---- 生成日报 ----
$now = Get-Date
$reportPath = Join-Path $OutputDir "daily-report-${Date}.md"
$totalVideos = 0

# 日报 Header
$reportLines = @()
$reportLines += "# B站 AI 方向每日动态日报"
$reportLines += ""
$reportLines += "**日期**: $Date  |  **生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  |  **时间范围**: 最近 ${HoursBack} 小时"
$reportLines += ""
$reportLines += $("---" * 20)
$reportLines += ""

if ($results.Count -eq 0) {
    $reportLines += "今日暂无符合条件的视频更新。"
    $reportLines += ""
    $reportLines += "可能原因："
    $reportLines += "- 该时间范围内没有相关方向的新视频发布"
    $reportLines += "- B站 API 限流导致部分请求失败"
    $reportLines += "- 可以尝试扩大时间范围（如 -HoursBack 48）重新抓取"
}
else {
    # 统计信息
    $reportLines += "## 📊 概览"
    $reportLines += ""
    $reportLines += "| 方向 | 视频数 | 代表视频 |"
    $reportLines += "|---|---|---|"
    foreach ($topicName in $results.Keys) {
        $videos = $results[$topicName]
        $firstTitle = if ($videos.Count -gt 0) { $videos[0].title.Substring(0, [Math]::Min($videos[0].title.Length, 30)) } else { "-" }
        $reportLines += "| $topicName | $($videos.Count) 个 | $firstTitle |"
        $totalVideos += $videos.Count
    }
    $reportLines += ""
    $reportLines += "**总计**: $totalVideos 个视频"
    $reportLines += ""

    # 各方向详情
    foreach ($topicName in $results.Keys) {
        $videos = $results[$topicName]
        $reportLines += ""
        $reportLines += $("---" * 15)
        $reportLines += ""
        $reportLines += "## $topicName"
        $reportLines += ""

        $i = 1
        foreach ($v in $videos) {
            $pubStr = $v.pubdate.ToString("MM-dd HH:mm")
            $durStr = Format-Duration -Seconds $v.duration
            $playStr = if ($v.play -ge 10000) { "{0:N1}万" -f ($v.play / 10000) } else { "$($v.play)" }
            $danmakuStr = if ($v.danmaku -ge 10000) { "{0:N1}万" -f ($v.danmaku / 10000) } else { "$($v.danmaku)" }

            $reportLines += "### $i. $($v.title)"
            $reportLines += ""
            $reportLines += "| 项目 | 内容 |"
            $reportLines += "|---|---|"
            $reportLines += "| UP主 | $($v.author) |"
            $reportLines += "| 时长 | $durStr |"
            $reportLines += "| 播放 | $playStr |"
            $reportLines += "| 弹幕 | $danmakuStr |"
            $reportLines += "| 发布 | $pubStr |"
            if ($v.description) {
                $desc = $v.description -replace '\|', '｜'
                $reportLines += "| 简介 | $desc |"
            }
            $reportLines += "| 链接 | [$($v.arcurl)]($($v.arcurl)) |"
            $reportLines += ""
            $i++
        }
    }
}

$reportLines += ""
$reportLines += $("---" * 20)
$reportLines += ""
$reportLines += "*日报由 bilibili-daily skill 自动生成 | 数据来源: B站公开 API*"
$reportLines += "*关注方向: $($topics.name -join ', ')*"
$reportLines += "*生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*"

# 写入文件
$reportContent = $reportLines -join "`r`n"
Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8

Write-Log ""
Write-Log "=" * 50
Write-Log "日报完成!"
Write-Log "文件: $reportPath"
Write-Log "总视频数: $totalVideos"
Write-Log "涉及方向: $($results.Count) 个"
Write-Log "API 请求次数: $totalRequests"

# 返回结构化结果供 Claude 直接使用
$summary = @{
    date = $Date
    totalVideos = $totalVideos
    topics = @{}
}

foreach ($topicName in $results.Keys) {
    $topicSummary = @()
    foreach ($v in $results[$topicName]) {
        $topicSummary += @{
            title = $v.title
            author = $v.author
            play = $v.play
            danmaku = $v.danmaku
            duration = $v.duration
            pubdate = $v.pubdate.ToString("yyyy-MM-dd HH:mm")
            url = $v.arcurl
        }
    }
    $summary.topics[$topicName] = $topicSummary
}

return $summary
