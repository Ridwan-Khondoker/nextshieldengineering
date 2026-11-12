# ------------------------------------------------------------------
#  Next Shield Engineering - website setup for Windows
#
#  Run it by pasting this one line into PowerShell:
#    irm https://raw.githubusercontent.com/Ridwan-Khondoker/nextshieldengineering/claude/dazzling-fermat-xkohmo/setup/windows-setup.ps1 | iex
#
#  What it does:
#    1. Checks Windows can install apps (winget)
#    2. Installs Git (lets Claude save and upload changes)
#    3. Installs Claude Code and gives Claude some house rules
#    4. Downloads the website into %USERPROFILE%\nextshieldengineering
#    5. Puts three shortcuts on the desktop
#
#  It is safe to run again at any time: it skips anything already done.
# ------------------------------------------------------------------

& {
    $ErrorActionPreference = 'Stop'

    $RepoUrl   = 'https://github.com/Ridwan-Khondoker/nextshieldengineering.git'
    $RepoPage  = 'https://github.com/Ridwan-Khondoker/nextshieldengineering'
    $LiveSite  = 'https://web-production-5582235f.up.railway.app'
    $MyEmail   = 'aribhasan120@gmail.com'
    $Folder    = Join-Path $env:USERPROFILE 'nextshieldengineering'
    $ClaudeBin = Join-Path $env:USERPROFILE '.local\bin'

    $ClaudeNotes = @'

# About me
- I am not a programmer. Explain things in plain, simple language and avoid jargon.
- Before changing files, tell me in one or two sentences what you are about to change.

# Next Shield website (the nextshieldengineering folder)
- It is a static website: index.html plus the images folder. There is nothing to build or install.
- To preview a change, I double-click "Next Shield - Preview website" on my desktop (it opens index.html in my browser). Remind me to do that after each change.
- The main branch IS the live website: anything that reaches main goes live automatically within a few minutes.
- Never commit or push to main. When I am happy with a change, commit it to a new branch, push that branch, and give me the GitHub link to open a pull request, so my brother Ridwan can review it and put it live.
- Before starting new work, switch back to main and pull the latest changes first.
- Ignore the setup folder; it only holds the PC setup script.
'@

    function Say($text, $color = 'Gray') { Write-Host $text -ForegroundColor $color }
    function Step($n, $text) { Write-Host ''; Say "[$n/5] $text" 'Cyan' }
    function Ok($text) { Say "      Done: $text" 'Green' }
    function Has($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }
    function Refresh-Path {
        $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path = "$machine;$user;$ClaudeBin"
    }

    try {
        Clear-Host
        Say '==============================================' 'White'
        Say '   Next Shield website - PC setup' 'White'
        Say '==============================================' 'White'
        Say 'This takes about 5 minutes. Keep this window open until it says "All set".'
        Say 'If Windows asks "Do you want to allow this app to make changes?", click Yes.'

        # ---- 1. winget ---------------------------------------------
        Step 1 'Checking this PC can install apps'
        if (-not (Has 'winget')) {
            Start-Process 'https://apps.microsoft.com/detail/9NBLGGH4NNS1'
            throw 'Windows "App Installer" is missing. A Microsoft Store page just opened: click Get (or Update), then run the setup line again.'
        }
        Ok 'ready'

        # ---- 2. Git ------------------------------------------------
        Step 2 'Installing Git (lets Claude save and upload changes)'
        Refresh-Path
        if (Has 'git') {
            Ok 'Git was already installed'
        } else {
            winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements
            Refresh-Path
            if (-not (Has 'git')) {
                throw 'Git did not install. Download it from https://git-scm.com/download/win , install it, then run the setup line again.'
            }
            Ok 'Git installed'
        }
        if (-not (git config --global user.name)) {
            $name = ''
            while (-not $name) { $name = (Read-Host '      Type your name (it is shown next to changes you make)').Trim() }
            git config --global user.name $name
        }
        if (-not (git config --global user.email)) { git config --global user.email $MyEmail }

        # ---- 3. Claude Code ----------------------------------------
        Step 3 'Installing Claude Code'
        if (Has 'claude') {
            Ok 'Claude Code was already installed'
        } else {
            # Run the official installer in a separate PowerShell process so it cannot close this window.
            powershell -NoProfile -ExecutionPolicy Bypass -Command '[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://claude.ai/install.ps1 | iex'
            Refresh-Path
            if (-not (Has 'claude')) {
                throw 'Claude Code did not install. See https://code.claude.com/docs/en/setup , then run the setup line again.'
            }
            Ok 'Claude Code installed'
        }
        # Make sure new windows can find Claude too.
        if (Test-Path (Join-Path $ClaudeBin 'claude.exe')) {
            $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
            if (-not $userPath) { $userPath = '' }
            if (($userPath -split ';') -notcontains $ClaudeBin) {
                [Environment]::SetEnvironmentVariable('Path', (($userPath.TrimEnd(';') + ';' + $ClaudeBin).TrimStart(';')), 'User')
            }
        }
        # House rules Claude reads every time it starts.
        $memDir  = Join-Path $env:USERPROFILE '.claude'
        $memFile = Join-Path $memDir 'CLAUDE.md'
        New-Item -ItemType Directory -Force -Path $memDir | Out-Null
        $existing = ''
        if (Test-Path $memFile) { $existing = [IO.File]::ReadAllText($memFile) }
        if ($existing -notmatch 'Next Shield website') {
            Add-Content -Path $memFile -Value $ClaudeNotes -Encoding ASCII
        }
        Ok 'Claude knows the house rules for the website'

        # ---- 4. Website files --------------------------------------
        Step 4 'Downloading the website files'
        if (Test-Path (Join-Path $Folder '.git')) {
            git -C $Folder pull --ff-only
            if ($LASTEXITCODE -eq 0) { Ok "updated to the latest version ($Folder)" }
            else { Say "      Already downloaded ($Folder). Could not auto-update - just ask Claude to get the latest version." 'Yellow' }
        } else {
            git clone $RepoUrl $Folder
            if ($LASTEXITCODE -ne 0) {
                throw "Could not download the website from $RepoPage . Check your internet connection and run the setup line again."
            }
            Ok "saved to $Folder"
        }

        # ---- 5. Desktop shortcuts ----------------------------------
        Step 5 'Adding shortcuts to your desktop'
        $desktop = [Environment]::GetFolderPath('Desktop')

        $launcher = Join-Path $desktop 'Next Shield - Edit with Claude.cmd'
        @(
            '@echo off'
            'title Next Shield - Claude'
            'cd /d "%USERPROFILE%\nextshieldengineering"'
            'git pull --ff-only >nul 2>nul'
            'if exist "%USERPROFILE%\.local\bin\claude.exe" ("%USERPROFILE%\.local\bin\claude.exe") else (claude)'
        ) | Set-Content -Path $launcher -Encoding ASCII

        $shell = New-Object -ComObject WScript.Shell
        $preview = $shell.CreateShortcut((Join-Path $desktop 'Next Shield - Preview website.lnk'))
        $preview.TargetPath = Join-Path $Folder 'index.html'
        $preview.Save()

        @('[InternetShortcut]', "URL=$LiveSite") |
            Set-Content -Path (Join-Path $desktop 'Next Shield - Live website.url') -Encoding ASCII
        Ok '3 shortcuts added'

        # ---- Finished ----------------------------------------------
        Write-Host ''
        Say '==============================================' 'Green'
        Say '   All set!' 'Green'
        Say '==============================================' 'Green'
        Say 'On your desktop you now have:'
        Say '  * Next Shield - Edit with Claude   -> tell Claude what to change on the website'
        Say '  * Next Shield - Preview website    -> see your changes before they go live'
        Say '  * Next Shield - Live website       -> the real website'
        Write-Host ''
        Say 'The first time Claude opens it asks you to log in: choose your Claude account (the Pro one).'
        Write-Host ''
        $answer = Read-Host 'Open Claude now? (Y/n)'
        if ($answer -notmatch '^[Nn]') { Start-Process -FilePath $launcher }
        Write-Host ''
        Say 'You can close this window now.'
    }
    catch {
        Write-Host ''
        Say "Setup stopped: $($_.Exception.Message)" 'Red'
        Say 'Running the setup line again is safe. If it keeps stopping, send a photo of this window to Ridwan.' 'Yellow'
    }
}
