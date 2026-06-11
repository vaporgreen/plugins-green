# GreenVapor Installer
# Usage: irm "https://greenvapor.vercel.app/install.ps1" | iex
#
# Override via env vars:
#   $env:GV_DOWNLOAD_LINK  - custom plugin zip URL
#   $env:GV_CULTURE        - force language (en, pt-BR, es, fr)

$Script:DownloadLink   = $env:GV_DOWNLOAD_LINK
$Script:Culture        = $env:GV_CULTURE
$Script:PluginName     = "greenvapor"
$Script:PluginRepo     = "https://github.com/vaporgreen/greenvapor-plugin/releases/latest/download/greenvapor.zip"
$Script:SteamtoolsUrl        = "https://steam.run"
$Script:SteamtoolsFallbackUrl = "https://raw.githubusercontent.com/vaporgreen/plugins-green/master/public/st"
$Script:CloudRedirectUrl  = "https://github.com/Selectively11/CloudRedirect/releases/latest/download/CloudRedirectCLI.exe"
$Script:ProgressPreference = 'SilentlyContinue'

# Force UTF-8 before any output — must come before Write-Host calls in PS 5.1
$null = chcp 65001
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Net.Http

# ---------------------------------------------------------------------------
# Locale
# ---------------------------------------------------------------------------
function Get-Strings {
    param([string]$Culture)
    $tables = @{
        "en" = @{
            Title                    = "GreenVapor Installer | discord.gg/greenvapor"
            SteamNotFound            = "Steam not found in registry. Is Steam installed?"
            SteamKilling             = "Stopping Steam..."
            SteamtoolsFound          = "Steamtools already installed"
            SteamtoolsNotFound       = "Steamtools not found — installing..."
            SteamtoolsInstalling     = "Installing Steamtools..."
            SteamtoolsInstalled      = "Steamtools installed"
            SteamtoolsRetrying       = "Steamtools install failed, retrying..."
            SteamtoolsFailed         = "Steamtools failed after 5 attempts — trying fallback..."
            SteamtoolsFallback       = "Downloading Steamtools from GreenVapor repo..."
            SteamtoolsFallbackOk     = "Steamtools installed via fallback"
            SteamtoolsFallbackFailed = "Fallback failed — install Steamtools manually later"
            CloudRedirectApplying    = "Applying Steamtools fix (CloudRedirect)..."
            CloudRedirectDone        = "Steamtools fix applied"
            CloudRedirectFailed      = "CloudRedirect failed (skipping)"
            MillenniumInstalling     = "Installing Millennium..."
            MillenniumInstalled      = "Millennium installed"
            MillenniumAlready        = "Millennium already installed"
            MillenniumFirstBoot      = "Steam may be slower on first boot — let it load."
            PluginDownloading        = "Downloading GreenVapor..."
            PluginExtracting         = "Extracting GreenVapor..."
            PluginInstalled          = "GreenVapor installed!"
            PluginEnabled            = "GreenVapor enabled"
            CleaningUp               = "Cleaning up..."
            StartingSteam            = "Starting Steam..."
            Done                     = "All done! Enjoy GreenVapor."
            ErrorTitle               = "GreenVapor Installer — ERROR"
            ErrorHeader              = "AN ERROR OCCURRED"
            ErrorBody                = "The installer encountered a problem. This is often caused by your ISP blocking download servers."
            ErrorFaq                 = "Visit discord.gg/greenvapor for help."
            ErrorExit                = "Press any key to exit."
        }
        "pt-BR" = @{
            Title                    = "Instalador GreenVapor | discord.gg/greenvapor"
            SteamNotFound            = "Steam nao encontrada no registro. Esta instalada?"
            SteamKilling             = "Encerrando o Steam..."
            SteamtoolsFound          = "Steamtools ja instalado"
            SteamtoolsNotFound       = "Steamtools nao encontrado — instalando..."
            SteamtoolsInstalling     = "Instalando Steamtools..."
            SteamtoolsInstalled      = "Steamtools instalado"
            SteamtoolsRetrying       = "Falha ao instalar Steamtools, tentando de novo..."
            SteamtoolsFailed         = "Steamtools falhou apos 5 tentativas — tentando fallback..."
            SteamtoolsFallback       = "Baixando Steamtools do repositorio GreenVapor..."
            SteamtoolsFallbackOk     = "Steamtools instalado via fallback"
            SteamtoolsFallbackFailed = "Fallback falhou — instale o Steamtools manualmente depois"
            CloudRedirectApplying    = "Aplicando correcao do Steamtools (CloudRedirect)..."
            CloudRedirectDone        = "Correcao do Steamtools aplicada"
            CloudRedirectFailed      = "CloudRedirect falhou (ignorando)"
            MillenniumInstalling     = "Instalando o Millennium..."
            MillenniumInstalled      = "Millennium instalado"
            MillenniumAlready        = "Millennium já está instalado"
            MillenniumFirstBoot      = "A Steam pode demorar um pouco na primeira inicialização — aguarde."
            PluginDownloading        = "Baixando GreenVapor..."
            PluginExtracting         = "Extraindo GreenVapor..."
            PluginInstalled          = "GreenVapor instalado!"
            PluginEnabled            = "GreenVapor habilitado"
            CleaningUp               = "Limpando arquivos temporários..."
            StartingSteam            = "Abrindo o Steam..."
            Done                     = "Pronto! Bom uso do GreenVapor."
            ErrorTitle               = "Instalador GreenVapor — ERRO"
            ErrorHeader              = "OCORREU UM ERRO"
            ErrorBody                = "O instalador encontrou um problema. Geralmente causado pela sua internet bloqueando os servidores de download."
            ErrorFaq                 = "Acesse discord.gg/greenvapor para ajuda."
            ErrorExit                = "Pressione qualquer tecla para sair."
        }
        "es" = @{
            Title                    = "Instalador GreenVapor | discord.gg/greenvapor"
            SteamNotFound            = "Steam no encontrado en el registro. ¿Está instalado?"
            SteamKilling             = "Cerrando Steam..."
            SteamtoolsFound          = "Steamtools ya está instalado"
            SteamtoolsNotFound       = "Steamtools no encontrado — instalando..."
            SteamtoolsInstalling     = "Instalando Steamtools..."
            SteamtoolsInstalled      = "Steamtools instalado"
            SteamtoolsRetrying       = "Fallo al instalar Steamtools, reintentando..."
            SteamtoolsFailed         = "Instalación de Steamtools fallida tras 5 intentos"
            CloudRedirectApplying    = "Aplicando parche de Steamtools (CloudRedirect)..."
            CloudRedirectDone        = "Parche de Steamtools aplicado"
            CloudRedirectFailed      = "CloudRedirect falló (omitiendo)"
            MillenniumInstalling     = "Instalando Millennium..."
            MillenniumInstalled      = "Millennium instalado"
            MillenniumAlready        = "Millennium ya estaba instalado"
            MillenniumFirstBoot      = "Steam puede tardar más en el primer inicio — espera."
            PluginDownloading        = "Descargando GreenVapor..."
            PluginExtracting         = "Extrayendo GreenVapor..."
            PluginInstalled          = "¡GreenVapor instalado!"
            PluginEnabled            = "GreenVapor habilitado"
            CleaningUp               = "Limpiando archivos temporales..."
            StartingSteam            = "Iniciando Steam..."
            Done                     = "¡Listo! Disfruta GreenVapor."
            ErrorTitle               = "Instalador GreenVapor — ERROR"
            ErrorHeader              = "OCURRIÓ UN ERROR"
            ErrorBody                = "El instalador encontró un problema. Suele ocurrir cuando tu ISP bloquea los servidores de descarga."
            ErrorFaq                 = "Visita discord.gg/greenvapor para más ayuda."
            ErrorExit                = "Presiona cualquier tecla para salir."
        }
    }
    foreach ($key in @($Culture, ($Culture -split '-')[0], "en")) {
        if ($tables.ContainsKey($key)) { return $tables[$key] }
    }
    return $tables["en"]
}

