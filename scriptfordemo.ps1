

# === CONFIGURE THESE VARIABLES ===
# Your Azure DevOps OAuth or PAT which can access the repo:
$systemAccessToken = ''  

# Your HubSpot Personal Access Token:
#$hubspotPat        = ''

# Your HubSpot portal ID (e.g. 39646145):
$hubspotPortalId   = ''

# The HubSpot theme folder name to fetch (e.g. 'DEV'):
$themeName         = 'DEV'

# The Git branch you want to sync into (will be created if missing):
$branchName        = 'theme-dev'

# ---------------------- end config ----------------------

# Paths
$localRepoPath = Join-Path (Get-Location) 'repo'
$repoUrl       = "https://$systemAccessToken@grahamsio.visualstudio.com/CN%20Website/_git/Hubspot"

# 1) Clone the repo fresh
if (Test-Path $localRepoPath) {
    Write-Host "Removing existing folder $localRepoPath..."
    Remove-Item -Recurse -Force $localRepoPath
}
Write-Host "Cloning repo from $repoUrl..."
git clone $repoUrl $localRepoPath
Set-Location $localRepoPath

# 2) Create or checkout the target branch
Write-Host "Checking out branch '$branchName'..."
git checkout -B $branchName

# 3) Install the HubSpot CLI
Write-Host "Installing HubSpot CLI via npm (this may take a moment)..."
#npm install -g @hubspot/cli

# 5) Fetch the theme (overwrites local)
Write-Host "Fetching HubSpot theme '$themeName'..."
hs fetch $themeName --overwrite

# 6) Commit & push if there are changes
Write-Host "Staging changes under themes\$themeName..."
git pull origin $branchName
git add "themes/$themeName"

if (-not (git diff --cached --quiet)) {
    Write-Host "Committing and pushing updates..."
    git config user.name  'AutomatedBuild'
    git config user.email 'build@yourdomain.com'
    git commit -m "Automated sync of HubSpot theme '$themeName'"
    git push origin $branchName
}
else {
    Write-Host "No changes detected; nothing to commit."
}

Write-Host "✅ Done."
