# Configuration -- CloudFix Standalone
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Script:ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$null = chcp 65001

# ---------------------------------------------------------------------------
# Locale defaults
# ---------------------------------------------------------------------------
function Get-DefaultStrings {
    param([string]$Culture)
    $tables = @{
        "en" = @{
            Title                 = "CloudFix / CloudRedirect Installer"
            SteamRegNotFound      = "Steam registry key not found. Is Steam installed?"
            SteamKilling          = "Stopping Steam..."
            CloudInstalling       = "Installing CloudRedirect clean environment..."
            CloudInstalled        = "CloudRedirect installed successfully!"
            CloudFailed           = "CloudRedirect validation failed."
            StartingSteam         = "Starting Steam & CloudRedirect..."
        }
        "pt-BR" = @{
            Title                 = "Instalador CloudFix / CloudRedirect"
            SteamRegNotFound      = "Steam não encontrada no registro. A Steam está instalada?"
            SteamKilling          = "Parando a Steam..."
            CloudInstalling       = "Configurando ambiente limpo do CloudRedirect..."
            CloudInstalled        = "CloudRedirect configurado com sucesso!"
            CloudFailed           = "Falha na validação dos componentes do CloudRedirect."
            StartingSteam         = "Abrindo a Steam e o CloudRedirect..."
        }
    }
    foreach ($key in @($Culture, $Culture.Split('-')[0], "pt-BR")) {
        if ($tables.ContainsKey($key)) { return $tables[$key] }
    }
    return $tables["pt-BR"]
}

$DetectedCulture = [System.Globalization.CultureInfo]::CurrentUICulture.Name
$L = Get-DefaultStrings -Culture $DetectedCulture
$Host.UI.RawUI.WindowTitle = $L["Title"]

$LogColors = @{ "OK" = "Green"; "INFO" = "Cyan"; "ERR" = "Red"; "WARN" = "Yellow"; "LOG" = "Magenta"; "AUX" = "DarkGray" }
function Write-Log {
    param([ValidateSet("OK","INFO","ERR","WARN","LOG","AUX")][string]$Type, [string]$Message)
    $color = $LogColors[$Type]
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts] " -ForegroundColor Cyan -NoNewline
    Write-Host "[$Type] $Message" -ForegroundColor $color
}

# ---------------------------------------------------------------------------
# Steam path
# ---------------------------------------------------------------------------
function Get-SteamPath {
    $registries = @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", "HKLM:\SOFTWARE\Valve\Steam", "HKCU:\SOFTWARE\Valve\Steam")
    foreach ($reg in $registries) {
        if (!(Test-Path $reg)) { continue }
        $path = (Get-ItemProperty -Path $reg -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
        if ((Test-Path $path) -and (Test-Path (Join-Path $path "steam.exe"))) { return $path }
    }
    Write-Log -Type ERR -Message $L["SteamRegNotFound"]
    exit
}

# ---------------------------------------------------------------------------
# Component Validation
# ---------------------------------------------------------------------------
function Test-Components {
    param([string]$SteamPath)
    foreach ($f in @("dwmapi.dll", "OpenSteamTool.dll", "xinput1_4.dll", "cloud_redirect.dll")) {
        if (-not (Test-Path (Join-Path $SteamPath $f))) { return $false }
    }
    return $true
}

# ---------------------------------------------------------------------------
# Core Installation Function
# ---------------------------------------------------------------------------
function Install-Steamtools {
    param([string]$SteamPath)

    Write-Log -Type WARN -Message $L["CloudInstalling"]

    # 1. REMOÇÃO FORÇADA ANTERIOR (Limpeza silenciosa em background)
    $ArquivosLimpeza = @("dwmapi.dll", "OpenSteamTool.dll", "xinput1_4.dll", "cloud_redirect.dll", "opensteamtool.toml")
    foreach ($arq in $ArquivosLimpeza) {
        $CaminhoCompleto = Join-Path $SteamPath $arq
        if (Test-Path $CaminhoCompleto) {
            # Corrigido: Colchete removido do final da linha abaixo
            Remove-Item $CaminhoCompleto -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Configuração dos caminhos de destino do CloudRedirect
    $Script:DesktopPath = [Environment]::GetFolderPath("Desktop")
    $TargetExe          = Join-Path $Script:DesktopPath "CloudRedirect.exe"
    $TargetDll          = Join-Path $SteamPath "cloud_redirect.dll"

    try {
        # 3. Downloads do CloudRedirect Oficial
        Write-Log -Type LOG -Message "Baixando executável e dependências do CloudRedirect..."
        Start-BitsTransfer -Source "https://github.com/Selectively11/CloudRedirect/releases/latest/download/CloudRedirect.exe" -Destination $TargetExe -ErrorAction Stop
        Start-BitsTransfer -Source "https://github.com/Selectively11/CloudRedirect/releases/latest/download/cloud_redirect.dll" -Destination $TargetDll -ErrorAction Stop

        # 4. Downloads das DLLs e do TOML do repositório personalizado
        $BaseUrl = "https://raw.githubusercontent.com/vaporgreen/plugins-green/main/public/opst"
        $ArquivosParaBaixar = @("OpenSteamTool.dll", "dwmapi.dll", "opensteamtool.toml", "xinput1_4.dll")

        Write-Log -Type LOG -Message "Sincronizando arquivos complementares do CloudRedirect..."
        foreach ($item in $ArquivosParaBaixar) {
            $UrlDownload = "$BaseUrl/$item"
            $Destino      = Join-Path $SteamPath $item
            
            # Baixa de forma totalmente silenciosa sem poluir o log
            Start-BitsTransfer -Source $UrlDownload -Destination $Destino -ErrorAction Stop
        }
    }
    catch {
        Write-Log -Type ERR -Message "Falha crítica ao baixar os componentes: $($_.Exception.Message)"
        exit
    }

    # Validação final do ambiente
    if (Test-Components $SteamPath) {
        Write-Log -Type OK -Message $L["CloudInstalled"]
    } else {
        Write-Log -Type ERR -Message $L["CloudFailed"]
        exit
    }
}

# ---------------------------------------------------------------------------
# Main Execution
# ---------------------------------------------------------------------------
function Main {
    $steamPath = Get-SteamPath

    # Fecha a Steam se estiver rodando
    Write-Log -Type INFO -Message $L["SteamKilling"]
    while (Get-Process steam -ErrorAction SilentlyContinue) {
        Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Milliseconds 500
    }

    # Executa a instalação
    Install-Steamtools $steamPath

    # Reabre a Steam
    Write-Log -Type INFO -Message $L["StartingSteam"]
    Start-Process (Join-Path $steamPath "steam.exe")

    # Executa o CloudRedirect.exe
    $CloudRedirectPath = Join-Path $Script:DesktopPath "CloudRedirect.exe"
    if (Test-Path $CloudRedirectPath) {
        Start-Process $CloudRedirectPath
    }
}

Main