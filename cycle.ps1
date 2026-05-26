# Follow the White Rabbit — orquestador completo (Windows nativo).
#
# Hace todo el ciclo: investigar 5 temas en paralelo + publicar a GitHub Pages.
# Reemplaza run-research.sh + publish.sh sin necesidad de bash/WSL.
#
# Uso manual:
#   .\cycle.ps1                 # ciclo completo (default)
#   .\cycle.ps1 -DryRun         # solo muestra qué haría, sin lanzar workers
#   .\cycle.ps1 -SkipPublish    # investiga pero no publica
#
# Programación: ver GUIA.md sección "Automatización con Task Scheduler"

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipPublish,
    [int]$WorkerTimeoutSeconds = 900
)

$ErrorActionPreference = "Stop"
$ProjectDir = $PSScriptRoot
Set-Location $ProjectDir

# ---------- Logging ----------
$LogsDir = Join-Path $ProjectDir ".logs"
New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
$RunDate = Get-Date -Format "yyyy-MM-dd"
$RunId = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$MainLog = Join-Path $LogsDir "research-$RunDate.log"

function Log {
    param([string]$msg)
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    Write-Host $line
    Add-Content -Path $MainLog -Value $line -Encoding UTF8
}

# Limpia logs viejos (>7 días)
Get-ChildItem $LogsDir -Filter "research-*.log" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
    Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem $LogsDir -Filter "*_round*.log" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

Log "=== Ciclo de research: $RunId ==="

# ---------- Sanity checks ----------
foreach ($cmd in @("python", "claude", "git")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Log "ERROR: '$cmd' no encontrado en PATH. Aborto."
        exit 1
    }
}

if (-not (Test-Path "config.yaml")) {
    Log "ERROR: config.yaml no encontrado en $ProjectDir. Aborto."
    exit 1
}

# ---------- Parsea topics desde config.yaml ----------
$topicsJson = python -c @"
import json, yaml
with open('config.yaml', encoding='utf-8') as f:
    cfg = yaml.safe_load(f)
out = []
for t in cfg.get('topics', []):
    out.append({'id': t['id'], 'target': t.get('target', 0), 'model': t.get('model', 'opus')})
print(json.dumps(out))
"@

if ($LASTEXITCODE -ne 0) {
    Log "ERROR: no pude parsear config.yaml. Aborto."
    exit 1
}

$Topics = $topicsJson | ConvertFrom-Json
Log "Topics a procesar: $($Topics.Count)"
foreach ($t in $Topics) {
    Log "  - $($t.id) (target=$($t.target), model=$($t.model))"
}

if ($DryRun) {
    Log "DRY RUN: termino aquí, no lanzo workers ni publico."
    exit 0
}

# Inicializa feeds (idempotente, crea XMLs que falten)
python feed.py init | Out-Null

