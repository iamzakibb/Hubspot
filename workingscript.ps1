

# Theme folder name in HubSpot:
$themeName         = 'DEV'

# Git branch to sync into:
$branchName        = 'theme-dev'

# ---------------------- end config ----------------------

# Prepare local paths
$root = (Get-Location)
$localRepoPath = Join-Path $root 'repo'
$repoUrl       = "https://$systemAccessToken@grahamsio.visualstudio.com/CN%20Website/_git/Hubspot"

# 1) Clone repo
if (Test-Path $localRepoPath) {
    Write-Host "Removing existing repo folder..."
    Remove-Item -Recurse -Force $localRepoPath
}
Write-Host "Cloning repo..."
git clone $repoUrl $localRepoPath
Set-Location $localRepoPath

# 2) Checkout branch
Write-Host "Checking out branch '$branchName'..."
git checkout -B $branchName

# 3) Install HubSpot CLI
Write-Host "Installing HubSpot CLI..."
#npm install -g @hubspot/cli

# 4) Write non-interactive CLI config
$configDir  = Join-Path $env:USERPROFILE '.hubspotcli'
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
$configFile = Join-Path $configDir 'hubspot.config.yml'
@"
defaultPortal: $hubspotPortalId
portals:
  - name: $hubspotPortalId
    portalId: $hubspotPortalId
    personalAccessKey: $hubspotPat
"@ | Out-File -FilePath $configFile -Encoding utf8

# 5) Fetch into themes/DEV
$dest = Join-Path $localRepoPath "themes\$themeName"
Write-Host "Fetching theme '$themeName' into '$dest'..."
# Ensure parent folder exists
$parent = Split-Path $dest -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
hs fetch $themeName $dest --overwrite

# 6) Commit & push
Write-Host "Staging changes..."
git add "themes/$themeName"

if (-not (git diff --cached --quiet)) {
    Write-Host "Committing..."
    git config user.name  'AutomatedBuild'
    git config user.email 'build@yourdomain.com'
    git commit -m "Automated sync of HubSpot theme '$themeName'"
    Write-Host "Pushing to remote..."
    # Push explicitly with credentials in URL
    Write-Host "Pushing to remote…"
    & git push $repoUrl HEAD:$branchName 2>&1 | Write-Host

} else {
    Write-Host "No changes to commit."
}

Write-Host "✅ Done."
