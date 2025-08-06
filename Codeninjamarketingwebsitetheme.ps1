


$themeName         = 'Code Ninja - Marketing Website'

$safeName = $themeName.ToLower() `
  -replace '[^a-z0-9]', '-' `
  -replace '-+', '-'
$safeName = $safeName.Trim('-')

# Build branch name and destination folder
$branchName     = "theme-$safeName"
$localRepoPath  = Join-Path (Get-Location) 'repo'
$repoUrl        = "https://$systemAccessToken@grahamsio.visualstudio.com/CN%20Website/_git/Hubspot"
$destThemePath  = Join-Path $localRepoPath "themes\$themeName"

Write-Host "Theme name:      '$themeName'"
Write-Host "Sanitized slug:  '$safeName'"
Write-Host "Branch to create: '$branchName'"
Write-Host "Local repo path: '$localRepoPath'"
Write-Host "Theme dest path: '$destThemePath'"

# 2) Clone repo
if (Test-Path $localRepoPath) { Remove-Item -Recurse -Force $localRepoPath }
git clone $repoUrl $localRepoPath
Set-Location $localRepoPath

# 3) Checkout or create branch
git checkout -B $branchName

# 4) Install HubSpot CLI
#npm install -g @hubspot/cli

# 5) Write non-interactive CLI config
$configDir  = Join-Path $env:USERPROFILE '.hubspotcli'
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
$configFile = Join-Path $configDir 'hubspot.config.yml'
@"
defaultPortal: $hubspotPortalId
portals:
  - name: $hubspotPortalId
    portalId: $hubspotPortalId
    personalAccessKey: $hubspotPat
"@ | Out-File -FilePath $configFile -Encoding utf8

# 6) Fetch into themes/<OriginalName>
$parent = Split-Path $destThemePath -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
hs fetch $themeName $destThemePath --overwrite

# 7) Commit & push
git add "themes/$themeName"
if (-not (git diff --cached --quiet)) {
  git config user.name  'AutomatedBuild'
  git config user.email 'build@yourdomain.com'
  git commit -m "Sync theme '$themeName' (slug: $safeName)"
  Write-Host "Pushing to branch '$branchName'..."
  & git push origin "HEAD:$branchName"
} else {
  Write-Host "No changes to commit."
}

Write-Host "✅ Done."

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
    # make sure both URL and refspec are individually quoted
& git push "$repoUrl" "HEAD:$branchName" 2>&1 | Write-Host


} else {
    Write-Host "No changes to commit."
}

Write-Host "✅ Done."
