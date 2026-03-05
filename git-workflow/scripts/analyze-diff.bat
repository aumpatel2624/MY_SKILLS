@echo off
REM analyze-diff.bat
REM Produces a structured summary of current git changes.
REM Run this at the start of the workflow to get a clear picture.
REM Usage: analyze-diff.bat

echo ========================================
echo   GIT DIFF ANALYSIS
echo ========================================

echo.
echo --- CURRENT BRANCH ---
git branch --show-current

echo.
echo --- STATUS SUMMARY ---
git status --short

echo.
echo --- FILES CHANGED (unstaged) ---
git diff --name-status

echo.
echo --- FILES CHANGED (staged) ---
git diff --cached --name-status

echo.
echo --- CHANGE STATS (unstaged) ---
git diff --stat

echo.
echo --- CHANGE STATS (staged) ---
git diff --cached --stat

echo.
echo --- RECENT COMMITS (last 5) ---
git log --oneline -5

echo.
echo --- STAGED DIFF (preview) ---
git diff --cached

echo.
echo --- UNSTAGED DIFF (preview) ---
git diff

echo.
echo ========================================
echo   END OF ANALYSIS
echo ========================================
