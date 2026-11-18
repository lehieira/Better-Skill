<#
.SYNOPSIS
    Better-Skill universal Windows installer.
.DESCRIPTION
    Detects Antigravity surfaces (CLI, Desktop App, IDE, VS Code extension),
    installs all 24 global skills, 5 plugins (17 skills), 9 rules, and AGENTS.md,
    and optionally installs & configures Windows Terminal + PowerShell 7 + Oh My Posh + FiraCode Nerd Font.
#>
param(
    [string]$TargetHome = $HOME,
    [string]$AppDataDir = $env:APPDATA,
    [string]$LocalAppDataDir = $env:LOCALAPPDATA,
    [string]$WtSettingsPath = "",
    [string]$Workspace = "",
    [string]$RepoZipUrl = "https://github.com/lehieira/Better-Skill/archive/refs/heads/main.zip",
    [switch]$SkillsOnly,
    [switch]$TerminalOnly,
    [switch]$SkipPackageInstall,
    [switch]$SkipCommandProbe,
    [switch]$SkipVerify,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[Better-Skill] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-WarnLine {
    param([string]$Message)
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

function Join-MultiPath {
    param([string[]]$Parts)
    $clean = @()
    foreach ($p in $Parts) {
        if (-not [string]::IsNullOrEmpty($p)) { $clean += $p }
    }
    return [System.IO.Path]::Combine([string[]]$clean)
}

function Ensure-Dir {
    param([string]$Path)
    if ($DryRun) { return }
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Backup-FileIfChanged {
    param(
        [string]$Path,
        [string]$NewContent = ""
    )
    if ($DryRun -or -not (Test-Path $Path)) { return }
    if ($NewContent -ne "") {
        $oldContent = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        if ($oldContent -eq $NewContent) { return }
    }
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $bakPath = "$Path.bak.$stamp"
    Copy-Item -Force -Path $Path -Destination $bakPath
    Write-Ok "Backed up $(Split-Path -Leaf $Path) -> $(Split-Path -Leaf $bakPath)"
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )
    if ($DryRun) {
        Write-Step "[DryRun] Would write $Path"
        return
    }
    Ensure-Dir (Split-Path -Parent $Path)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Copy-FileSafe {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$BackupExisting
    )
    if ($DryRun) {
        Write-Step "[DryRun] Would copy $Source -> $Destination"
        return
    }
    Ensure-Dir (Split-Path -Parent $Destination)
    if ($BackupExisting -and (Test-Path $Destination)) {
        $srcBytes = [System.IO.File]::ReadAllBytes($Source)
        $dstBytes = [System.IO.File]::ReadAllBytes($Destination)
        $same = ($srcBytes.Length -eq $dstBytes.Length)
        if ($same) {
            for ($i = 0; $i -lt $srcBytes.Length; $i++) {
                if ($srcBytes[$i] -ne $dstBytes[$i]) { $same = $false; break }
            }
        }
        if (-not $same) {
            Backup-FileIfChanged -Path $Destination
        }
    }
    Copy-Item -Force -Path $Source -Destination $Destination
}

function Copy-DirectoryTree {
    param(
        [string]$SourceDir,
        [string]$DestDir
    )
    if ($DryRun) {
        Write-Step "[DryRun] Would sync directory $SourceDir -> $DestDir"
        return
    }
    Ensure-Dir $DestDir
    Get-ChildItem -LiteralPath $SourceDir -Directory | ForEach-Object {
        Copy-DirectoryTree -SourceDir $_.FullName -DestDir (Join-Path $DestDir $_.Name)
    }
    Get-ChildItem -LiteralPath $SourceDir -File | ForEach-Object {
        Copy-Item -Force -Path $_.FullName -Destination (Join-Path $DestDir $_.Name)
    }
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Test-ToolAvailable {
    param(
        [string]$CommandName,
        [string[]]$FallbackPaths = @()
    )
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) { return $true }
    foreach ($fp in $FallbackPaths) {
        if ($fp -and (Test-Path $fp)) { return $true }
    }
    return $false
}

function Install-WingetPackageIfMissing {
    param(
        [string]$CommandName,
        [string]$WingetId,
        [string]$DisplayName,
        [string[]]$FallbackPaths = @(),
        [switch]$ForceWinget
    )
    if (-not $ForceWinget -and (Test-ToolAvailable -CommandName $CommandName -FallbackPaths $FallbackPaths)) {
        Write-Ok "$DisplayName already installed"
        return $true
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-WarnLine "winget not found; cannot auto-install $DisplayName ($WingetId)."
        return $false
    }
    Write-Step "Installing $DisplayName ($WingetId) via winget..."
    & winget install --id $WingetId -e --source winget --accept-source-agreements --accept-package-agreements --silent
    Refresh-ProcessPath
    if (Test-ToolAvailable -CommandName $CommandName -FallbackPaths $FallbackPaths) {
        Write-Ok "$DisplayName installed"
        return $true
    }
    Write-WarnLine "$DisplayName installation completed with warning or requires restarting terminal."
    return $false
}

function Get-InstalledMsixOrToolVersion {
    param(
        [string]$AppxName,
        [string]$CommandName = ""
    )
    try {
        $pkg = Get-AppxPackage -Name $AppxName -ErrorAction SilentlyContinue | Sort-Object { [version]$_.Version } -Descending | Select-Object -First 1
        if ($pkg -and $pkg.Version) {
            return ([version]$pkg.Version)
        }
    } catch {
    }
    if ($CommandName -eq "pwsh" -and -not $SkipCommandProbe) {
        $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($cmd) {
            try {
                $verStr = (& pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null | Select-Object -First 1).Trim()
                if ($verStr -match '^(\d+\.\d+\.\d+)') {
                    return ([version]($Matches[1] + ".0"))
                }
            } catch {
            }
        }
    }
    return $null
}

function Install-MsixBundleIfNeeded {
    param(
        [string]$DisplayName,
        [string]$AppxName,
        [version]$MinVersion,
        [string]$BundleUrl,
        [string]$WingetId,
        [string]$CommandName,
        [string[]]$FallbackPaths = @()
    )
    $currentVer = Get-InstalledMsixOrToolVersion -AppxName $AppxName -CommandName $CommandName
    if ($currentVer -and ($currentVer -ge $MinVersion)) {
        Write-Ok "$DisplayName $currentVer already installed (>= $MinVersion)"
        return $true
    }

    if ($DryRun) {
        $currText = if ($currentVer) { "$currentVer" } else { "not installed" }
        Write-Step "[DryRun] Would install/upgrade $DisplayName ($currText -> $MinVersion) from $BundleUrl (winget fallback: $WingetId)"
        return $true
    }

    $tmpDir = Join-Path $env:TEMP ("BetterSkill-Pkg-" + [guid]::NewGuid().ToString("N"))
    try {
        Ensure-Dir $tmpDir
        $fileName = [System.IO.Path]::GetFileName(($BundleUrl -split '\?')[0])
        $bundlePath = Join-Path $tmpDir $fileName
        Write-Step "Downloading $DisplayName ($MinVersion) from $BundleUrl..."
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            & curl.exe -fSL --retry 2 -o $bundlePath $BundleUrl
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path $bundlePath)) {
                throw "curl.exe failed with exit code $LASTEXITCODE"
            }
        } else {
            Invoke-WebRequest -Uri $BundleUrl -OutFile $bundlePath -UseBasicParsing
        }

        Write-Step "Installing $DisplayName via Add-AppxPackage..."
        Add-AppxPackage -Path $bundlePath -ErrorAction Stop
        Refresh-ProcessPath
        Write-Ok "$DisplayName installed via MSIX bundle"
        return $true
    } catch {
        Write-WarnLine "Add-AppxPackage failed for $DisplayName ($($_.Exception.Message)). Trying winget fallback ($WingetId)..."
        return (Install-WingetPackageIfMissing -CommandName $CommandName -WingetId $WingetId -DisplayName $DisplayName -FallbackPaths $FallbackPaths -ForceWinget)
    } finally {
        if (Test-Path $tmpDir) {
            Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
        }
    }
}

