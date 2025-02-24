# Run Fastfetch if it is installed
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch --disk-show-external false
}
# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

# Clearn line is Ctrl-u
Set-PSReadLineKeyHandler -Key Ctrl+u -Function DeleteLine

# Exit Shell with Ctrl-d
Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

# Move to the beginning/end of the line with Ctrl-a and Ctrl-e
Set-PSReadLineKeyHandler -Key Ctrl+a -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key Ctrl+e -Function EndOfLine

# Use Alt+LeftArrow and Alt+RightArrow to move by word
Set-PSReadLineKeyHandler -Key Alt+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Alt+RightArrow -Function ForwardWord

# Use Alt+Backspace to delete by word
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function BackwardKillWord

# Initialize Starship
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $ENV:STARSHIP_CONFIG = "$HOME\.starship\starship.toml"
    $ENV:STARSHIP_CACHE = "$HOME\AppData\Local\Temp"
    function Invoke-Starship-TransientFunction {
        &starship module character
    }
    Invoke-Expression (&starship init powershell)
    Enable-TransientPrompt
}

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}
function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}


# Networking Utilities
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}