# ---------- Ronda de workers ----------
function Spawn-Workers {
    param(
        [string]$RoundName,
        [array]$TopicsToRun  # array de objetos con .id .target .model y .extraPrompt opcional
    )

    $jobs = @()
    foreach ($t in $TopicsToRun) {
        Log "  [$RoundName] $($t.id) target=$($t.target) model=$($t.model)"

        # Recuperar 'recently covered' para evitar duplicados
        $covered = ""
        try {
            $stateOut = python feed.py state $t.id 2>$null
            if ($LASTEXITCODE -eq 0 -and $stateOut) {
                $stateText = $stateOut -join "`n"
                $match = [regex]::Match($stateText, '(?ms)^=== RECENTLY COVERED.*?(?=^===|\z)')
                if ($match.Success) { $covered = $match.Value.Trim() }
            }
        } catch {}

        $prompt = "@research-worker Process topic '$($t.id)' with run-id '$RunId'. Your target is $($t.target) entries."
        if ($covered) {
            $prompt += "`n`n$covered`n`nDo NOT write entries about subjects listed above unless you have genuinely new facts."
        }
        if ($t.extraPrompt) {
            $prompt += "`n`n$($t.extraPrompt)"
        }

        $logFile = Join-Path $LogsDir "$($t.id)_$RoundName.log"

        $job = Start-Job -Name "worker-$($t.id)" -ScriptBlock {
            param($workDir, $model, $prompt, $logFile)
            Set-Location $workDir
            & claude --model $model -p $prompt `
                --allowedTools "WebSearch,WebFetch,Bash,Read,Grep,Glob" `
                --permission-mode dontAsk *>&1 | Tee-Object -FilePath $logFile
            return $LASTEXITCODE
        } -ArgumentList $ProjectDir, $t.model, $prompt, $logFile

        $jobs += [pscustomobject]@{ job = $job; topicId = $t.id; logFile = $logFile }
    }

    Log "  [$RoundName] esperando $($jobs.Count) workers (timeout: ${WorkerTimeoutSeconds}s)..."

    $deadline = (Get-Date).AddSeconds($WorkerTimeoutSeconds)
    foreach ($entry in $jobs) {
        $remaining = [int](($deadline - (Get-Date)).TotalSeconds)
        if ($remaining -lt 1) { $remaining = 1 }
        $finished = Wait-Job -Job $entry.job -Timeout $remaining
        if (-not $finished) {
            Log "  TIMEOUT: $($entry.topicId)"
            Stop-Job -Job $entry.job -ErrorAction SilentlyContinue
        } else {
            $exit = Receive-Job -Job $entry.job -ErrorAction SilentlyContinue
            if ($entry.job.State -eq "Completed") {
                Log "  OK: $($entry.topicId)"
            } else {
                Log "  FAIL: $($entry.topicId) (state=$($entry.job.State))"
            }
        }
        Remove-Job -Job $entry.job -Force -ErrorAction SilentlyContinue
    }
    Log "  [$RoundName] hecho."
}

# ---------- Ronda 1: todos los topics ----------
Log "--- Ronda 1: lanzando todos los workers ---"
$round1 = $Topics | ForEach-Object {
    [pscustomobject]@{ id = $_.id; target = $_.target; model = $_.model; extraPrompt = "" }
}
Spawn-Workers -RoundName "round1" -TopicsToRun $round1

# ---------- Check de targets ----------
Log "--- Comprobando targets ---"
$checkOutput = python feed.py check-targets --run-id $RunId 2>&1
$checkOutput | ForEach-Object { Log $_ }

$shortfallLine = $checkOutput | Where-Object { $_ -match "__SHORTFALLS_JSON__" } | Select-Object -First 1

if ($shortfallLine) {
    $shortfalls = ($shortfallLine -split "__SHORTFALLS_JSON__:")[1] | ConvertFrom-Json
    if ($shortfalls.Count -gt 0) {
        Log "--- Ronda 2: reintentando topics con shortfall ---"
        $topicMap = @{}
        foreach ($t in $Topics) { $topicMap[$t.id] = $t }
        $retry = @()
        foreach ($s in $shortfalls) {
            $base = $topicMap[$s.topic_id]
            $retry += [pscustomobject]@{
                id = $s.topic_id
                target = $s.gap
                model = $base.model
                extraPrompt = "Previous round produced $($s.added)/$($s.target). Try to produce $($s.gap) more entries by searching different sub-topics and broadening scope. Do NOT re-cover subjects already in state. If you cannot find genuinely new subjects after thorough searching, producing fewer is OK."
            }
        }
        Spawn-Workers -RoundName "retry" -TopicsToRun $retry
        Log "--- Check final ---"
        python feed.py check-targets --run-id $RunId 2>&1 | ForEach-Object { Log $_ }
    }
} else {
    Log "Todos los targets se cumplieron en la primera ronda."
}

# ---------- Prune ----------
Log "--- Prune (max 50 entradas/feed) ---"
python feed.py prune --keep 50 | ForEach-Object { Log $_ }

# ---------- Publish ----------
if ($SkipPublish) {
    Log "SKIP: --SkipPublish activo, no publico a gh-pages."
    Log "=== Listo (sin publicar) ==="
    exit 0
}

Log "--- Publicando a gh-pages ---"

$baseUrl = python -c @"
import yaml
with open('config.yaml', encoding='utf-8') as f:
    print(yaml.safe_load(f).get('settings', {}).get('base_url', ''))
"@

