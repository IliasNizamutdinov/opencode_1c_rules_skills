<#
.SYNOPSIS
    Установка правил и скиллов 1С для OpenCode.

.DESCRIPTION
    Копирует skills, rules и commands в проект (.opencode) или глобально
    (%USERPROFILE%\.config\opencode). Отличающийся файл не перезаписывается
    без -Yes или явного ответа. Чужие скиллы не удаляются. Перед заменой
    создается резервная копия.

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -Global

.EXAMPLE
    .\install.ps1 -ProjectDir C:\Projects\my-1c -RulesOnly

.EXAMPLE
    .\install.ps1 -List

.EXAMPLE
    .\install.ps1 -Uninstall -Yes
#>
[CmdletBinding()]
param(
    [string]$ProjectDir = (Get-Location).Path,
    [switch]$Global,
    [switch]$RulesOnly,
    [switch]$SkillsOnly,
    [switch]$CommandsOnly,
    [switch]$List,
    [switch]$Uninstall,
    [switch]$Yes,
    [switch]$NonInteractive,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$InstallGlobal = [bool]$Global
if (-not $Yes -and -not $NonInteractive) {
    try {
        if ([Console]::IsInputRedirected) { $NonInteractive = $true }
    } catch { }
}

$Source = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DoRules = $true
$DoSkills = $true
$DoCommands = $true
if ($RulesOnly -or $SkillsOnly -or $CommandsOnly) {
    $DoRules = [bool]$RulesOnly
    $DoSkills = [bool]$SkillsOnly
    $DoCommands = [bool]$CommandsOnly
}

if ($InstallGlobal) {
    $ConfigRoot = Join-Path $env:USERPROFILE ".config\opencode"
    $Base = $ConfigRoot
    $AgentsFile = Join-Path $ConfigRoot "AGENTS.md"
    $RulesLink = $ConfigRoot.Replace("\", "/") + "/1c-rules"
    $Scope = "global"
} else {
    $ProjectDir = (Resolve-Path -LiteralPath $ProjectDir).Path
    $Base = Join-Path $ProjectDir ".opencode"
    $ConfigRoot = $ProjectDir
    $AgentsFile = Join-Path $ProjectDir "AGENTS.md"
    $RulesLink = ".opencode/1c-rules"
    $Scope = "project"
}
$ManifestPath = Join-Path $Base "1c-kit-manifest.tsv"
$BackupRoot = Join-Path $Base "1c-kit-backups"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Utf8 = New-Object System.Text.UTF8Encoding $false
$script:ReplaceAll = [bool]$Yes

function Get-NormalizedHash([string]$Path) {
    $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    $text = @(".md", ".txt", ".json", ".yml", ".yaml", ".py", ".ps1", ".sh", ".mjs", ".js", ".bsl", ".xml", ".csv", ".tsv", ".markdown")
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($text -contains $ext) {
        $filtered = New-Object System.Collections.Generic.List[byte]
        foreach ($b in $bytes) { if ($b -ne 13) { [void]$filtered.Add($b) } }
        $bytes = $filtered.ToArray()
    }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    } finally { $sha.Dispose() }
    return ([BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
}

function Get-PathKey([string]$Rel) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Rel))
    } finally { $sha.Dispose() }
    return ([BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
}

function Get-SourceItems {
    $items = New-Object System.Collections.Generic.List[object]
    if ($DoSkills) {
        $root = (Resolve-Path -LiteralPath (Join-Path $Source "skills")).Path
        Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
            $_.FullName -notmatch '[\\/]__pycache__[\\/]' -and $_.Extension -ne ".pyc"
        } | ForEach-Object {
            $rel = "skills/" + $_.FullName.Substring($root.Length).TrimStart("\", "/").Replace("\", "/")
            $items.Add([pscustomobject]@{ Rel = $rel; Src = $_.FullName; Component = "skills" })
        }
    }
    if ($DoRules) {
        $root = (Resolve-Path -LiteralPath (Join-Path $Source "rules")).Path
        foreach ($file in (Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $_.Name -ne "README.md" })) {
            $rel = "1c-rules/" + $file.FullName.Substring($root.Length).TrimStart("\", "/").Replace("\", "/")
            $items.Add([pscustomobject]@{ Rel = $rel; Src = $file.FullName; Component = "rules" })
        }
    }
    if ($DoCommands) {
        $root = (Resolve-Path -LiteralPath (Join-Path $Source "commands")).Path
        foreach ($file in (Get-ChildItem -LiteralPath $root -File)) {
            $items.Add([pscustomobject]@{ Rel = ("commands/" + $file.Name); Src = $file.FullName; Component = "commands" })
        }
    }
    return $items
}

function Read-Manifest {
    $map = @{}
    $meta = @{ agents_created = "0"; scope = $Scope }
    if (-not (Test-Path -LiteralPath $ManifestPath)) { return @{ Map = $map; Meta = $meta } }
    $text = [IO.File]::ReadAllText($ManifestPath)
    foreach ($line in ($text -split "`n")) {
        $line = $line.TrimEnd("`r")
        if (-not $line -or $line.StartsWith("#")) { continue }
        $parts = $line.Split("`t")
        if ($parts[0] -eq "meta" -and $parts.Length -ge 3) { $meta[$parts[1]] = $parts[2] }
        elseif ($parts[0] -eq "file" -and $parts.Length -ge 4) {
            $map[$parts[3]] = @{ Hash = $parts[1]; Component = $parts[2]; Rel = $parts[3] }
        }
    }
    return @{ Map = $map; Meta = $meta }
}

function Write-Manifest($Map, $AgentsCreated) {
    if ($DryRun) { return }
    $dir = Split-Path -Parent $ManifestPath
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $lines = @("# opencode-1c-kit`t1", "meta`tagents_created`t$AgentsCreated", "meta`tscope`t$Scope")
    foreach ($rel in ($Map.Keys | Sort-Object)) {
        $row = $Map[$rel]
        $lines += "file`t$($row.Hash)`t$($row.Component)`t$rel"
    }
    [IO.File]::WriteAllText($ManifestPath, (($lines -join "`n") + "`n"), $Utf8)
}

function Backup-File([string]$Dest) {
    $rel = $Dest.Substring($ConfigRoot.Length).TrimStart("\", "/").Replace("\", "/")
    $backup = Join-Path $BackupRoot (Join-Path $Stamp ($rel.Replace("/", [IO.Path]::DirectorySeparatorChar)))
    $parent = Split-Path -Parent $backup
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $Dest -Destination $backup -Force
    return $backup
}

function Confirm-Replace([string]$Dest, [string]$Src) {
    if ($script:ReplaceAll) { return $true }
    if ($NonInteractive -or $DryRun) { return $false }
    Write-Host "Файл уже есть и отличается от версии набора:"
    Write-Host "  $Dest"
    Write-Host "Замена обновит файл до версии репозитория. Перед заменой будет резервная копия."
    if ($Src -and (Test-Path -LiteralPath $Src)) {
        git -C $Source diff --no-index -- "$Dest" "$Src" 2>$null | Select-Object -First 120 | ForEach-Object { Write-Host $_ }
    }
    $answer = Read-Host "Действие: [k] оставить, [r] заменить, [a] заменить все, [q] прервать"
    switch ($answer) {
        { $_ -in "r", "R" } { return $true }
        { $_ -in "a", "A" } { $script:ReplaceAll = $true; return $true }
        { $_ -in "q", "Q" } { throw "Установка прервана." }
        default { return $false }
    }
}

function Install-Tree {
    $old = Read-Manifest
    $map = @{}
    foreach ($key in $old.Map.Keys) { $map[$key] = $old.Map[$key] }
    $copied = 0; $same = 0; $kept = 0; $replaced = 0
    $seen = @{}
    foreach ($item in (Get-SourceItems)) {
        $seen[$item.Rel] = $true
        $dest = Join-Path $Base ($item.Rel.Replace("/", [IO.Path]::DirectorySeparatorChar))
        $hash = Get-NormalizedHash $item.Src
        if (-not (Test-Path -LiteralPath $dest)) {
            if ($DryRun) { Write-Host "поставить $($item.Rel)" }
            else {
                $parent = Split-Path -Parent $dest
                if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                Copy-Item -LiteralPath $item.Src -Destination $dest -Force
            }
            $map[$item.Rel] = @{ Hash = $hash; Component = $item.Component; Rel = $item.Rel }
            $copied++
            continue
        }
        $current = Get-NormalizedHash $dest
        if ($current -eq $hash) {
            $map[$item.Rel] = @{ Hash = $hash; Component = $item.Component; Rel = $item.Rel }
            $same++
            continue
        }
        Write-Host "отличается: $($item.Rel)"
        if (Confirm-Replace $dest $item.Src) {
            if (-not $DryRun) {
                $backup = Backup-File $dest
                Copy-Item -LiteralPath $item.Src -Destination $dest -Force
                Write-Host "  заменен, копия: $backup"
            }
            $map[$item.Rel] = @{ Hash = $hash; Component = $item.Component; Rel = $item.Rel }
            $replaced++
        } else {
            Write-Host "  оставлена ваша версия"
            $kept++
            if (-not $old.Map.ContainsKey($item.Rel)) { $map.Remove($item.Rel) }
        }
    }
    foreach ($rel in @($old.Map.Keys)) {
        if ($seen.ContainsKey($rel)) { continue }
        $row = $old.Map[$rel]
        $selected = ($row.Component -eq "skills" -and $DoSkills) -or ($row.Component -eq "rules" -and $DoRules) -or ($row.Component -eq "commands" -and $DoCommands)
        if (-not $selected) { continue }
        $dest = Join-Path $Base ($rel.Replace("/", [IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $dest)) { $map.Remove($rel); continue }
        if ((Get-NormalizedHash $dest) -eq $row.Hash) {
            if (-not $DryRun) { Remove-Item -LiteralPath $dest -Force }
            $map.Remove($rel)
            Write-Host "удален устаревший файл набора: $rel"
        } else {
            Write-Host "устаревший файл изменен вами, оставлен: $rel"
        }
    }
    $agentsCreated = $old.Meta["agents_created"]
    if ($DoRules) { $agentsCreated = Update-AgentsBlock $agentsCreated }
    if (-not $DryRun) { Write-Manifest $map $agentsCreated }
    Write-Host "Готово (${Scope}): поставлено $copied, без изменений $same, заменено $replaced, оставлено ваших $kept"
    Write-Host "Каталог: $Base"
    if ($DoRules) {
        Write-Host "Правила: $RulesLink"
        Write-Host "Указатель: $AgentsFile"
    }
}

function Update-AgentsBlock([string]$AgentsCreated) {
    $indexPath = Join-Path $Source "templates\rules-index.md"
    $index = [IO.File]::ReadAllText($indexPath).Replace("@RULES_ROOT@", $RulesLink).TrimEnd("`r", "`n")
    $block = "<!-- 1c-opencode-rules:start -->`n$index`n<!-- 1c-opencode-rules:end -->"
    if (-not (Test-Path -LiteralPath $AgentsFile)) {
        if ($DryRun) { Write-Host "создать $AgentsFile"; return $AgentsCreated }
        $parent = Split-Path -Parent $AgentsFile
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [IO.File]::WriteAllText($AgentsFile, $block + "`n", $Utf8)
        Write-Host "создан $AgentsFile"
        return "1"
    }
    $current = [IO.File]::ReadAllText($AgentsFile)
    if ($current.Contains("1c-opencode-rules:start")) {
        $pattern = "(?s)<!-- 1c-opencode-rules:start -->.*?<!-- 1c-opencode-rules:end -->"
        $match = [regex]::Match($current, $pattern)
        if ($match.Success -and ($match.Value.Replace("`r", "") -eq $block)) {
            Write-Host "блок правил в AGENTS.md совпадает"
            return $AgentsCreated
        }
        Write-Host "блок правил в AGENTS.md отличается"
        if (-not (Confirm-Replace $AgentsFile $null)) {
            Write-Host "  блок правил оставлен как есть"
            return $AgentsCreated
        }
        if ($DryRun) { Write-Host "  dry-run: блок был бы заменен"; return $AgentsCreated }
        Backup-File $AgentsFile | Out-Null
        $updated = [regex]::Replace($current, $pattern, $block)
        [IO.File]::WriteAllText($AgentsFile, $updated, $Utf8)
        Write-Host "  блок правил обновлен"
        return $AgentsCreated
    }
    Write-Host "В $AgentsFile нет блока набора. Будет добавлен в конец, остальной текст не изменится."
    if (-not (Confirm-Replace $AgentsFile $null)) {
        Write-Host "  блок не добавлен. Подключите правила вручную, см. docs/installation.md"
        return $AgentsCreated
    }
    if ($DryRun) { Write-Host "  dry-run: блок был бы добавлен"; return $AgentsCreated }
    Backup-File $AgentsFile | Out-Null
    $suffix = "`n" + $block + "`n"
    [IO.File]::AppendAllText($AgentsFile, $suffix, $Utf8)
    Write-Host "  блок добавлен в конец $AgentsFile"
    return $AgentsCreated
}

function Show-List {
    $missing = 0; $modified = 0; $ok = 0
    foreach ($item in (Get-SourceItems)) {
        $dest = Join-Path $Base ($item.Rel.Replace("/", [IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $dest)) { Write-Host "нет       $($item.Rel)"; $missing++; continue }
        if ((Get-NormalizedHash $dest) -eq (Get-NormalizedHash $item.Src)) { Write-Host "совпадает $($item.Rel)"; $ok++ }
        else { Write-Host "отличается $($item.Rel)"; $modified++ }
    }
    Write-Host "Совпадает: $ok, нет: $missing, отличается: $modified"
    Write-Host "Каталог: $Base"
    if ((Test-Path -LiteralPath $AgentsFile) -and ([IO.File]::ReadAllText($AgentsFile).Contains("1c-opencode-rules:start"))) {
        Write-Host "Блок правил в ${AgentsFile}: есть"
    } else {
        Write-Host "Блок правил в ${AgentsFile}: нет"
    }
}

function Uninstall-Kit {
    $old = Read-Manifest
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        Write-Host "Манифест не найден: $ManifestPath. Удалять нечего."
        return
    }
    if (-not $Yes -and $NonInteractive) {
        Write-Host "Удаление без -Yes в неинтерактивном режиме отменено."
        exit 2
    }
    if (-not $Yes) {
        $answer = Read-Host "Будут удалены только файлы набора, совпадающие с манифестом. Продолжить? [y/N]"
        if ($answer -notin @("y", "Y")) { Write-Host "Отменено."; exit 2 }
    }
    $removed = 0; $kept = 0
    $map = @{}
    foreach ($rel in $old.Map.Keys) {
        $row = $old.Map[$rel]
        $selected = ($row.Component -eq "skills" -and $DoSkills) -or ($row.Component -eq "rules" -and $DoRules) -or ($row.Component -eq "commands" -and $DoCommands)
        if (-not $selected) { $map[$rel] = $row; continue }
        $dest = Join-Path $Base ($rel.Replace("/", [IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $dest)) { continue }
        if ((Get-NormalizedHash $dest) -eq $row.Hash) {
            Remove-Item -LiteralPath $dest -Force
            Write-Host "удален $rel"
            $removed++
        } else {
            Write-Host "оставлен измененный $rel"
            $map[$rel] = $row
            $kept++
        }
    }
    $agentsCreated = $old.Meta["agents_created"]
    if ($DoRules -and (Test-Path -LiteralPath $AgentsFile)) {
        $current = [IO.File]::ReadAllText($AgentsFile)
        if ($current.Contains("1c-opencode-rules:start")) {
            Backup-File $AgentsFile | Out-Null
            $pattern = "(?s)<!-- 1c-opencode-rules:start -->.*?<!-- 1c-opencode-rules:end -->"
            $stripped = [regex]::Replace($current, $pattern, "").Trim()
            if ($agentsCreated -eq "1" -and [string]::IsNullOrWhiteSpace($stripped)) {
                Remove-Item -LiteralPath $AgentsFile -Force
                Write-Host "удален $AgentsFile (его создал установщик, своего текста не было)"
            } else {
                [IO.File]::WriteAllText($AgentsFile, ($stripped + "`n"), $Utf8)
                Write-Host "из $AgentsFile удален только блок набора"
            }
            $agentsCreated = "0"
        }
    }
    Write-Manifest $map $agentsCreated
    Write-Host "Удалено файлов: $removed, оставлено измененных: $kept"
}

if ($List) { Show-List }
elseif ($Uninstall) { Uninstall-Kit }
else { Install-Tree }
