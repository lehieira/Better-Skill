param(
    [string]$TargetHome = $HOME,
    [string]$AppDataDir = $env:APPDATA,
    [string]$LocalAppDataDir = $env:LOCALAPPDATA,
    [switch]$SkipCommandProbe,
    [switch]$AsJson
)

function Join-MultiPath {
    param([string[]]$Parts)
    $clean = @()
    foreach ($p in $Parts) {
        if (-not [string]::IsNullOrEmpty($p)) { $clean += $p }
    }
    if ($clean.Count -eq 0) { return "" }
    return [System.IO.Path]::Combine([string[]]$clean)
}

function Test-CommandExists {
    param([string]$Name)
    if ($SkipCommandProbe) { return $false }
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

$cliEvidence = New-Object System.Collections.Generic.List[string]
$appEvidence = New-Object System.Collections.Generic.List[string]
$ideEvidence = New-Object System.Collections.Generic.List[string]
$vsEvidence  = New-Object System.Collections.Generic.List[string]
$matchedExts = New-Object System.Collections.Generic.List[string]

# 1. Antigravity CLI
if (Test-CommandExists "agy") { $cliEvidence.Add("cmd:agy") }
$cliBin = Join-MultiPath @($LocalAppDataDir, "agy", "bin", "agy.exe")
if ($cliBin -and (Test-Path $cliBin)) { $cliEvidence.Add($cliBin) }
$cliDir = Join-MultiPath @($TargetHome, ".gemini", "antigravity-cli")
if ($cliDir -and (Test-Path $cliDir)) { $cliEvidence.Add($cliDir) }

# 2. Antigravity Desktop App (2.0)
$appGemDir = Join-MultiPath @($TargetHome, ".gemini", "antigravity")
if ($appGemDir -and (Test-Path $appGemDir)) { $appEvidence.Add($appGemDir) }
$appRoaming = Join-MultiPath @($AppDataDir, "Antigravity")
if ($appRoaming -and (Test-Path $appRoaming)) { $appEvidence.Add($appRoaming) }
$appProg = Join-MultiPath @($LocalAppDataDir, "Programs", "Antigravity")
if ($appProg -and (Test-Path $appProg)) { $appEvidence.Add($appProg) }
if (Test-CommandExists "antigravity") { $appEvidence.Add("cmd:antigravity") }

# 3. Antigravity IDE
$ideGemDir = Join-MultiPath @($TargetHome, ".gemini", "antigravity-ide")
if ($ideGemDir -and (Test-Path $ideGemDir)) { $ideEvidence.Add($ideGemDir) }
$ideProg = Join-MultiPath @($LocalAppDataDir, "Programs", "Antigravity IDE")
if ($ideProg -and (Test-Path $ideProg)) { $ideEvidence.Add($ideProg) }
if (Test-CommandExists "antigravity-ide") { $ideEvidence.Add("cmd:antigravity-ide") }

# 4. VS Code & Antigravity / Gemini Extensions
$vsCodeInstalled = $false
if (Test-CommandExists "code") {
    $vsCodeInstalled = $true
    $vsEvidence.Add("cmd:code")
}
$vsProg = Join-MultiPath @($LocalAppDataDir, "Programs", "Microsoft VS Code")
if ($vsProg -and (Test-Path $vsProg)) {
    $vsCodeInstalled = $true
    $vsEvidence.Add($vsProg)
}
$vsAppData = Join-MultiPath @($AppDataDir, "Code")
if ($vsAppData -and (Test-Path $vsAppData)) {
    $vsCodeInstalled = $true
    $vsEvidence.Add($vsAppData)
}

$extRoots = @(
    (Join-MultiPath @($TargetHome, ".vscode", "extensions")),
    (Join-MultiPath @($TargetHome, ".vscode-insiders", "extensions")),
    (Join-MultiPath @($TargetHome, ".vscode-oss", "extensions"))
)
foreach ($er in $extRoots) {
    if ($er -and (Test-Path $er)) {
        $vsCodeInstalled = $true
        Get-ChildItem -LiteralPath $er -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -match '(?i)(antigravity|google\.gemini|gemini-code-assist|codeium)') {
                $matchedExts.Add($_.Name)
                $vsEvidence.Add($_.FullName)
            }
        }
    }
}

if (-not $SkipCommandProbe -and (Test-CommandExists "code")) {
    try {
        $cliExts = & code --list-extensions 2>$null
        foreach ($extId in $cliExts) {
            if ($extId -match '(?i)(antigravity|google\.gemini|gemini-code-assist|codeium)') {
                if (-not $matchedExts.Contains($extId)) {
                    $matchedExts.Add($extId)
                    $vsEvidence.Add("code-ext:$extId")
                }
            }
        }
    } catch {
    }
}

$vsSettingsPath = Join-MultiPath @($AppDataDir, "Code", "User", "settings.json")
$agUserSettingsPath = Join-MultiPath @($AppDataDir, "Antigravity", "User", "settings.json")

$result = [PSCustomObject]@{
    Platform                   = "Windows"
    TargetHome                 = $TargetHome
    CliDetected                = ($cliEvidence.Count -gt 0)
    CliEvidence                = @($cliEvidence)
    AppDetected                = ($appEvidence.Count -gt 0)
    AppEvidence                = @($appEvidence)
    IdeDetected                = ($ideEvidence.Count -gt 0)
    IdeEvidence                = @($ideEvidence)
    VsCodeInstalled            = $vsCodeInstalled
    VsCodeAntigravityExtension = ($matchedExts.Count -gt 0)
    MatchedExtensions          = @($matchedExts)
    VsCodeEvidence             = @($vsEvidence)
    VsCodeSettingsPath         = $vsSettingsPath
    AntigravitySettingsPath    = $agUserSettingsPath
    HasAnySurface              = (($cliEvidence.Count -gt 0) -or ($appEvidence.Count -gt 0) -or ($ideEvidence.Count -gt 0) -or ($matchedExts.Count -gt 0))
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 4
} else {
    $result
}