if (-not $baseUrl) {
    Log "ERROR: base_url vacío en config.yaml. No publico."
    exit 1
}

# Genera index.html, opml, páginas HTML legibles y archivo cronológico
python feed.py index-html --base-url $baseUrl | Out-Null
python feed.py opml --base-url $baseUrl | Out-Null
python feed.py render-html --base-url $baseUrl | ForEach-Object { Log "  $_" }
python feed.py render-archive --base-url $baseUrl | ForEach-Object { Log "  $_" }

# Lock simple para evitar publishes concurrentes
$LockDir = Join-Path $ProjectDir ".publish.lock"
if (Test-Path $LockDir) {
    Log "WARN: $LockDir ya existe. Otro publish podría estar en curso. Salgo."
    exit 0
}
New-Item -ItemType Directory -Path $LockDir -Force | Out-Null

try {
    $remoteUrl = git remote get-url origin
    $workDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ccfeed-pub-" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
    $cloneDir = Join-Path $workDir "repo"

    $hasGhPages = $true
    & git ls-remote --exit-code --heads $remoteUrl gh-pages 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { $hasGhPages = $false }

    if ($hasGhPages) {
        Log "Clonando rama gh-pages existente..."
        & git clone --depth 1 --single-branch --branch gh-pages $remoteUrl $cloneDir 2>&1 | ForEach-Object { Log "  $_" }
    } else {
        Log "Rama gh-pages no existe en remoto. La creo."
        New-Item -ItemType Directory -Path $cloneDir -Force | Out-Null
        & git -C $cloneDir init 2>&1 | Out-Null
        & git -C $cloneDir remote add origin $remoteUrl
        & git -C $cloneDir checkout --orphan gh-pages 2>&1 | Out-Null
    }

    # Limpia el clone (excepto .git) y copia los feeds nuevos
    Get-ChildItem $cloneDir -Force | Where-Object { $_.Name -ne ".git" } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    $FeedsDir = Join-Path $ProjectDir "feeds"
    Get-ChildItem $FeedsDir -Filter "*.xml" | Copy-Item -Destination $cloneDir -Force
    Get-ChildItem $FeedsDir -Filter "*.html" | Copy-Item -Destination $cloneDir -Force
    Get-ChildItem $FeedsDir -Filter "*.png" -ErrorAction SilentlyContinue | Copy-Item -Destination $cloneDir -Force
    if (Test-Path "$FeedsDir\index.opml") { Copy-Item "$FeedsDir\index.opml" $cloneDir -Force }

    Push-Location $cloneDir
    try {
        & git add -A
        $diff = & git diff --cached --quiet; $hasChanges = ($LASTEXITCODE -ne 0)
        if ($hasChanges) {
            $msg = "Update feeds {0}" -f (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            & git -c user.name="follow-white-rabbit" -c user.email="bot@seoutopico.local" commit -m $msg 2>&1 | ForEach-Object { Log "  $_" }
            & git push origin gh-pages 2>&1 | ForEach-Object { Log "  $_" }
            Log "Publicado a gh-pages."
        } else {
            Log "No hay cambios que publicar."
        }
    } finally {
        Pop-Location
    }

    # Ping WebSub si está configurado
    $websub = python -c @"
import yaml
with open('config.yaml', encoding='utf-8') as f:
    print(yaml.safe_load(f).get('settings', {}).get('websub_hub', ''))
"@

    if ($websub) {
        Log "Pingueando WebSub hub: $websub"
        $xmls = Get-ChildItem $FeedsDir -Filter "*.xml"
        foreach ($x in $xmls) {
            $feedUrl = "$($baseUrl.TrimEnd('/'))/$($x.Name)"
            try {
                $resp = Invoke-WebRequest -Uri $websub -Method Post -Body @{ "hub.mode" = "publish"; "hub.url" = $feedUrl } -UseBasicParsing -TimeoutSec 10
                Log "  OK $($x.Name) ($($resp.StatusCode))"
            } catch {
                Log "  WARN ping falló para $($x.Name): $_"
            }
        }
    }

    Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
} finally {
    Remove-Item $LockDir -Recurse -Force -ErrorAction SilentlyContinue
}

Log "=== Ciclo completo ==="
