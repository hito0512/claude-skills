param(
    [string]$RepoDir = "E:\workspace\github"
)

$claudeFile = Join-Path $RepoDir "CLAUDE.md"

function Get-GhInfo {
    param([string]$RemoteUrl)
    if ($RemoteUrl -match 'github\.com[/:]([^/]+)/([^/]+?)(?:\.git)?$') {
        $owner = $matches[1]
        $repo = $matches[2]
        try {
            return & gh repo view "$owner/$repo" --json description,language 2>$null | ConvertFrom-Json
        } catch { }
    }
    return $null
}

function Get-RepoLanguage {
    param([string]$RepoPath)
    $langMap = @{
        'package.json'       = 'JavaScript / TypeScript'
        'Cargo.toml'         = 'Rust'
        'go.mod'             = 'Go'
        'pom.xml'            = 'Java'
        'build.gradle'       = 'Java / Kotlin'
        'requirements.txt'   = 'Python'
        'setup.py'           = 'Python'
        'pyproject.toml'     = 'Python'
        'CMakeLists.txt'     = 'C / C++'
        'Makefile'           = 'C / C++'
        'Gemfile'            = 'Ruby'
        'Cargo.lock'         = 'Rust'
        'composer.json'      = 'PHP'
        'Project.csproj'     = 'C#'
        'Solution.sln'       = 'C#'
        'Podfile'            = 'Swift / Objective-C'
    }
    foreach ($file in $langMap.Keys) {
        if (Test-Path (Join-Path $RepoPath $file)) { return $langMap[$file] }
    }
    # Check for .csproj files
    $csproj = Get-ChildItem $RepoPath -Filter *.csproj -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($csproj) { return 'C#' }

    # Fallback: search recursively in subdirectories
    $setupPy = Get-ChildItem $RepoPath -Filter setup.py -Recurse -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 1
    if ($setupPy) { return 'Python' }
    $pyproj = Get-ChildItem $RepoPath -Filter pyproject.toml -Recurse -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 1
    if ($pyproj) { return 'Python' }

    return $null
}

function Get-RepoDescription {
    param([string]$RepoPath, [string]$RepoName, [string]$RemoteUrl)

    # 优先从 README 提取中文描述
    $desc = Read-ReadmeDescription -RepoPath $RepoPath
    if ($desc) { return $desc }

    # 其次使用 GitHub API 描述（通常为英文）
    $ghInfo = Get-GhInfo -RemoteUrl $RemoteUrl
    if ($ghInfo -and $ghInfo.description) {
        return $ghInfo.description
    }

    # Last resort: last commit message
    $commitMsg = & git -C $RepoPath log -1 --format="%s" 2>$null
    if ($commitMsg) { return $commitMsg }

    return ""
}

function Read-ReadmeDescription {
    param([string]$RepoPath)

    # 优先尝试中文 README，再试英文
    $candidates = @("README.zh-CN.md", "README.md", "readme.md", "README")
    $readmePath = $null
    foreach ($name in $candidates) {
        $test = Join-Path $RepoPath $name
        if (Test-Path $test) { $readmePath = $test; break }
    }

    if (-not $readmePath) { return $null }

    $content = Get-Content $readmePath -TotalCount 50 -Encoding UTF8
    foreach ($line in $content) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^#{1,3}\s') { continue }
        if ($trimmed -match '^\[!\[') { continue }
        if ($trimmed -match '^<') { continue }
        if ($trimmed -match '^https?://') { continue }
        # 剥离 HTML 标签
        $trimmed = $trimmed -replace '<[^>]+>', ''
        $trimmed = $trimmed.Trim()
        if ($trimmed.Length -gt 20) {
            if ($trimmed.Length -gt 120) { $trimmed = $trimmed.Substring(0, 117) + "..." }
            return $trimmed
        }
    }
    return $null
}

# Scan all directories (repos)
$repos = Get-ChildItem $RepoDir -Directory | Where-Object { $_.Name -ne ".git" }

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# GitHub Repositories")
$lines.Add("")
$lines.Add(('本地 GitHub 仓库目录：{0}' -f $RepoDir))
$lines.Add("")
$lines.Add("## 仓库列表")
$lines.Add("")

if ($repos.Count -eq 0) {
    $lines.Add("*(暂无仓库)*")
} else {
    foreach ($repo in $repos) {
        $repoPath = $repo.FullName
        $gitDir = Join-Path $repoPath ".git"

        if (Test-Path $gitDir) {
            $remoteUrl = & git -C $repoPath remote get-url origin 2>$null
            if (-not $remoteUrl) { $remoteUrl = "(仅本地，无远程)" }

            $ghInfo = Get-GhInfo -RemoteUrl $remoteUrl
            $desc = Get-RepoDescription -RepoPath $repoPath -RepoName $repo.Name -RemoteUrl $remoteUrl
            $lang = if ($ghInfo -and $ghInfo.language) { $ghInfo.language } else { Get-RepoLanguage -RepoPath $repoPath }

            $lines.Add(('- **{0}**' -f $repo.Name))
            if ($desc) {
                $lines.Add(('  - {0}' -f $desc))
            }
            if ($lang) {
                $lines.Add(('  - 语言：{0}' -f $lang))
            }
            $lines.Add(('  - `{0}`' -f $remoteUrl))
        } else {
            $lines.Add(('- **{0}**（非 git 仓库）' -f $repo.Name))
        }
        $lines.Add("")
    }
}

$lines.Add("---")
$lines.Add("")
$lines.Add("*CLAUDE.md 由 github-kb skill 自动管理。添加/删除仓库后会自动更新。*")

$content = $lines -join "`r`n"
Set-Content -Path $claudeFile -Value $content -Encoding UTF8

Write-Output ("CLAUDE.md 已更新。扫描到 {0} 个仓库。" -f $repos.Count)
Write-Output "请检查每个仓库的描述是否为中文，如有英文请翻译为中文。"
