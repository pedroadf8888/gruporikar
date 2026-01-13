# ============================================================
# WallSync SENDER - Upload para GitHub
# ============================================================

Clear-Host
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       WALLSYNC - ENVIAR WALLPAPER         " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# CONFIGURAÇÃO
# ============================================================
$PASTA_ORIGEM = "C:\scripts\wallpaper"
$PASTA_REPO = "C:\scripts\gruporikar"
$ARQUIVO_DESTINO = "C:\scripts\gruporikar\wallpaper.jpg"
$PASTA_BACKUP = "C:\scripts\gruporikar\backup"

# ============================================================
# PASSO 1: Verificar Git
# ============================================================
Write-Host "[PASSO 1] Verificando Git..." -ForegroundColor Yellow

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Host "ERRO: Git nao esta instalado!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}
Write-Host "Git OK" -ForegroundColor Green
Write-Host ""

# ============================================================
# PASSO 2: Verificar/Clonar repositório
# ============================================================
Write-Host "[PASSO 2] Verificando repositorio..." -ForegroundColor Yellow

if (-not (Test-Path $PASTA_REPO)) {
    Write-Host "Clonando repositorio..." -ForegroundColor Cyan
    Set-Location "C:\scripts"
    git clone https://github.com/pedroadf8888/gruporikar.git
}

