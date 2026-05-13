param(
    [string]$RepoDir = "E:\workspace\github"
)

$claudeFile = Join-Path $RepoDir "CLAUDE.md"

# Scan all directories (repos)
$repos = Get-ChildItem $RepoDir -Directory | Where-Object { $_.Name -ne ".git" }

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# GitHub Repositories")
$lines.Add("")
$lines.Add(('Local GitHub repo dir: {0}' -f $RepoDir))
$lines.Add("")
$lines.Add("## Repositories")
$lines.Add("")

if ($repos.Count -eq 0) {
    $lines.Add("*(no repos yet)*")
} else {
    foreach ($repo in $repos) {
        $repoPath = $repo.FullName
        $gitDir = Join-Path $repoPath ".git"

        if (Test-Path $gitDir) {
            $remoteUrl = & git -C $repoPath remote get-url origin 2>$null
            if (-not $remoteUrl) { $remoteUrl = "(local only, no remote)" }

            $desc = & git -C $repoPath log -1 --format="%s" 2>$null
            if (-not $desc) { $desc = "" }

            $bullet = '- **{0}**' -f $repo.Name
            $lines.Add($bullet)
            if ($desc) {
                $lines.Add(('   - {0}' -f $desc))
            }
            $lines.Add(('   - `{0}`' -f $remoteUrl))
        } else {
            $lines.Add(('- **{0}** (not a git repo)' -f $repo.Name))
        }
        $lines.Add("")
    }
}

$lines.Add("---")
$lines.Add("")
$lines.Add("*CLAUDE.md auto-managed by github-kb skill. Updated on repo add/remove.*")

$content = $lines -join "`r`n"
Set-Content -Path $claudeFile -Value $content -Encoding UTF8

Write-Output ('CLAUDE.md updated. Scanned {0} repos.' -f $repos.Count)
