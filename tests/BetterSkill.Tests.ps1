$RepoRoot = Split-Path -Parent $PSScriptRoot
$DetectScript = Join-Path $RepoRoot "scripts\detect-antigravity.ps1"
$InstallScript = Join-Path $RepoRoot "install.ps1"
$ValidatorScript = Join-Path $RepoRoot "antigravity\skills\skill-architect-generator\scripts\validate_skills.ps1"

Describe "Better-Skill Repository & Windows Installer" {
    Context "AC-01: Packaged Antigravity Assets Integrity" {
        It "validates all 24 global skills and 5 plugins (17 skills) with 0 errors" {
            $skillsDir = Join-Path $RepoRoot "antigravity\skills"
            $pluginsDir = Join-Path $RepoRoot "antigravity\plugins"
            & $ValidatorScript -PrimaryRoot $skillsDir -MirrorRoot "" -PluginsRoot $pluginsDir -BuiltinRoot "" | Out-Null
            $LASTEXITCODE | Should Be 0
        }

        It "contains all 9 rules, AGENTS.md, and terminal templates" {
            $rulesCount = (Get-ChildItem (Join-Path $RepoRoot "antigravity\rules") -Filter "*.md").Count
            $rulesCount | Should Be 9
            (Join-Path $RepoRoot "antigravity\AGENTS.md") | Should Exist
            (Join-Path $RepoRoot "terminal\oh-my-posh\custom.omp.json") | Should Exist
            (Join-Path $RepoRoot "terminal\powershell\Microsoft.PowerShell_profile.ps1") | Should Exist
            (Join-Path $RepoRoot "terminal\windows-powershell\Microsoft.PowerShell_profile.ps1") | Should Exist
            (Join-Path $RepoRoot "terminal\windows-terminal\settings.template.json") | Should Exist
        }
    }

    Context "AC-08: Secret & PII Hygiene Scan" {
        It "contains no hardcoded personal user paths, real emails, private keys, or DB/log files" {
            $forbiddenFiles = Get-ChildItem $RepoRoot -Recurse -File | Where-Object {
                $_.FullName -notmatch '\\\.git\\' -and
                $_.Extension -in @('.env', '.db', '.sqlite', '.log', '.pem', '.key')
            }
            $forbiddenFiles.Count | Should Be 0

            $textFiles = Get-ChildItem $RepoRoot -Recurse -File | Where-Object {
                $_.FullName -notmatch '\\\.git\\' -and
                $_.FullName -notmatch '\\tests\\' -and
                $_.FullName -notmatch '\\\.specify\\' -and
                $_.FullName -notmatch '\\\.antigravity\\'
            }
            $hits = $textFiles | Select-String -Pattern 'C:\\Users\\lehie|C:\\Users\\ad|0mxlinh|haimtts|(?m)^-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{20,}|sk_live_[A-Za-z0-9]{16,}|AIzaSy[A-Za-z0-9_-]{20,}' -AllMatches
            if ($hits) {
                $msg = ($hits | ForEach-Object { "$($_.Path):$($_.LineNumber)" }) -join "; "
                throw "Found forbidden pattern in: $msg"
            }
        }
    }

    Context "AC-02: Antigravity Surface Detection" {
        It "detects CLI, App, IDE, and VS Code extension accurately in isolated home" {
            (Test-Path $DetectScript) | Should Be $true
            $sandbox = Join-Path $TestDrive "detect-all"
            $fakeHome = Join-Path $sandbox "home"
            $fakeAppData = Join-Path $sandbox "appdata"
            $fakeLocalAppData = Join-Path $sandbox "localappdata"
            New-Item -ItemType Directory -Force (Join-Path $fakeHome ".gemini\antigravity-cli") | Out-Null
            New-Item -ItemType Directory -Force (Join-Path $fakeHome ".gemini\antigravity") | Out-Null
            New-Item -ItemType Directory -Force (Join-Path $fakeHome ".gemini\antigravity-ide") | Out-Null
            New-Item -ItemType Directory -Force (Join-Path $fakeHome ".vscode\extensions\google.antigravity-1.2.0") | Out-Null
            New-Item -ItemType Directory -Force (Join-Path $fakeAppData "Antigravity\User") | Out-Null
            New-Item -ItemType Directory -Force (Join-Path $fakeAppData "Code\User") | Out-Null
            New-Item -ItemType Directory -Force $fakeLocalAppData | Out-Null

            $res = & $DetectScript -TargetHome $fakeHome -AppDataDir $fakeAppData -LocalAppDataDir $fakeLocalAppData -SkipCommandProbe
            $res.CliDetected | Should Be $true
            $res.AppDetected | Should Be $true
            $res.IdeDetected | Should Be $true
            $res.VsCodeInstalled | Should Be $true
            $res.VsCodeAntigravityExtension | Should Be $true
        }

        It "returns false cleanly on a brand-new machine with zero surfaces" {
            $sandbox = Join-Path $TestDrive "detect-none"
            $fakeHome = Join-Path $sandbox "home"
            $fakeAppData = Join-Path $sandbox "appdata"
            $fakeLocalAppData = Join-Path $sandbox "localappdata"
            New-Item -ItemType Directory -Force $fakeHome | Out-Null

            $res = & $DetectScript -TargetHome $fakeHome -AppDataDir $fakeAppData -LocalAppDataDir $fakeLocalAppData -SkipCommandProbe
            $res.CliDetected | Should Be $false
            $res.AppDetected | Should Be $false
            $res.IdeDetected | Should Be $false
            $res.VsCodeAntigravityExtension | Should Be $false
        }
    }

    Context "AC-03, AC-04, AC-05, AC-07: Sandbox Install, Safe Merge, Idempotency & Workspace" {
        It "installs all skills/rules/plugins, safely merges Windows Terminal & VS Code, and preserves user data across 2 runs" {
            (Test-Path $InstallScript) | Should Be $true
            $sandbox = Join-Path $TestDrive "install-sandbox"
            $fakeHome = Join-Path $sandbox "home"
            $fakeAppData = Join-Path $sandbox "appdata"
            $fakeLocalAppData = Join-Path $sandbox "localappdata"
            $fakeWtDir = Join-Path $fakeLocalAppData "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
            $fakeWt = Join-Path $fakeWtDir "settings.json"
            $fakeVsCodeSettings = Join-Path $fakeAppData "Code\User\settings.json"
            $fakeWorkspace = Join-Path $sandbox "my-project"

            New-Item -ItemType Directory -Force $fakeWtDir | Out-Null
            New-Item -ItemType Directory -Force (Join-Path $fakeAppData "Code\User") | Out-Null
            New-Item -ItemType Directory -Force (Join-Path $fakeHome ".vscode\extensions\google.antigravity-0.1.0") | Out-Null
            New-Item -ItemType Directory -Force (Join-Path $fakeHome "Documents\PowerShell") | Out-Null
            New-Item -ItemType Directory -Force $fakeWorkspace | Out-Null

            # Seed pre-existing WT settings with Ubuntu + custom keybinding
            $existingWt = @'
{
  "defaultProfile": "{c6f74b21-f533-5be9-b155-2fbe36596bca}",
  "keybindings": [
    { "id": "User.CustomAction", "keys": "alt+f4" }
  ],
  "profiles": {
    "defaults": {},
    "list": [
      {
        "guid": "{c6f74b21-f533-5be9-b155-2fbe36596bca}",
        "name": "Ubuntu",
        "source": "Microsoft.WSL"
      }
    ]
  }
}
'@
            [System.IO.File]::WriteAllText($fakeWt, $existingWt, [System.Text.UTF8Encoding]::new($false))
            [System.IO.File]::WriteAllText($fakeVsCodeSettings, '{"editor.fontSize": 14}', [System.Text.UTF8Encoding]::new($false))

            $pwshProfile = Join-Path $fakeHome "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
            [System.IO.File]::WriteAllText($pwshProfile, "Set-Alias ll Get-ChildItem`n", [System.Text.UTF8Encoding]::new($false))

            # Run 1
            & $InstallScript -TargetHome $fakeHome -AppDataDir $fakeAppData -LocalAppDataDir $fakeLocalAppData -WtSettingsPath $fakeWt -Workspace $fakeWorkspace -SkipPackageInstall -SkipCommandProbe
            $LASTEXITCODE | Should Be 0

            # Run 2 (idempotency check)
            & $InstallScript -TargetHome $fakeHome -AppDataDir $fakeAppData -LocalAppDataDir $fakeLocalAppData -WtSettingsPath $fakeWt -Workspace $fakeWorkspace -SkipPackageInstall -SkipCommandProbe
            $LASTEXITCODE | Should Be 0

            # Verify skills, rules, plugins, workspace
            (Get-ChildItem (Join-Path $fakeHome ".gemini\config\skills") -Directory).Count | Should Be 24
            (Get-ChildItem (Join-Path $fakeHome ".gemini\skills") -Directory).Count | Should Be 24
            (Get-ChildItem (Join-Path $fakeHome ".gemini\config\rules") -Filter "*.md").Count | Should Be 9
            (Get-ChildItem (Join-Path $fakeHome ".gemini\rules") -Filter "*.md").Count | Should Be 9
            (Get-ChildItem (Join-Path $fakeHome ".gemini\config\plugins") -Directory).Count | Should Be 5
            (Join-Path $fakeHome ".gemini\AGENTS.md") | Should Exist
            (Join-Path $fakeWorkspace ".agents\skills") | Should Exist
            (Join-Path $fakeWorkspace ".agents\rules") | Should Exist
            (Join-Path $fakeWorkspace ".agents\plugins") | Should Exist
            (Join-Path $fakeWorkspace ".agents\AGENTS.md") | Should Exist

            # Validate installed skills via validator
            & $ValidatorScript -PrimaryRoot (Join-Path $fakeHome ".gemini\config\skills") -MirrorRoot (Join-Path $fakeHome ".gemini\skills") -PluginsRoot (Join-Path $fakeHome ".gemini\config\plugins") -BuiltinRoot "" | Out-Null
            $LASTEXITCODE | Should Be 0

            # Verify OMP theme & idempotent profile
            (Join-Path $fakeHome ".config\oh-my-posh\custom.omp.json") | Should Exist
            $profText = [System.IO.File]::ReadAllText($pwshProfile)
            $profText | Should Match "Set-Alias ll Get-ChildItem"
            ([regex]::Matches($profText, ">>> Better-Skill Oh My Posh >>>")).Count | Should Be 1

            # Verify WT safe merge + backup + no hardcoded username
            @(Get-ChildItem $fakeWtDir -Filter "settings.json.bak.*").Count | Should BeGreaterThan 0
            $mergedWt = Get-Content $fakeWt -Raw | ConvertFrom-Json
            $mergedWt.defaultProfile | Should Be "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
            $mergedWt.profiles.defaults.font.face | Should Be "FiraCode Nerd Font"
            @($mergedWt.profiles.list | Where-Object { $_.name -eq "Ubuntu" }).Count | Should Be 1
            $pwshProf = $mergedWt.profiles.list | Where-Object { $_.guid -eq "{574e775e-4f2a-5b96-ac1e-a2962a402336}" }
            $pwshProf.name | Should Be "/~"
            $pwshProf.font.face | Should Be "FiraCode Nerd Font Mono"
            $pwshProf.font.size | Should Be 10
            $pwshProf.font.weight | Should Be "semi-bold"
            $pwshProf.commandline | Should Not Match "C:\\Users\\lehie"
            @($mergedWt.keybindings | Where-Object { $_.keys -eq "alt+f4" }).Count | Should Be 1
            @($mergedWt.keybindings | Where-Object { $_.keys -eq "ctrl+v" }).Count | Should Be 1

            # Verify VS Code settings merge preserved existing settings + backup
            @(Get-ChildItem (Join-Path $fakeAppData "Code\User") -Filter "settings.json.bak.*").Count | Should BeGreaterThan 0
            $mergedVs = Get-Content $fakeVsCodeSettings -Raw | ConvertFrom-Json
            $mergedVs.'editor.fontSize' | Should Be 14
            $mergedVs.'terminal.integrated.fontFamily' | Should Be "FiraCode Nerd Font"
        }
    }

    Context "AC-09: Windows-Only MSIX Bundle (Pwsh 7.7.0 & WT 1.25.3131.0)" {
        It "configures exact GitHub .msixbundle URLs and Add-AppxPackage version checks in install.ps1" {
            $psContent = [System.IO.File]::ReadAllText($InstallScript, [System.Text.Encoding]::UTF8)
            $psContent | Should Match "https://github\.com/PowerShell/PowerShell/releases/download/v7\.7\.0/PowerShell-7\.7\.0\.msixbundle"
            $psContent | Should Match "https://github\.com/microsoft/terminal/releases/download/v1\.25\.3131\.0/Microsoft\.WindowsTerminal_1\.25\.3131\.0_8wekyb3d8bbwe\.msixbundle"
            $psContent | Should Match "Add-AppxPackage"
        }

        It "reports version-aware package plan cleanly in -DryRun mode" {
            $dryOut = (& $InstallScript -DryRun *>&1 | Out-String)
            $LASTEXITCODE | Should Be 0
            $dryOut | Should Match "PowerShell 7\.7\.0"
            $dryOut | Should Match "Windows Terminal 1\.25\.3131\.0"
        }
    }
}
