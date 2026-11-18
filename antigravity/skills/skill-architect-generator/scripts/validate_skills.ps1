<#
.SYNOPSIS
    Validates Antigravity custom global skills and plugin-bundled skills.
.DESCRIPTION
    Checks all skill subdirectories under PrimaryRoot (default: ~/.gemini/config/skills),
    verifies SHA-256 parity against MirrorRoot (default: ~/.gemini/skills),
    validates plugins under PluginsRoot (default: ~/.gemini/config/plugins),
    and enforces zero name collisions with BuiltinRoot.
#>
param(
    [string]$PrimaryRoot = (Join-Path $HOME ".gemini\config\skills"),
    [string]$MirrorRoot = (Join-Path $HOME ".gemini\skills"),
    [string]$PluginsRoot = (Join-Path $HOME ".gemini\config\plugins"),
    [string]$BuiltinRoot = (Join-Path $HOME ".gemini\antigravity-cli\builtin\skills"),
    [int]$MaxRecommendedLines = 200
)

$ErrorActionPreference = "Stop"
$sha = [System.Security.Cryptography.SHA256]::Create()
$allowedPluginFields = @(
    "name", "description", "logo", "suggestedPrompts",
    "displayName", "version", "author", "homepage", "repository", "disabled"
)

function Get-FileSha256 {
    param([string]$FilePath)
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Parse-SkillFrontmatter {
    param([string]$FilePath)
    $raw = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    if ($raw.Contains([char]0xFFFD)) {
        return @{ Valid = $false; Error = "Contains invalid UTF-8 replacement char (U+FFFD)" }
    }
    $lines = $raw -split "\r?\n"
    if ($lines.Count -lt 4 -or $lines[0].Trim() -ne "---") {
        return @{ Valid = $false; Error = "Missing opening YAML frontmatter '---' at line 1" }
    }
    $endIdx = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") {
            $endIdx = $i
            break
        }
    }
    if ($endIdx -lt 0) {
        return @{ Valid = $false; Error = "Missing closing YAML frontmatter '---'" }
    }

    $fmLines = $lines[1..($endIdx - 1)]
    $fmText = $fmLines -join "`n"
    $nameMatch = [regex]::Match($fmText, '(?m)^name:\s*(.+?)\s*$')
    $descMatch = [regex]::Match($fmText, '(?ms)^description:\s*(.+?)(?=^\w+:|\z)')

    $nameVal = if ($nameMatch.Success) { $nameMatch.Groups[1].Value.Trim().Trim('"').Trim("'") } else { "" }
    $descVal = if ($descMatch.Success) { $descMatch.Groups[1].Value.Trim() } else { "" }

    if ([string]::IsNullOrWhiteSpace($nameVal)) {
        return @{ Valid = $false; Error = "Missing or empty 'name' in frontmatter" }
    }
    if ([string]::IsNullOrWhiteSpace($descVal) -or $descVal -eq ">-" -or $descVal -eq "|") {
        return @{ Valid = $false; Error = "Missing or empty 'description' in frontmatter" }
    }

    return @{
        Valid     = $true
        Name      = $nameVal
        DescLen   = $descVal.Length
        LineCount = $lines.Count
    }
}

if (-not (Test-Path $PrimaryRoot)) {
    Write-Error "PrimaryRoot not found: $PrimaryRoot"
    exit 1
}

# Collect built-in skill names to prevent collisions
$builtinNames = @{}
if ($BuiltinRoot -and (Test-Path $BuiltinRoot)) {
    Get-ChildItem -LiteralPath $BuiltinRoot -Directory | ForEach-Object {
        $bf = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $bf) {
            $parsed = Parse-SkillFrontmatter $bf
            if ($parsed.Valid) {
                $builtinNames[$parsed.Name] = $_.FullName
            }
        }
    }
}

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$seenSkills = @{}