$DetectedCulture = if ($Script:Culture) { $Script:Culture } else {
    [System.Globalization.CultureInfo]::CurrentUICulture.Name
}
$L = Get-Strings -Culture $DetectedCulture

# ---------------------------------------------------------------------------
# Error trap
# ---------------------------------------------------------------------------
$Script:OriginalEA = $ErrorActionPreference
$ErrorActionPreference = "Stop"

trap {
    $msg = $_.Exception.Message
    if (-not $L) { $L = Get-Strings -Culture "en" }
    Clear-Host
    $host.UI.RawUI.WindowTitle = $L.ErrorTitle
    $w = $host.UI.RawUI.WindowSize.Width
    Write-Host ("=" * $w) -ForegroundColor Red
    Write-Host ""
    $pad = [Math]::Max(0, [int](($w - $L.ErrorHeader.Length) / 2))
    Write-Host (" " * $pad + $L.ErrorHeader) -ForegroundColor Red
    Write-Host ""
    Write-Host $L.ErrorBody -ForegroundColor White
    Write-Host ""
    Write-Host ">>> $msg" -ForegroundColor Yellow
    Write-Host ""
    Write-Host $L.ErrorFaq -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("=" * $w) -ForegroundColor Red
    Write-Host ""
    Write-Host $L.ErrorExit -ForegroundColor Yellow
    try { $null = [System.Console]::ReadKey($true) } catch {}
    $ErrorActionPreference = $Script:OriginalEA
    break
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
$host.UI.RawUI.WindowTitle = $L.Title

function Write-Log {
    param(
        [ValidateSet("OK","INFO","WARN","ERR","LOG","AUX")][string]$Type,
        [string]$Message
    )
    $colors = @{ OK="Green"; INFO="Cyan"; WARN="Yellow"; ERR="Red"; LOG="Magenta"; AUX="DarkGray" }
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts] " -ForegroundColor Cyan -NoNewline
    Write-Host "[$Type] $Message" -ForegroundColor $colors[$Type]
}

