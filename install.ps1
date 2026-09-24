param(
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'OscilloscopeViewer')
)

$ErrorActionPreference = 'Stop'
$sourceDir = $PSScriptRoot
$python = Get-Command python.exe -ErrorAction SilentlyContinue
if (-not $python) {
    throw 'Python 3 was not found. Install Python 3.10+ and enable it in PATH.'
}

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Copy-Item (Join-Path $sourceDir 'oscilloscope_viewer.py') $InstallDir -Force
Copy-Item (Join-Path $sourceDir 'requirements.txt') $InstallDir -Force
Copy-Item (Join-Path $sourceDir 'oscilloscope.ico') $InstallDir -Force
if (Test-Path (Join-Path $sourceDir 'parsers')) {
    Copy-Item (Join-Path $sourceDir 'parsers') $InstallDir -Recurse -Force
}

$venvDir = Join-Path $InstallDir '.venv'
if (-not (Test-Path (Join-Path $venvDir 'Scripts\python.exe'))) {
    & $python.Source -m venv $venvDir
}
$venvPython = Join-Path $venvDir 'Scripts\python.exe'
$pythonw = Join-Path $venvDir 'Scripts\pythonw.exe'
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install pyside6 numpy pandas pyqtgraph

$icon = Join-Path $InstallDir 'oscilloscope.ico'
$script = Join-Path $InstallDir 'oscilloscope_viewer.py'
$shell = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'Oscilloscope Viewer.lnk'
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $pythonw
$shortcut.Arguments = '"' + $script + '"'
$shortcut.WorkingDirectory = $InstallDir
$shortcut.IconLocation = '"' + $icon + '",0'
$shortcut.Description = 'Oscilloscope Waveform Viewer'
$shortcut.Save()

$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$startShortcutPath = Join-Path $startMenu 'Oscilloscope Viewer.lnk'
$shortcut = $shell.CreateShortcut($startShortcutPath)
$shortcut.TargetPath = $pythonw
$shortcut.Arguments = '"' + $script + '"'
$shortcut.WorkingDirectory = $InstallDir
$shortcut.IconLocation = '"' + $icon + '",0'
$shortcut.Description = 'Oscilloscope Waveform Viewer'
$shortcut.Save()

$root = 'HKCU:\Software\Classes\SystemFileAssociations\.csv\shell\OscilloscopeViewer'
$commandKey = Join-Path $root 'command'
New-Item -Path $commandKey -Force | Out-Null
Set-Item -Path $root -Value 'Открыть в Oscilloscope Viewer'
New-ItemProperty -Path $root -Name Icon -Value $icon -PropertyType String -Force | Out-Null
New-ItemProperty -Path $root -Name WorkingDirectory -Value $InstallDir -PropertyType String -Force | Out-Null
$command = '"' + $pythonw + '" "' + $script + '" "%1"'
New-ItemProperty -Path $commandKey -Name '(default)' -Value $command -PropertyType String -Force | Out-Null

Write-Host "Oscilloscope Viewer installed to: $InstallDir"
Write-Host "Desktop shortcut: $shortcutPath"
Write-Host 'CSV context-menu entry registered for the current user.'