function Install-FiraCodeNerdFont {
    $userFontDir = Join-MultiPath @($LocalAppDataDir, "Microsoft", "Windows", "Fonts")
    $sysFontDir = Join-MultiPath @($env:SystemRoot, "Fonts")
    $existingUser = if (Test-Path $userFontDir) { @(Get-ChildItem -LiteralPath $userFontDir -Filter "*FiraCode*Nerd*" -ErrorAction SilentlyContinue) } else { @() }
    $existingSys = if (Test-Path $sysFontDir) { @(Get-ChildItem -LiteralPath $sysFontDir -Filter "*FiraCode*Nerd*" -ErrorAction SilentlyContinue) } else { @() }
    if (($existingUser.Count -gt 0) -or ($existingSys.Count -gt 0)) {
        Write-Ok "FiraCode Nerd Font already installed"
        return
    }

    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Step "Installing FiraCode Nerd Font via oh-my-posh..."
        try {
            & oh-my-posh font install FiraCode | Out-Null
            Write-Ok "FiraCode Nerd Font installed via oh-my-posh"
            return
        } catch {
            Write-WarnLine "oh-my-posh font install fallback triggered: $($_.Exception.Message)"
        }
    }

    Write-Step "Downloading FiraCode Nerd Font into user Fonts folder..."
    $fontTmp = Join-Path $env:TEMP ("FiraCode-" + [guid]::NewGuid().ToString("N"))
    try {
        Ensure-Dir $fontTmp
        Ensure-Dir $userFontDir
        $zipPath = Join-Path $fontTmp "FiraCode.zip"
        Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $fontTmp -Force
        $regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
        Ensure-Dir $regPath
        Get-ChildItem -LiteralPath $fontTmp -Filter "*.ttf" -Recurse | ForEach-Object {
            $dst = Join-Path $userFontDir $_.Name
            Copy-Item -Force -Path $_.FullName -Destination $dst
            New-ItemProperty -Path $regPath -Name "$($_.BaseName) (TrueType)" -Value $dst -PropertyType String -Force | Out-Null
        }
        Write-Ok "FiraCode Nerd Font installed to $userFontDir"
    } catch {
        Write-WarnLine "Could not auto-install FiraCode Nerd Font: $($_.Exception.Message)"
    } finally {
        if (Test-Path $fontTmp) { Remove-Item -Recurse -Force $fontTmp -ErrorAction SilentlyContinue }
    }
}