function Get-SteamPath {
    foreach ($reg in @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )) {
        if (-not (Test-Path $reg)) { continue }
        $p = (Get-ItemProperty $reg -Name InstallPath -ErrorAction SilentlyContinue).InstallPath
        if ($p -and (Test-Path (Join-Path $p "steam.exe"))) { return $p }
    }
    throw $L.SteamNotFound
}

function Test-Steamtools {
    param([string]$SteamPath)
    foreach ($f in @("dwmapi.dll", "xinput1_4.dll")) {
        if (Test-Path (Join-Path $SteamPath $f)) { return $true }
    }
    return $false
}

function Install-Steamtools {
    param([string]$SteamPath)
    Write-Log INFO $L.SteamtoolsInstalling
    $raw = $null
    try { $raw = Invoke-RestMethod $Script:SteamtoolsUrl -TimeoutSec 30 } catch {}
    if (-not $raw) { throw "steam.run unreachable" }

    # Filter lines that start/stop Steam — our installer controls the Steam lifecycle
    $filtered = ($raw -split "`n") | Where-Object {
        ($_ -inotmatch "Start-Process.*steam") -and
        ($_ -inotmatch "steam\.exe")           -and
        ($_ -inotmatch "Stop-Process")         -and
        ($_ -inotmatch "cls|Clear-Host")
    }
    $block = $filtered -join "`n"

    for ($i = 1; $i -le 5; $i++) {
        Invoke-Expression $block *> $null
        if (Test-Steamtools $SteamPath) {
            Write-Log OK $L.SteamtoolsInstalled
            return
        }
        Write-Log WARN $L.SteamtoolsRetrying
    }
    throw $L.SteamtoolsFailed
}

function Install-Steamtools-Fallback {
    param([string]$SteamPath)
    Write-Log WARN $L.SteamtoolsFallback
    $files = @("dwmapi.dll", "xinput1_4.dll")
    foreach ($f in $files) {
        $url  = "$Script:SteamtoolsFallbackUrl/$f"
        $dest = Join-Path $SteamPath $f
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $dest -TimeoutSec 60 -ErrorAction Stop
    }
    Write-Log OK $L.SteamtoolsFallbackOk
}

function Invoke-CloudRedirect {
    Write-Log INFO $L.CloudRedirectApplying
    $crExe = Join-Path $env:TEMP "CloudRedirectCLI.exe"
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Script:CloudRedirectUrl -OutFile $crExe -TimeoutSec 60 -ErrorAction Stop
        $proc = Start-Process -FilePath $crExe -ArgumentList "/stfixer" -Wait -PassThru -ErrorAction Stop
        if ($proc.ExitCode -eq 0) {
            Write-Log OK $L.CloudRedirectDone
        } else {
            Write-Log WARN $L.CloudRedirectFailed
        }
    } catch {
        Write-Log WARN $L.CloudRedirectFailed
    } finally {
        Remove-Item $crExe -ErrorAction SilentlyContinue
    }
}

function Test-Millennium {
    param([string]$SteamPath)
    return (Test-Path (Join-Path $SteamPath "millennium.dll")) -and
           (Test-Path (Join-Path $SteamPath "python311.dll"))
}

function Install-Millennium {
    param([string]$SteamPath)
    Write-Log INFO $L.MillenniumInstalling
    $urls = @("https://clemdotla.github.io/millennium-installer-ps1/millennium.ps1")
    $code = $null
    foreach ($url in $urls) {
        try { $code = Invoke-RestMethod $url -TimeoutSec 30; if ($code) { break } } catch {}
    }
    if (-not $code) { throw $L.MillenniumInstalling }
    Invoke-Expression "& { $code } -NoLog -DontStart -SteamPath '$SteamPath'"
    Write-Log OK $L.MillenniumInstalled
}