if (-not (Test-Path $PASTA_REPO)) {
    Write-Host "ERRO: Repositorio nao existe!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "Repositorio OK" -ForegroundColor Green
Write-Host ""

# ============================================================
# PASSO 3: Buscar imagem na pasta de origem
# ============================================================
Write-Host "[PASSO 3] Buscando imagem em $PASTA_ORIGEM ..." -ForegroundColor Yellow

$todosJpg = Get-ChildItem -Path $PASTA_ORIGEM -Filter "*.jpg" -File -ErrorAction SilentlyContinue

if (-not $todosJpg) {
    Write-Host "ERRO: Nenhum arquivo JPG encontrado!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "Arquivos encontrados:" -ForegroundColor Cyan
foreach ($arq in $todosJpg) {
    Write-Host "  - $($arq.Name) | $($arq.Length) bytes" -ForegroundColor White
}

$IMAGEM_ORIGEM = $todosJpg | Sort-Object LastWriteTime -Descending | Select-Object -First 1

Write-Host ""
Write-Host "Selecionado: $($IMAGEM_ORIGEM.Name)" -ForegroundColor Green
Write-Host "Tamanho: $($IMAGEM_ORIGEM.Length) bytes" -ForegroundColor Green
Write-Host "Caminho: $($IMAGEM_ORIGEM.FullName)" -ForegroundColor Green
$TAMANHO_NOVO = $IMAGEM_ORIGEM.Length
$CAMINHO_ORIGEM = $IMAGEM_ORIGEM.FullName
Write-Host ""

# ============================================================
# PASSO 4: LIMPAR repositório local completamente
# ============================================================
Write-Host "[PASSO 4] Limpando repositorio local..." -ForegroundColor Yellow

Set-Location "C:\scripts"

# Deletar pasta do repositório
if (Test-Path $PASTA_REPO) {
    Remove-Item -Path $PASTA_REPO -Recurse -Force
    Write-Host "Repositorio local deletado" -ForegroundColor Green
}

# Aguardar
Start-Sleep -Seconds 2

# Clonar novamente
Write-Host "Clonando repositorio novamente..." -ForegroundColor Cyan
git clone https://github.com/pedroadf8888/gruporikar.git

if (-not (Test-Path $PASTA_REPO)) {
    Write-Host "ERRO: Falha ao clonar!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "Repositorio clonado!" -ForegroundColor Green
Write-Host ""

# Entrar na pasta
Set-Location $PASTA_REPO

# ============================================================
# PASSO 5: Criar pasta de backup
# ============================================================
Write-Host "[PASSO 5] Criando pasta de backup..." -ForegroundColor Yellow

if (-not (Test-Path $PASTA_BACKUP)) {
    New-Item -ItemType Directory -Path $PASTA_BACKUP -Force | Out-Null
}
Write-Host "Pasta backup OK" -ForegroundColor Green
Write-Host ""

# ============================================================
# PASSO 6: Backup do wallpaper atual (se existir)
# ============================================================
Write-Host "[PASSO 6] Verificando backup..." -ForegroundColor Yellow

if (Test-Path $ARQUIVO_DESTINO) {
    $dataBackup = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $arquivoBackup = "$PASTA_BACKUP\wallpaper_$dataBackup.jpg"
    
    Copy-Item -Path $ARQUIVO_DESTINO -Destination $arquivoBackup -Force
    Write-Host "Backup criado: wallpaper_$dataBackup.jpg" -ForegroundColor Green
} else {
    Write-Host "Nenhum wallpaper anterior" -ForegroundColor Cyan
}
Write-Host ""

# ============================================================
# PASSO 7: Deletar wallpaper.jpg do Git
# ============================================================
Write-Host "[PASSO 7] Removendo wallpaper antigo do GitHub..." -ForegroundColor Yellow

# Deletar arquivo do disco
if (Test-Path $ARQUIVO_DESTINO) {
    Remove-Item -Path $ARQUIVO_DESTINO -Force
    Write-Host "Arquivo deletado do disco" -ForegroundColor Green
}

# Remover do Git
git rm -f wallpaper.jpg 2>$null

# Adicionar backup
git add backup/ 2>$null

# Commit
git commit -m "Backup e remocao do wallpaper antigo - $(Get-Date -Format 'HH:mm:ss')" 2>$null

# Push
Write-Host "Enviando remocao para GitHub..." -ForegroundColor Cyan
git push origin main

Write-Host "Remocao enviada!" -ForegroundColor Green
Write-Host ""

# ============================================================
# PASSO 8: Aguardar 5 segundos
# ============================================================
Write-Host "[PASSO 8] Aguardando GitHub processar..." -ForegroundColor Yellow
for ($i = 5; $i -ge 1; $i--) {
    Write-Host "`r  $i... " -NoNewline -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}
Write-Host "`r  OK!   " -ForegroundColor Green
Write-Host ""

# ============================================================
# PASSO 9: Copiar NOVO wallpaper
# ============================================================
Write-Host "[PASSO 9] Copiando novo wallpaper..." -ForegroundColor Yellow
Write-Host "  De: $CAMINHO_ORIGEM" -ForegroundColor White
Write-Host "  Para: $ARQUIVO_DESTINO" -ForegroundColor White

# Copiar
[System.IO.File]::Copy($CAMINHO_ORIGEM, $ARQUIVO_DESTINO, $true)

# Verificar
if (-not (Test-Path $ARQUIVO_DESTINO)) {
    Write-Host "ERRO: Arquivo nao foi copiado!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

$tamanhoCopiado = (Get-Item $ARQUIVO_DESTINO).Length
Write-Host "  Tamanho copiado: $tamanhoCopiado bytes" -ForegroundColor Green

if ($tamanhoCopiado -ne $TAMANHO_NOVO) {
    Write-Host "  AVISO: Tamanho diferente do original!" -ForegroundColor Red
}
Write-Host ""

# ============================================================
# PASSO 10: Adicionar e enviar NOVO wallpaper
# ============================================================
Write-Host "[PASSO 10] Enviando NOVO wallpaper para GitHub..." -ForegroundColor Yellow

git add wallpaper.jpg

Write-Host "Status Git:" -ForegroundColor Cyan
git status --short

git commit -m "Novo wallpaper ($tamanhoCopiado bytes) - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"

Write-Host ""
Write-Host "Enviando..." -ForegroundColor Cyan
git push origin main

Write-Host ""

# ============================================================
# PASSO 11: Verificação final
# ============================================================
Write-Host "[PASSO 11] Verificacao final..." -ForegroundColor Yellow

# Verificar o que está no Git
$gitFiles = git ls-files -s wallpaper.jpg
Write-Host "Git ls-files: $gitFiles" -ForegroundColor Cyan

# Último commit
$ultimoCommit = git log -1 --oneline wallpaper.jpg
Write-Host "Ultimo commit: $ultimoCommit" -ForegroundColor Cyan

Write-Host ""

# ============================================================
# RESULTADO FINAL
# ============================================================
Write-Host "============================================" -ForegroundColor Green
Write-Host "       ENVIADO COM SUCESSO!                " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Arquivo: wallpaper.jpg" -ForegroundColor White
Write-Host "Tamanho: $tamanhoCopiado bytes" -ForegroundColor White
Write-Host ""
Write-Host "Verifique no GitHub:" -ForegroundColor Yellow
Write-Host "https://github.com/pedroadf8888/gruporikar" -ForegroundColor Cyan
Write-Host ""
Write-Host "URL direta:" -ForegroundColor Yellow
Write-Host "https://raw.githubusercontent.com/pedroadf8888/gruporikar/main/wallpaper.jpg" -ForegroundColor Cyan
Write-Host ""

Read-Host "Pressione Enter para sair"