function Merge-ProfileFile {
    param(
        [string]$ProfilePath,
        [string]$TemplatePath
    )
    $block = ([System.IO.File]::ReadAllText($TemplatePath, [System.Text.Encoding]::UTF8)).TrimEnd()
    $startMarker = "# >>> Better-Skill Oh My Posh >>>"
    $endMarker = "# <<< Better-Skill Oh My Posh <<<"

    if (-not (Test-Path $ProfilePath)) {
        Write-Utf8NoBom -Path $ProfilePath -Content ($block + "`r`n")
        Write-Ok "Created PowerShell profile: $ProfilePath"
        return
    }

    $current = [System.IO.File]::ReadAllText($ProfilePath, [System.Text.Encoding]::UTF8)
    $pattern = "(?ms)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
    if ($current -match $pattern) {
        $updated = [regex]::Replace($current, $pattern, $block)
    } elseif ($current -match "custom\.omp\.json") {
        # Wrap existing matching setup or replace cleanly without duplicating
        $updated = $current.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
    } else {
        $updated = $current.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
    }

    if ($updated -ne $current) {
        Backup-FileIfChanged -Path $ProfilePath -NewContent $updated
        Write-Utf8NoBom -Path $ProfilePath -Content $updated
        Write-Ok "Merged Oh My Posh block into: $ProfilePath"
    } else {
        Write-Ok "PowerShell profile already up to date: $ProfilePath"
    }
}

