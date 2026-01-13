# ============================================================
# Instalador do WallSync - Importa XML
# ============================================================

Clear-Host
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   INSTALADOR WALLSYNC - IMPORTAR XML      " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERRO: Execute como ADMINISTRADOR!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "Administrador: OK" -ForegroundColor Green
Write-Host ""

# ============================================================
# Configurações
# ============================================================
$NomeTarefa = "WallSync - Wallpaper Corporativo"
$ArquivoXML = "C:\scripts\WallSync-WallpaperCorporativo.xml"
$CaminhoScript = "C:\scripts\wallpaper\receiver_github.ps1"

# ============================================================
# Criar pastas
# ============================================================
Write-Host "[1] Criando pastas..." -ForegroundColor Yellow

@("C:\scripts\wallpaper", "C:\scripts\wallpaper\logs", "C:\scripts\wallpaper\backup") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}
Write-Host "  OK" -ForegroundColor Green
Write-Host ""

# ============================================================
# Criar XML se não existir
# ============================================================
Write-Host "[2] Verificando XML..." -ForegroundColor Yellow

if (-not (Test-Path $ArquivoXML)) {
    Write-Host "  Criando XML..." -ForegroundColor Cyan
    
    $xmlContent = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Aplica wallpaper corporativo automaticamente no logon</Description>
    <Author>WallSync</Author>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-545</GroupId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\scripts\wallpaper\receiver_github.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
    
    $xmlContent | Out-File -FilePath $ArquivoXML -Encoding Unicode -Force
    Write-Host "  XML criado!" -ForegroundColor Green
} else {
    Write-Host "  XML encontrado!" -ForegroundColor Green
}
Write-Host ""

# ============================================================
# Verificar script receiver
# ============================================================
Write-Host "[3] Verificando script receiver..." -ForegroundColor Yellow

if (Test-Path $CaminhoScript) {
    Write-Host "  Script encontrado: OK" -ForegroundColor Green
} else {
    Write-Host "  AVISO: Salve o receiver em $CaminhoScript" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================
# Remover tarefa antiga
# ============================================================
Write-Host "[4] Removendo tarefa antiga..." -ForegroundColor Yellow

schtasks /delete /tn "$NomeTarefa" /f 2>$null | Out-Null
Write-Host "  OK" -ForegroundColor Green
Write-Host ""

# ============================================================
# Importar XML
# ============================================================
Write-Host "[5] Importando tarefa..." -ForegroundColor Yellow
Write-Host "  - Executa no LOGON do usuario" -ForegroundColor Cyan
Write-Host "  - Apenas quando CONECTADO" -ForegroundColor Cyan
Write-Host "  - Visivel para TODOS" -ForegroundColor Cyan
Write-Host ""

$resultado = schtasks /create /tn "$NomeTarefa" /xml "$ArquivoXML" /f 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Tarefa criada com sucesso!" -ForegroundColor Green
} else {
    Write-Host "  Resultado: $resultado" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================
# Verificar tarefa
# ============================================================
Write-Host "[6] Verificando tarefa..." -ForegroundColor Yellow

$verificacao = schtasks /query /tn "$NomeTarefa" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Tarefa encontrada!" -ForegroundColor Green
    Write-Host ""
    schtasks /query /tn "$NomeTarefa" /fo list | Where-Object { $_ -match "\S" } | Select-Object -First 10
} else {
    Write-Host "  ERRO: $verificacao" -ForegroundColor Red
}
Write-Host ""

# ============================================================
# Testar
# ============================================================
Write-Host "[7] Deseja testar agora? (S/N)" -ForegroundColor Yellow
$resposta = Read-Host

if ($resposta -eq "S" -or $resposta -eq "s") {
    Write-Host ""
    Write-Host "  Executando..." -ForegroundColor Cyan
    schtasks /run /tn "$NomeTarefa"
    Start-Sleep -Seconds 5
    
    # Verificar log
    $logHoje = "C:\scripts\wallpaper\logs\$(Get-Date -Format 'yyyy-MM-dd')_receiver.log"
    if (Test-Path $logHoje) {
        Write-Host ""
        Write-Host "  Ultimas linhas do log:" -ForegroundColor Cyan
        Get-Content $logHoje -Tail 10
    }
}
Write-Host ""

# ============================================================
# Resultado
# ============================================================
Write-Host "============================================" -ForegroundColor Green
Write-Host "       INSTALACAO CONCLUIDA!               " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "A tarefa foi configurada para:" -ForegroundColor Cyan
Write-Host "  - Executar no LOGON de qualquer usuario" -ForegroundColor White
Write-Host "  - Somente quando estiver CONECTADO" -ForegroundColor White
Write-Host "  - Visivel no Agendador para TODOS" -ForegroundColor White
Write-Host ""
Write-Host "Para verificar:" -ForegroundColor Yellow
Write-Host "  1. Abra: taskschd.msc" -ForegroundColor White
Write-Host "  2. Biblioteca do Agendador de Tarefas" -ForegroundColor White
Write-Host "  3. Procure: $NomeTarefa" -ForegroundColor White
Write-Host ""

Read-Host "Pressione Enter para sair"