function Install-GreenVapor {
    param([string]$SteamPath, [string]$ZipUrl)

    $millDir    = Join-Path $SteamPath "millennium"
    $pluginsDir = Join-Path $millDir "plugins"
    $null = New-Item -Path $pluginsDir -ItemType Directory -Force

    # Find existing install dir (update in place) or create new
    $targetDir = Join-Path $pluginsDir $Script:PluginName
    foreach ($dir in (Get-ChildItem $pluginsDir -Directory -ErrorAction SilentlyContinue)) {
        $pj = Join-Path $dir.FullName "plugin.json"
        if (Test-Path $pj) {
            try {
                $m = Get-Content $pj -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($m.name -eq $Script:PluginName) { $targetDir = $dir.FullName; break }
            } catch {}
        }
    }

    $zipPath = Join-Path $env:TEMP "greenvapor.zip"

    Write-Log LOG $L.PluginDownloading
    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [System.TimeSpan]::FromSeconds(120)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("GreenVapor-Installer/1.0")
    $stream     = $client.GetStreamAsync($ZipUrl).Result
    $fileStream = [System.IO.File]::Create($zipPath)
    $stream.CopyTo($fileStream)
    $fileStream.Close(); $stream.Close(); $client.Dispose()

    if (-not (Test-Path $zipPath)) { throw $L.PluginDownloading }

    Write-Log LOG $L.PluginExtracting
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')) { continue }
            $dest   = Join-Path $targetDir $entry.FullName
            $parent = Split-Path $dest -Parent
            $null   = [System.IO.Directory]::CreateDirectory($parent)
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)
        }
        $zip.Dispose()
    } catch {
        if ($zip) { $zip.Dispose() }
        Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
    }

    Remove-Item $zipPath -ErrorAction SilentlyContinue
    Write-Log OK $L.PluginInstalled
}

function Enable-Plugin {
    param([string]$SteamPath)
    $millDir    = Join-Path $SteamPath "millennium"
    $configDir  = Join-Path $millDir "config"
    $configPath = Join-Path $configDir "config.json"
    $null = New-Item -Path $configDir -ItemType Directory -Force

    if (-not (Test-Path $configPath)) {
        @{ plugins = @{ enabledPlugins = @($Script:PluginName) } } |
            ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
    } else {
        $cfg = (Get-Content $configPath -Raw -Encoding UTF8) | ConvertFrom-Json
        if (-not $cfg.plugins) {
            $cfg | Add-Member -MemberType NoteProperty -Name plugins -Value @{ enabledPlugins = @() } -Force
        }
        $list = @($cfg.plugins.enabledPlugins)
        if ($list -notcontains $Script:PluginName) {
            $list += $Script:PluginName
            $cfg.plugins.enabledPlugins = $list
        }
        $cfg | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
    }
    Write-Log OK $L.PluginEnabled
}

function Invoke-Cleanup {
    param([string]$SteamPath)
    Write-Log AUX $L.CleaningUp
    $beta = Join-Path $SteamPath "package\beta"
    if (Test-Path $beta) { Remove-Item $beta -Recurse -Force -ErrorAction SilentlyContinue }
    $cfg = Join-Path $SteamPath "steam.cfg"
    if (Test-Path $cfg) { Remove-Item $cfg -Force -ErrorAction SilentlyContinue }
    @("HKCU:\Software\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKLM:\SOFTWARE\WOW6432Node\Valve\Steam") | ForEach-Object {
        Remove-ItemProperty -Path $_ -Name "SteamCmdForceX86" -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$steamPath = Get-SteamPath

Write-Log INFO $L.SteamKilling
while (Get-Process steam -ErrorAction SilentlyContinue) {
    Stop-Process -Name steam -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

if (Test-Steamtools $steamPath) {
    Write-Log INFO $L.SteamtoolsFound
} else {
    Write-Log WARN $L.SteamtoolsNotFound
    try {
        Install-Steamtools $steamPath
    } catch {
        Write-Log WARN $L.SteamtoolsFailed
        try {
            Install-Steamtools-Fallback $steamPath
        } catch {
            Write-Log WARN $L.SteamtoolsFallbackFailed
        }
    }
}

Invoke-CloudRedirect

if (Test-Millennium $steamPath) {
    Write-Log INFO $L.MillenniumAlready
} else {
    Install-Millennium $steamPath
    Write-Log WARN $L.MillenniumFirstBoot
}

$zipUrl = if ($Script:DownloadLink) { $Script:DownloadLink } else { $Script:PluginRepo }
Install-GreenVapor $steamPath $zipUrl
Enable-Plugin $steamPath
Invoke-Cleanup $steamPath

Write-Host ""
Write-Log OK $L.Done
Write-Log INFO $L.StartingSteam
Start-Process (Join-Path $steamPath "steam.exe") -ArgumentList "-clearbeta"

$ErrorActionPreference = $Script:OriginalEA