function Validate-SkillFolder {
    param(
        [System.IO.DirectoryInfo]$Dir,
        [string]$ScopeLabel,
        [string]$CheckMirrorRoot = ""
    )
    $skillFile = Join-Path $Dir.FullName "SKILL.md"
    if (-not (Test-Path $skillFile)) {
        $errors.Add("[$ScopeLabel/$($Dir.Name)] Missing SKILL.md at $skillFile")
        return
    }

    $parsed = Parse-SkillFrontmatter $skillFile
    if (-not $parsed.Valid) {
        $errors.Add("[$ScopeLabel/$($Dir.Name)] $($parsed.Error)")
        return
    }

    if ($parsed.Name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        $errors.Add("[$ScopeLabel/$($Dir.Name)] Skill name '$($parsed.Name)' must be lowercase kebab-case")
    }
    if ($parsed.Name -ne $Dir.Name) {
        $errors.Add("[$ScopeLabel/$($Dir.Name)] Frontmatter name '$($parsed.Name)' does not match folder name '$($Dir.Name)'")
    }
    if ($seenSkills.ContainsKey($parsed.Name)) {
        $errors.Add("[$ScopeLabel/$($Dir.Name)] Duplicate skill name '$($parsed.Name)' (already in $($seenSkills[$parsed.Name]))")
    } else {
        $seenSkills[$parsed.Name] = $Dir.FullName
    }
    if ($builtinNames.ContainsKey($parsed.Name)) {
        $errors.Add("[$ScopeLabel/$($Dir.Name)] Collides with built-in skill '$($parsed.Name)'")
    }
    if ($parsed.LineCount -gt $MaxRecommendedLines) {
        $warnings.Add("[$ScopeLabel/$($Dir.Name)] SKILL.md has $($parsed.LineCount) lines (> $MaxRecommendedLines). Consider moving details to references/.")
    }

    if ($CheckMirrorRoot -and (Test-Path $CheckMirrorRoot)) {
        $mirrorDir = Join-Path $CheckMirrorRoot $Dir.Name
        $mirrorSkill = Join-Path $mirrorDir "skill.md"
        if (-not (Test-Path $mirrorSkill)) {
            $mirrorSkillUpper = Join-Path $mirrorDir "SKILL.md"
            if (Test-Path $mirrorSkillUpper) {
                $mirrorSkill = $mirrorSkillUpper
            } else {
                $errors.Add("[$ScopeLabel/$($Dir.Name)] Missing mirror skill file in $mirrorDir")
                return
            }
        }
        if ((Get-FileSha256 $skillFile) -ne (Get-FileSha256 $mirrorSkill)) {
            $errors.Add("[$ScopeLabel/$($Dir.Name)] Hash mismatch between $skillFile and $mirrorSkill")
        }
        $srcScripts = Join-Path $Dir.FullName "scripts"
        if (Test-Path $srcScripts) {
            $dstScripts = Join-Path $mirrorDir "scripts"
            Get-ChildItem -LiteralPath $srcScripts -File | ForEach-Object {
                $dstFile = Join-Path $dstScripts $_.Name
                if (-not (Test-Path $dstFile)) {
                    $errors.Add("[$ScopeLabel/$($Dir.Name)] Missing mirrored script $dstFile")
                } elseif ((Get-FileSha256 $_.FullName) -ne (Get-FileSha256 $dstFile)) {
                    $errors.Add("[$ScopeLabel/$($Dir.Name)] Script hash mismatch for $($_.Name)")
                }
            }
        }
    }

    Write-Output ("OK   [{0,-19}] {1,-30} lines={2,-4} descLen={3}" -f $ScopeLabel, $parsed.Name, $parsed.LineCount, $parsed.DescLen)
}

# 1. Validate Global Skills
$globalDirs = Get-ChildItem -LiteralPath $PrimaryRoot -Directory | Sort-Object Name
foreach ($dir in $globalDirs) {
    Validate-SkillFolder -Dir $dir -ScopeLabel "global" -CheckMirrorRoot $MirrorRoot
}

# 2. Validate Plugin Manifests and Bundled Skills
$seenPluginNames = @{}
$pluginSkillCount = 0
if ($PluginsRoot -and (Test-Path $PluginsRoot)) {
    $pluginDirs = Get-ChildItem -LiteralPath $PluginsRoot -Directory | Sort-Object Name
    foreach ($pDir in $pluginDirs) {
        $manifestPath = Join-Path $pDir.FullName "plugin.json"
        if (-not (Test-Path $manifestPath)) {
            $errors.Add("[plugin/$($pDir.Name)] Missing plugin.json")
            continue
        }
        try {
            $manifestRaw = [System.IO.File]::ReadAllText($manifestPath, [System.Text.Encoding]::UTF8)
            $manifest = $manifestRaw | ConvertFrom-Json
        } catch {
            $errors.Add("[plugin/$($pDir.Name)] Invalid JSON in plugin.json: $($_.Exception.Message)")
            continue
        }
        $pName = if ($manifest.name) { [string]$manifest.name } else { $pDir.Name }
        if ($pName -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            $errors.Add("[plugin/$($pDir.Name)] Plugin name '$pName' must be lowercase kebab-case")
        }
        if ($seenPluginNames.ContainsKey($pName)) {
            $errors.Add("[plugin/$($pDir.Name)] Duplicate plugin name '$pName'")
        } else {
            $seenPluginNames[$pName] = $pDir.FullName
        }
        if ([string]::IsNullOrWhiteSpace([string]$manifest.description)) {
            $errors.Add("[plugin/$($pDir.Name)] Missing description in plugin.json")
        }
        if ($manifest.suggestedPrompts -and @($manifest.suggestedPrompts).Count -gt 3) {
            $warnings.Add("[plugin/$($pDir.Name)] suggestedPrompts has > 3 items (extras are ignored by UI)")
        }
        foreach ($prop in $manifest.PSObject.Properties.Name) {
            if ($allowedPluginFields -notcontains $prop) {
                $errors.Add("[plugin/$($pDir.Name)] Unsupported top-level field '$prop' in plugin.json")
            }
        }

        $pSkillsDir = Join-Path $pDir.FullName "skills"
        if (Test-Path $pSkillsDir) {
            $pSkillDirs = Get-ChildItem -LiteralPath $pSkillsDir -Directory | Sort-Object Name
            foreach ($sd in $pSkillDirs) {
                $pluginSkillCount++
                Validate-SkillFolder -Dir $sd -ScopeLabel "plugin:$($pDir.Name)"
            }
        }
    }
}

foreach ($w in $warnings) {
    Write-Output "WARN $w"
}
foreach ($e in $errors) {
    Write-Output "ERR  $e"
}

Write-Output ("Summary: {0} global + {1} plugin skills ({2} plugins) checked, {3} warnings, {4} errors" -f $globalDirs.Count, $pluginSkillCount, $seenPluginNames.Count, $warnings.Count, $errors.Count)
if ($errors.Count -gt 0) { exit 1 } else { exit 0 }
