# Simple git init + optional GitHub push (uses gh if available)
# Run from project root:
#   powershell -ExecutionPolicy Bypass -File .\deploy_simple.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host 'git is not installed or not on PATH. Install git and re-run.' -ForegroundColor Red
  exit 1
}

# ensure .gitignore contains safe entries
$gi = Join-Path $root '.gitignore'
if (-not (Test-Path $gi)) { '' | Out-File $gi -Encoding utf8 }
$entries = @('.env','/.venv','node_modules/','dist/','*.bak_*')
foreach ($e in $entries) {
  if (-not (Select-String -Path $gi -Pattern ("^\s*{0}\s*$" -f [regex]::Escape($e)) -Quiet)) {
    Add-Content -Path $gi -Value $e
  }
}

# init repo if needed
if (-not (Test-Path (Join-Path $root '.git'))) {
  git init
  Write-Host 'Initialized git repository'
}

# remove tracked .env if present
try {
  git ls-files --error-unmatch .env 2>$null | Out-Null
  git rm --cached .env 2>$null
  Write-Host 'Removed tracked .env (if it existed)'
} catch {}

# commit changes
git add -A
$hasChanges = (git status --porcelain)
if ($hasChanges) {
  git commit -m 'chore: initial commit' 2>$null
  Write-Host 'Committed changes'
} else {
  Write-Host 'No changes to commit'
}

git branch -M main

# If gh exists, offer to create repo and push
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
  $create = Read-Host 'Create GitHub repo and push now using gh? (y/n)'
  if ($create -match '^[Yy]') {
    $repo = Read-Host 'Enter repo name (user/repo or just repo). Leave empty to use folder name'
    if (-not $repo) { $repo = (Split-Path $root -Leaf) }
    $vis = Read-Host 'Visibility (public/private) [public]'
    if (-not $vis) { $vis = 'public' }
    & gh repo create $repo --$vis --source=. --remote=origin --push
    if ($LASTEXITCODE -eq 0) {
      Write-Host 'Repository created and pushed to GitHub (origin).'
    } else {
      Write-Host 'gh failed or was cancelled. You can add remote manually. See below.'
    }
  } else {
    Write-Host 'Skipping repo creation. You can add a remote later.'
  }
} else {
  Write-Host ''
  Write-Host 'gh CLI not found. To push to GitHub do this manually:'
  Write-Host '1) Create a new repository on https://github.com/new'
  Write-Host '2) Run these commands (replace <URL>):'
  Write-Host '   git remote add origin <URL>'
  Write-Host '   git push -u origin main'
}

Write-Host ''
Write-Host 'Done. Next suggested steps:'
Write-Host '- Do NOT commit .env. Keep secrets out of repo.'
Write-Host '- If you want CI/deploy (GitHub Actions), I can add a workflow file next.'
```# filepath: C:\Users\161621\Desktop\Github_CoPilot\user-onboarding-platform\deploy_simple.ps1
# Simple git init + optional GitHub push (uses gh if available)
# Run from project root:
#   powershell -ExecutionPolicy Bypass -File .\deploy_simple.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host 'git is not installed or not on PATH. Install git and re-run.' -ForegroundColor Red
  exit 1
}

# ensure .gitignore contains safe entries
$gi = Join-Path $root '.gitignore'
if (-not (Test-Path $gi)) { '' | Out-File $gi -Encoding utf8 }
$entries = @('.env','/.venv','node_modules/','dist/','*.bak_*')
foreach ($e in $entries) {
  if (-not (Select-String -Path $gi -Pattern ("^\s*{0}\s*$" -f [regex]::Escape($e)) -Quiet)) {
    Add-Content -Path $gi -Value $e
  }
}

# init repo if needed
if (-not (Test-Path (Join-Path $root '.git'))) {
  git init
  Write-Host 'Initialized git repository'
}

# remove tracked .env if present
try {
  git ls-files --error-unmatch .env 2>$null | Out-Null
  git rm --cached .env 2>$null
  Write-Host 'Removed tracked .env (if it existed)'
} catch {}

# commit changes
git add -A
$hasChanges = (git status --porcelain)
if ($hasChanges) {
  git commit -m 'chore: initial commit' 2>$null
  Write-Host 'Committed changes'
} else {
  Write-Host 'No changes to commit'
}

git branch -M main

# If gh exists, offer to create repo and push
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
  $create = Read-Host 'Create GitHub repo and push now using gh? (y/n)'
  if ($create -match '^[Yy]') {
    $repo = Read-Host 'Enter repo name (user/repo or just repo). Leave empty to use folder name'
    if (-not $repo) { $repo = (Split-Path $root -Leaf) }
    $vis = Read-Host 'Visibility (public/private) [public]'
    if (-not $vis) { $vis = 'public' }
    & gh repo create $repo --$vis --source=. --remote=origin --push
    if ($LASTEXITCODE -eq 0) {
      Write-Host 'Repository created and pushed to GitHub (origin).'
    } else {
      Write-Host 'gh failed or was cancelled. You can add remote manually. See below.'
    }
  } else {
    Write-Host 'Skipping repo creation. You can add a remote later.'
  }
} else {
  Write-Host ''
  Write-Host 'gh CLI not found. To push to GitHub do this manually:'
  Write-Host '1) Create a new repository on https://github.com/new'
  Write-Host '2) Run these commands (replace <URL>):'
  Write-Host '   git remote add origin <URL>'
  Write-Host '   git push -u origin main'
}

Write-Host ''
Write-Host 'Done. Next suggested steps:'
Write-Host '- Do NOT commit .env. Keep secrets out of repo.'
Write-Host '- If you want CI/deploy (GitHub Actions), I can add a workflow file next.'