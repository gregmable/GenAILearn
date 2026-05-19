# SharePoint Publish Checklist (GenAI Learning)

This guide is tailored to this repository and assumes deployment to a SharePoint document library.

## 1) Create the SharePoint target

1. Create a document library, for example: `GenAILearningSite`.
2. In library settings, keep files opening in browser.
3. Ensure users have at least Read access.

## 2) Upload this site content

Upload these files/folders from the repo root:

- `index.html`
- `login.html`
- `resources.html`
- `glossary.html`
- `styles.css`
- `site.js`
- `phase1-1.html`
- `phase1-2.html`
- `phase1-3.html`
- `phase1-4.html`
- `phase1-5.html`
- `phase1-6.html`
- `phase1-quiz.html`
- `phase2-1.html`
- `phase2-2.html`
- `phase2-3.html`
- `phase2-4.html`
- `phase2-5.html`
- `phase2-6.html`
- `phase2-quiz.html`
- `phase3-1.html`
- `phase3-2.html`
- `phase3-3.html`
- `phase3-4.html`
- `phase3-5.html`
- `phase3-6.html`
- `phase3-7.html`
- `phase3-quiz.html`
- `phase4-1.html`
- `phase4-2.html`
- `phase4-3.html`
- `phase4-4.html`
- `phase4-5.html`
- `phase4-6.html`
- `phase4-7.html`
- `phase4-quiz.html`
- `assets/` (full folder)

Notes:
- Redirect config files (`web.config`, `_redirects`, `vercel.json`, `staticwebapp.config.json`, `firebase.json`) are not used by SharePoint hosting.
- Keep relative file/folder structure unchanged.

## 3) Start URL to share with users

After upload, use the direct browser URL to `index.html` inside the library, for example:

`https://<tenant>.sharepoint.com/sites/<site>/<library>/index.html`

## 4) SharePoint validation pass

Run this quick test after publishing:

1. Open `index.html` from SharePoint.
2. Sign in through `login.html` and return to the site.
3. Open a Phase 1 content page and confirm styles/images load.
4. Open `phase1-quiz.html` and complete quiz from first question to results.
5. Confirm next phase quiz lock/unlock behavior still works.
6. Confirm sidebar collapse toggle works and persists.
7. Confirm `phase1-5.html` redirects to `phase4-7.html`.
8. Confirm external Pega product links open in new tabs.

## 5) Known SharePoint behavior differences

- No host-level redirects from your redirect config files.
- URLs are library paths, not clean root-hosted paths.
- Storage is browser localStorage, so progress is per-browser profile/device.

## 6) Optional: create a clean upload package locally

Run from repo root in PowerShell to generate a zip with only deployable site assets:

```powershell
$files = @(
  'index.html','login.html','resources.html','glossary.html','styles.css','site.js',
  'phase1-1.html','phase1-2.html','phase1-3.html','phase1-4.html','phase1-5.html','phase1-6.html','phase1-quiz.html',
  'phase2-1.html','phase2-2.html','phase2-3.html','phase2-4.html','phase2-5.html','phase2-6.html','phase2-quiz.html',
  'phase3-1.html','phase3-2.html','phase3-3.html','phase3-4.html','phase3-5.html','phase3-6.html','phase3-7.html','phase3-quiz.html',
  'phase4-1.html','phase4-2.html','phase4-3.html','phase4-4.html','phase4-5.html','phase4-6.html','phase4-7.html','phase4-quiz.html'
)

$staging = Join-Path $PWD 'sharepoint-publish-package'
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging | Out-Null

foreach ($f in $files) {
  Copy-Item -Path (Join-Path $PWD $f) -Destination (Join-Path $staging $f) -Force
}
Copy-Item -Path (Join-Path $PWD 'assets') -Destination (Join-Path $staging 'assets') -Recurse -Force

$zipPath = Join-Path $PWD 'GenAILearning-SharePoint-Publish.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipPath -Force

Write-Host "Created: $zipPath"
```

Then upload the zip contents (not the zip itself) into the SharePoint library.
