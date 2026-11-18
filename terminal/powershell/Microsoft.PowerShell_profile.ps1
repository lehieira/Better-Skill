# >>> Better-Skill Oh My Posh >>>
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
}

$ompConfig = [System.IO.Path]::Combine($HOME, '.config', 'oh-my-posh', 'custom.omp.json')
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $ompConfig)) {
    oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
}
# <<< Better-Skill Oh My Posh <<<