function Resolve-PwshCommandLine {
    if (-not $SkipCommandProbe) {
        $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source) {
            return ('"' + $cmd.Source + '" -NoLogo')
        }
    }
    $storePwsh = Join-MultiPath @($LocalAppDataDir, "Microsoft", "WindowsApps", "Microsoft.PowerShell_8wekyb3d8bbwe", "pwsh.exe")
    if (Test-Path $storePwsh) {
        return ('"' + $storePwsh + '" -NoLogo')
    }
    $programPwsh = Join-MultiPath @($env:ProgramFiles, "PowerShell", "7", "pwsh.exe")
    if ($programPwsh -and (Test-Path $programPwsh)) {
        return ('"' + $programPwsh + '" -NoLogo')
    }
    return "pwsh.exe -NoLogo"
}

function Resolve-WtSettingsTarget {
    if (-not [string]::IsNullOrWhiteSpace($WtSettingsPath)) {
        return $WtSettingsPath
    }
    $candidates = @(
        (Join-MultiPath @($LocalAppDataDir, "Packages", "Microsoft.WindowsTerminal_8wekyb3d8bbwe", "LocalState", "settings.json")),
        (Join-MultiPath @($LocalAppDataDir, "Packages", "Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe", "LocalState", "settings.json")),
        (Join-MultiPath @($LocalAppDataDir, "Microsoft", "Windows Terminal", "settings.json"))
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $candidates[0]
}

function Ensure-JsonProperty {
    param(
        [PSCustomObject]$Obj,
        [string]$Name,
        $Value
    )
    if ($null -eq $Obj.PSObject.Properties[$Name]) {
        $Obj | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    } else {
        $Obj.$Name = $Value
    }
}

function Merge-WindowsTerminalSettings {
    param([string]$TemplatePath)
    $targetWt = Resolve-WtSettingsTarget
    $pwshGuid = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
    $pwshCmd  = Resolve-PwshCommandLine

    $templateObj = ([System.IO.File]::ReadAllText($TemplatePath, [System.Text.Encoding]::UTF8)) | ConvertFrom-Json
    $templatePwsh = $null
    foreach ($p in $templateObj.profiles.list) {
        if ($p.guid -eq $pwshGuid) { $templatePwsh = $p; break }
    }
    $templatePwsh.commandline = $pwshCmd

    if (-not (Test-Path $targetWt)) {
        $jsonOut = $templateObj | ConvertTo-Json -Depth 12
        Write-Utf8NoBom -Path $targetWt -Content ($jsonOut + "`r`n")
        Write-Ok "Created Windows Terminal settings: $targetWt"
        return
    }

    $raw = [System.IO.File]::ReadAllText($targetWt, [System.Text.Encoding]::UTF8)
    try {
        $wt = $raw | ConvertFrom-Json
    } catch {
        Write-WarnLine "Existing Windows Terminal settings.json could not be parsed cleanly; writing backup & applying clean template."
        Backup-FileIfChanged -Path $targetWt
        $jsonOut = $templateObj | ConvertTo-Json -Depth 12
        Write-Utf8NoBom -Path $targetWt -Content ($jsonOut + "`r`n")
        return
    }

    Ensure-JsonProperty -Obj $wt -Name "defaultProfile" -Value $pwshGuid
    Ensure-JsonProperty -Obj $wt -Name "copyFormatting" -Value "none"
    if ($null -eq $wt.PSObject.Properties["profiles"]) {
        $wt | Add-Member -NotePropertyName "profiles" -NotePropertyValue ([PSCustomObject]@{ defaults = [PSCustomObject]@{}; list = @() })
    }
    if ($null -eq $wt.profiles.PSObject.Properties["defaults"]) {
        $wt.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue ([PSCustomObject]@{})
    }
    if ($null -eq $wt.profiles.defaults.PSObject.Properties["font"]) {
        $wt.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue ([PSCustomObject]@{ face = "FiraCode Nerd Font" })
    } else {
        Ensure-JsonProperty -Obj $wt.profiles.defaults.font -Name "face" -Value "FiraCode Nerd Font"
    }

    $list = @()
    if ($wt.profiles.list) { $list = @($wt.profiles.list) }
    $foundPwsh = $false
    for ($i = 0; $i -lt $list.Count; $i++) {
        $item = $list[$i]
        if (($item.guid -eq $pwshGuid) -or ($item.source -eq "Windows.Terminal.PowershellCore")) {
            Ensure-JsonProperty -Obj $item -Name "guid" -Value $pwshGuid
            Ensure-JsonProperty -Obj $item -Name "name" -Value "/~"
            Ensure-JsonProperty -Obj $item -Name "icon" -Value $templatePwsh.icon
            Ensure-JsonProperty -Obj $item -Name "commandline" -Value $pwshCmd
            Ensure-JsonProperty -Obj $item -Name "hidden" -Value $false
            Ensure-JsonProperty -Obj $item -Name "source" -Value "Windows.Terminal.PowershellCore"
            Ensure-JsonProperty -Obj $item -Name "font" -Value ([PSCustomObject]@{
                face   = "FiraCode Nerd Font Mono"
                size   = 10
                weight = "semi-bold"
            })
            $foundPwsh = $true
            break
        }
    }
    if (-not $foundPwsh) {
        $list += $templatePwsh
    }
    $wt.profiles.list = $list

    # Merge keybindings without deleting user's custom keybindings
    $kbList = @()
    if ($wt.PSObject.Properties["keybindings"] -and $wt.keybindings) {
        $kbList = @($wt.keybindings)
    }
    foreach ($tkb in $templateObj.keybindings) {
        $exists = $false
        foreach ($ekb in $kbList) {
            if (($ekb.keys -eq $tkb.keys) -or ($ekb.id -eq $tkb.id)) {
                $exists = $true
                break
            }
        }
        if (-not $exists) { $kbList += $tkb }
    }
    Ensure-JsonProperty -Obj $wt -Name "keybindings" -Value $kbList

    $mergedJson = ($wt | ConvertTo-Json -Depth 12) + "`r`n"
    Backup-FileIfChanged -Path $targetWt -NewContent $mergedJson
    Write-Utf8NoBom -Path $targetWt -Content $mergedJson
    Write-Ok "Merged Windows Terminal profile '/~' & FiraCode Nerd Font -> $targetWt"
}

function Merge-IdeUserSettings {
    param([string]$SettingsPath)
    if (-not $SettingsPath) { return }
    $parent = Split-Path -Parent $SettingsPath
    if (-not (Test-Path $parent)) { return }

    $obj = [PSCustomObject]@{}
    if (Test-Path $SettingsPath) {
        $raw = [System.IO.File]::ReadAllText($SettingsPath, [System.Text.Encoding]::UTF8)
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            try {
                # Strip single-line // comments outside strings best-effort if simple JSONC
                $clean = [regex]::Replace($raw, '(?m)^\s*//.*$', '')
                $obj = $clean | ConvertFrom-Json
            } catch {
                Write-WarnLine "Skipped IDE settings merge (non-standard JSONC): $SettingsPath"
                return
            }
        }
    }

    Ensure-JsonProperty -Obj $obj -Name "terminal.integrated.fontFamily" -Value "FiraCode Nerd Font"
    if (Test-ToolAvailable -CommandName "pwsh" -FallbackPaths @(
        (Join-MultiPath @($LocalAppDataDir, "Microsoft", "WindowsApps", "Microsoft.PowerShell_8wekyb3d8bbwe", "pwsh.exe")),
        (Join-MultiPath @($env:ProgramFiles, "PowerShell", "7", "pwsh.exe"))
    )) {
        Ensure-JsonProperty -Obj $obj -Name "terminal.integrated.defaultProfile.windows" -Value "PowerShell"
    }

    $jsonOut = ($obj | ConvertTo-Json -Depth 12) + "`r`n"
    Backup-FileIfChanged -Path $SettingsPath -NewContent $jsonOut
    Write-Utf8NoBom -Path $SettingsPath -Content $jsonOut
    Write-Ok "Merged IDE terminal settings -> $SettingsPath"
}

