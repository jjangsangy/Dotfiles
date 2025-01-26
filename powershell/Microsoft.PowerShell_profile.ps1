if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
}

# Clearn line is Ctrl-u
Set-PSReadLineKeyHandler -Key Ctrl+u -Function DeleteLine

# Exit Shell with Ctrl-d
Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
}
