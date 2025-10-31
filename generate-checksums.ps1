Param(
    [string]$Path
)

Get-ChildItem -Path $Path -Recurse -Include *.exe,*.deb,*.ddeb,*.pkg,*.tar.gz,*.tar.xz,*.zip | Foreach-Object {
  $name = $_.Name
  $hash = (Get-FileHash $name).Hash.ToLower()
  "    ${name}: ${hash}" >> "$Path\CHECKSUMS.txt"
}