function Install-AntigravityAssets {
    param(
        [string]$SourceRoot,
        $Detected
    )
    $agSource = Join-Path $SourceRoot "antigravity"
    $geminiRoot = Join-Path $TargetHome ".gemini"
    $configRoot = Join-Path $geminiRoot "config"

    Write-Step "Installing Antigravity Rules, Skills & Plugins into $geminiRoot..."
    Copy-FileSafe -Source (Join-Path $agSource "AGENTS.md") -Destination (Join-Path $geminiRoot "AGENTS.md") -BackupExisting
    Copy-FileSafe -Source (Join-Path $agSource "README.md") -Destination (Join-Path $geminiRoot "README.md")

    # Rules -> ~/.gemini/config/rules AND ~/.gemini/rules
    Copy-DirectoryTree -SourceDir (Join-Path $agSource "rules") -DestDir (Join-Path $configRoot "rules")
    Copy-DirectoryTree -SourceDir (Join-Path $agSource "rules") -DestDir (Join-Path $geminiRoot "rules")

    # Skills -> ~/.gemini/config/skills/<name>/SKILL.md AND mirror ~/.gemini/skills/<name>/skill.md
    $srcSkills = Join-Path $agSource "skills"
    $dstConfigSkills = Join-Path $configRoot "skills"
    $dstCliSkills = Join-Path $geminiRoot "skills"
    Ensure-Dir $dstConfigSkills
    Ensure-Dir $dstCliSkills

    Get-ChildItem -LiteralPath $srcSkills -Directory | ForEach-Object {
        $skillName = $_.Name
        $cfgTarget = Join-Path $dstConfigSkills $skillName
        $cliTarget = Join-Path $dstCliSkills $skillName
        Copy-DirectoryTree -SourceDir $_.FullName -DestDir $cfgTarget
        Copy-DirectoryTree -SourceDir $_.FullName -DestDir $cliTarget
        if (-not $DryRun) {
            $upperCli = Join-Path $cliTarget "SKILL.md"
            $lowerCli = Join-Path $cliTarget "skill.md"
            if (Test-Path $upperCli) {
                Move-Item -Force -Path $upperCli -Destination $lowerCli
            }
        }
    }

    # Plugins -> ~/.gemini/config/plugins/<pack>/
    Copy-DirectoryTree -SourceDir (Join-Path $agSource "plugins") -DestDir (Join-Path $configRoot "plugins")

    if ($Workspace -and -not [string]::IsNullOrWhiteSpace($Workspace)) {
        Write-Step "Installing workspace-scoped .agents/ into $Workspace..."
        $wsAgents = Join-Path $Workspace ".agents"
        Copy-FileSafe -Source (Join-Path $agSource "AGENTS.md") -Destination (Join-Path $wsAgents "AGENTS.md")
        Copy-DirectoryTree -SourceDir (Join-Path $agSource "rules") -DestDir (Join-Path $wsAgents "rules")
        Copy-DirectoryTree -SourceDir (Join-Path $agSource "skills") -DestDir (Join-Path $wsAgents "skills")
        Copy-DirectoryTree -SourceDir (Join-Path $agSource "plugins") -DestDir (Join-Path $wsAgents "plugins")
        Write-Ok "Workspace .agents/ synced at $wsAgents"
    }

    Write-Ok "Installed 24 Global Core Skills, 5 Plugins (17 skills), 9 Rules & AGENTS.md"
}

