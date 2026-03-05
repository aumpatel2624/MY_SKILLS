# analyze-diff.ps1
# Produces a structured summary of current git changes.
# Run this at the start of the workflow to get a clear picture.
#
# Usage:
#   .\analyze-diff.ps1
#
# If execution policy blocks it, run once:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

function Write-Section($title) {
    Write-Host ""
    Write-Host "--- $title ---" -ForegroundColor Cyan
}

function Run-Git($args) {
    $output = & git @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "(no output)" -ForegroundColor DarkGray
    } else {
        $output | ForEach-Object { Write-Host $_ }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  GIT DIFF ANALYSIS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Section "CURRENT BRANCH"
Run-Git "branch", "--show-current"

Write-Section "STATUS SUMMARY"
Run-Git "status", "--short"

Write-Section "FILES CHANGED (unstaged)"
Run-Git "diff", "--name-status"

Write-Section "FILES CHANGED (staged)"
Run-Git "diff", "--cached", "--name-status"

Write-Section "CHANGE STATS (unstaged)"
Run-Git "diff", "--stat"

Write-Section "CHANGE STATS (staged)"
Run-Git "diff", "--cached", "--stat"

Write-Section "RECENT COMMITS (last 5)"
Run-Git "log", "--oneline", "-5"

Write-Section "STAGED DIFF (preview)"
Run-Git "diff", "--cached"

Write-Section "UNSTAGED DIFF (preview)"
Run-Git "diff"

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  END OF ANALYSIS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
