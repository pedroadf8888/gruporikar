# ============================================================
# WallSync RECEIVER - Baixa e aplica wallpaper do GitHub
# ============================================================

# URL do wallpaper (com parâmetro para evitar cache)
$UrlBase = "https://raw.githubusercontent.com/pedroadf8888/gruporikar/main/wallpaper.jpg"
$UrlWallpaper = "$UrlBase`?t=$(Get-Date -Format 'yyyyMMddHHmmss')"

# Configurações locais
$PastaLocal = "C:\scripts\wallpaper"
$PastaLogs = "C:\scripts\wallpaper\logs"
$PastaBackup = "C:\scripts\wallpaper\backup"
$ArquivoLocal = "C:\scripts\wallpaper\wallpaper.jpg"
$ArquivoLog = "C:\scripts\wallpaper\logs\receiver.log"

# ============================================================
# FUNÇÕES
# ============================================================

function Log {
    param([string]$Msg, [string]$Tipo = "INFO")
    $texto = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Tipo] $Msg"
    $script:LogTexto += "$texto`r`n"
    
    # Também salvar no arquivo de log imediatamente
    $texto | Out-File -FilePath $ArquivoLog -Append -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Set-Wallpaper {
    param([string]$Caminho)
    
$code = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    [Wallpaper]::SystemParametersInfo(0x0014, 0, $Caminho, 0x01 -bor 0x02)
    
    # Backup via registro
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $Caminho -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value "2" -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0" -Force
}

# ============================================================
# EXECUÇÃO
# ============================================================

$script:LogTexto = ""

# Criar pastas
@($PastaLocal, $PastaLogs, $PastaBackup) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

Log "========== WALLSYNC RECEIVER ==========" "INFO"
Log "Hostname: $env:COMPUTERNAME" "INFO"
Log "Usuario: $env:USERNAME" "INFO"
Log "URL: $UrlWallpaper" "INFO"

$sucesso = $false

try {
    # Configurar TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Verificar hash do arquivo atual (se existir)
    $hashAnterior = $null
    if (Test-Path $ArquivoLocal) {
        $hashAnterior = (Get-FileHash -Path $ArquivoLocal -Algorithm MD5).Hash
        Log "Hash atual: $hashAnterior" "INFO"
    }
    
    # Baixar para arquivo temporário
    $arquivoTemp = "$PastaLocal\wallpaper_temp.jpg"
    
    Log "Baixando wallpaper..." "INFO"
    
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
    $webClient.Headers.Add("Pragma", "no-cache")
    $webClient.Headers.Add("Expires", "0")
    $webClient.DownloadFile($UrlWallpaper, $arquivoTemp)
    
    # Verificar download
    if (-not (Test-Path $arquivoTemp)) {
        throw "Arquivo nao foi baixado"
    }
    
    $tamanho = (Get-Item $arquivoTemp).Length
    Log "Tamanho baixado: $tamanho bytes" "INFO"
    
    if ($tamanho -lt 1024) {
        throw "Arquivo muito pequeno - possivel erro"
    }
    
    # Verificar hash do novo arquivo
    $hashNovo = (Get-FileHash -Path $arquivoTemp -Algorithm MD5).Hash
    Log "Hash novo: $hashNovo" "INFO"
    
    if ($hashAnterior -and $hashAnterior -eq $hashNovo) {
        Log "Wallpaper nao mudou" "INFO"
        Remove-Item $arquivoTemp -Force -ErrorAction SilentlyContinue
    } else {
        Log "Novo wallpaper detectado!" "INFO"
        
        # Backup do anterior
        if (Test-Path $ArquivoLocal) {
            $dataBackup = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $backupFile = "$PastaBackup\wallpaper_$dataBackup.jpg"
            Copy-Item -Path $ArquivoLocal -Destination $backupFile -Force
            Log "Backup criado: $backupFile" "INFO"
            
            # Limpar backups antigos (manter últimos 5)
            Get-ChildItem -Path $PastaBackup -Filter "*.jpg" | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -Skip 5 | 
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
        
        # Substituir arquivo
        Move-Item -Path $arquivoTemp -Destination $ArquivoLocal -Force
    }
    
    # Aplicar wallpaper
    Log "Aplicando wallpaper..." "INFO"
    Set-Wallpaper -Caminho $ArquivoLocal
    
    # Forçar atualização
    Start-Sleep -Milliseconds 500
    RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True 2>$null
    
    Log "Wallpaper aplicado com sucesso!" "OK"
    $sucesso = $true
    
} catch {
    Log "ERRO: $_" "ERRO"
    
    # Limpar temp se existir
    if (Test-Path "$PastaLocal\wallpaper_temp.jpg") {
        Remove-Item "$PastaLocal\wallpaper_temp.jpg" -Force -ErrorAction SilentlyContinue
    }
}

# Salvar log final
$nomeLogFinal = "$(Get-Date -Format 'yyyy-MM-dd')-$env:COMPUTERNAME.log"
$caminhoLogFinal = Join-Path $PastaLogs $nomeLogFinal

$logFinal = @"
================================================================================
WALLSYNC RECEIVER - LOG
================================================================================
Data: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Status: $(if ($sucesso) { "SUCESSO" } else { "ERRO" })
Hostname: $env:COMPUTERNAME
Usuario: $env:USERNAME

$script:LogTexto
================================================================================
"@

$logFinal | Out-File -FilePath $caminhoLogFinal -Encoding UTF8 -Force

Log "========================================" $(if ($sucesso) { "OK" } else { "ERRO" })