# ---------------- Main Execution ----------------
$tempBootstrapDir = ""
try {
    $sourceRoot = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($sourceRoot) -or -not (Test-Path (Join-Path $sourceRoot "antigravity"))) {
        Write-Step "Bootstrapping Better-Skill bundle from GitHub..."
        $tempBootstrapDir = Join-Path $env:TEMP ("BetterSkill-" + [guid]::NewGuid().ToString("N"))
        Ensure-Dir $tempBootstrapDir
        $zipFile = Join-Path $tempBootstrapDir "bundle.zip"
        Invoke-WebRequest -Uri $RepoZipUrl -OutFile $zipFile -UseBasicParsing
        Expand-Archive -Path $zipFile -DestinationPath $tempBootstrapDir -Force
        $extracted = Get-ChildItem -LiteralPath $tempBootstrapDir -Directory | Select-Object -First 1
        if (-not $extracted) { throw "Failed to extract Better-Skill repository archive." }
        $sourceRoot = $extracted.FullName
    }

    $detectScript = Join-MultiPath @($sourceRoot, "scripts", "detect-antigravity.ps1")
    $detected = & $detectScript -TargetHome $TargetHome -AppDataDir $AppDataDir -LocalAppDataDir $LocalAppDataDir -SkipCommandProbe:$SkipCommandProbe

    Write-Step "Detected Antigravity surfaces on Windows:"
    Write-Host ("  - Antigravity CLI               : {0}" -f $detected.CliDetected)
    Write-Host ("  - Antigravity Desktop App (2.0) : {0}" -f $detected.AppDetected)
    Write-Host ("  - Antigravity IDE               : {0}" -f $detected.IdeDetected)
    Write-Host ("  - VS Code + Antigravity Ext     : {0} (VS Code installed: {1})" -f $detected.VsCodeAntigravityExtension, $detected.VsCodeInstalled)
    if (-not $detected.HasAnySurface) {
        Write-WarnLine "No existing Antigravity surface detected; pre-configuring global ~/.gemini/ for first launch."
    }

    if (-not $TerminalOnly) {
        Install-AntigravityAssets -SourceRoot $sourceRoot -Detected $detected
    }

    if (-not $SkillsOnly) {
        if (-not $SkipPackageInstall) {
            $wtBundleUrl = "https://github.com/microsoft/terminal/releases/download/v1.25.3131.0/Microsoft.WindowsTerminal_1.25.3131.0_8wekyb3d8bbwe.msixbundle"
            $pwshBundleUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.7.0/PowerShell-7.7.0.msixbundle"

            if (-not $DryRun) {
                Install-WingetPackageIfMissing -CommandName "git" -WingetId "Git.Git" -DisplayName "Git" | Out-Null
            }
            Install-MsixBundleIfNeeded `
                -DisplayName "Windows Terminal 1.25.3131.0" `
                -AppxName "Microsoft.WindowsTerminal" `
                -MinVersion ([version]"1.25.3131.0") `
                -BundleUrl $wtBundleUrl `
                -WingetId "Microsoft.WindowsTerminal" `
                -CommandName "wt" `
                -FallbackPaths @((Join-MultiPath @($LocalAppDataDir, "Microsoft", "WindowsApps", "wt.exe"))) | Out-Null

            Install-MsixBundleIfNeeded `
                -DisplayName "PowerShell 7.7.0" `
                -AppxName "Microsoft.PowerShell" `
                -MinVersion ([version]"7.7.0.0") `
                -BundleUrl $pwshBundleUrl `
                -WingetId "Microsoft.PowerShell" `
                -CommandName "pwsh" `
                -FallbackPaths @(
                    (Join-MultiPath @($LocalAppDataDir, "Microsoft", "WindowsApps", "Microsoft.PowerShell_8wekyb3d8bbwe", "pwsh.exe")),
                    (Join-MultiPath @($env:ProgramFiles, "PowerShell", "7", "pwsh.exe"))
                ) | Out-Null

            if (-not $DryRun) {
                $ompOk = Install-WingetPackageIfMissing -CommandName "oh-my-posh" -WingetId "JanDeDobbeleer.OhMyPosh" -DisplayName "Oh My Posh" -FallbackPaths @(
                    (Join-MultiPath @($LocalAppDataDir, "Programs", "oh-my-posh", "bin", "oh-my-posh.exe"))
                )
                if (-not $ompOk) {
                    try {
                        Write-Step "Trying official Oh My Posh installer fallback..."
                        Invoke-RestMethod https://ohmyposh.dev/install.ps1 | Invoke-Expression
                        Refresh-ProcessPath
                    } catch {
                        Write-WarnLine "Oh My Posh fallback failed: $($_.Exception.Message)"
                    }
                }
                Install-FiraCodeNerdFont
            }
        }

        $termSrc = Join-Path $sourceRoot "terminal"
        $ompDst = Join-MultiPath @($TargetHome, ".config", "oh-my-posh", "custom.omp.json")
        Copy-FileSafe -Source (Join-MultiPath @($termSrc, "oh-my-posh", "custom.omp.json")) -Destination $ompDst -BackupExisting
        Write-Ok "Installed Oh My Posh theme -> $ompDst"

        $pwshProfDst = Join-MultiPath @($TargetHome, "Documents", "PowerShell", "Microsoft.PowerShell_profile.ps1")
        $winPsProfDst = Join-MultiPath @($TargetHome, "Documents", "WindowsPowerShell", "Microsoft.PowerShell_profile.ps1")
        Merge-ProfileFile -ProfilePath $pwshProfDst -TemplatePath (Join-MultiPath @($termSrc, "powershell", "Microsoft.PowerShell_profile.ps1"))
        Merge-ProfileFile -ProfilePath $winPsProfDst -TemplatePath (Join-MultiPath @($termSrc, "windows-powershell", "Microsoft.PowerShell_profile.ps1"))

        Merge-WindowsTerminalSettings -TemplatePath (Join-MultiPath @($termSrc, "windows-terminal", "settings.template.json"))
        Merge-IdeUserSettings -SettingsPath $detected.VsCodeSettingsPath
        Merge-IdeUserSettings -SettingsPath $detected.AntigravitySettingsPath
    }

    if (-not $TerminalOnly -and -not $SkipVerify -and -not $DryRun) {
        $validator = Join-MultiPath @($TargetHome, ".gemini", "config", "skills", "skill-architect-generator", "scripts", "validate_skills.ps1")
        if (Test-Path $validator) {
            Write-Step "Running post-install skill & plugin validation..."
            & $validator -PrimaryRoot (Join-MultiPath @($TargetHome, ".gemini", "config", "skills")) -MirrorRoot (Join-MultiPath @($TargetHome, ".gemini", "skills")) -PluginsRoot (Join-MultiPath @($TargetHome, ".gemini", "config", "plugins")) -BuiltinRoot ""
            if ($LASTEXITCODE -ne 0) {
                throw "Post-install skill validation failed with exit code $LASTEXITCODE"
            }
        }
    }

    Write-Step "Done! Restart your terminal / Antigravity / VS Code to activate everything."
} finally {
    if ($tempBootstrapDir -and (Test-Path $tempBootstrapDir)) {
        Remove-Item -Recurse -Force $tempBootstrapDir -ErrorAction SilentlyContinue
    }
}
