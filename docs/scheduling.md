# Scheduling Automatic Research Cycles

Run research cycles on a schedule so your feeds update automatically.

## Prerequisites

- Claude Code CLI (`claude`) installed and authenticated
- The project directory with a valid `config.yaml`

## macOS: launchd

Create a plist file at `~/Library/LaunchAgents/com.cc-deepfeed.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cc-deepfeed</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/PATH/TO/cc-deepfeed/run-research.sh</string>
    </array>

    <key>WorkingDirectory</key>
    <string>/PATH/TO/cc-deepfeed</string>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>7</integer>
    </dict>

    <key>ExitTimeOut</key>
    <integer>1800</integer>

    <key>StandardOutPath</key>
    <string>/PATH/TO/cc-deepfeed/.logs/launchd-latest.log</string>
    <key>StandardErrorPath</key>
    <string>/PATH/TO/cc-deepfeed/.logs/launchd-latest.err</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
```

Replace `/PATH/TO/cc-deepfeed` with your actual project path. Make sure the `PATH` includes wherever `claude` is installed (check with `which claude`).

**Important:** The `ExitTimeOut` (30 min) kills the job if it runs too long — this prevents hung workers from blocking indefinitely. The script manages its own dated log files (`.logs/research-YYYY-MM-DD.log`) with 7-day rotation; the `launchd-latest.*` files are only a fallback. On macOS with Homebrew, add `/opt/homebrew/bin` to the PATH for GNU `timeout`.

Load and start:

```bash
launchctl load ~/Library/LaunchAgents/com.cc-deepfeed.plist
```

Unload:

```bash
launchctl unload ~/Library/LaunchAgents/com.cc-deepfeed.plist
```

## Linux: cron

```bash
crontab -e
```

Add:

```
7 9 * * * cd /path/to/cc-deepfeed && bash run-research.sh
```

This runs daily at 9:07 AM. The script manages its own log rotation — no need for shell redirects.

## Windows: Task Scheduler + cycle.ps1

Windows users should use `cycle.ps1` (native PowerShell orchestrator) instead of the bash scripts. It does both research and publish in one go and works without WSL.

### One-time setup

```powershell
# 1. Install Python dependency
pip install -r requirements.txt

# 2. Copy and edit config
Copy-Item config.example.yaml config.yaml
notepad config.yaml   # set base_url to https://<youruser>.github.io/<yourrepo>

# 3. Initialise feed XMLs
python feed.py init

# 4. Run once manually to verify end-to-end (publish included)
.\cycle.ps1
```

After the first run, **activate GitHub Pages** in your repo:
1. Open `https://github.com/<youruser>/<yourrepo>/settings/pages`
2. Source: **Deploy from a branch** → Branch: `gh-pages` / `/(root)` → Save
3. Wait 1–2 min and open `https://<youruser>.github.io/<yourrepo>/`

### Register the daily scheduled task

Run this once in PowerShell (as the regular user, not admin):

```powershell
$repo = "C:\path\to\follow-white-rabbit"

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$repo\cycle.ps1`"" `
    -WorkingDirectory $repo

$trigger = New-ScheduledTaskTrigger -Daily -At 9:00am

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

$task = New-ScheduledTask `
    -Action $action -Trigger $trigger `
    -Settings $settings -Principal $principal `
    -Description "Daily research cycle for follow-white-rabbit"

Register-ScheduledTask -TaskName "follow-white-rabbit-daily" -InputObject $task
```

Verify next run:

```powershell
Get-ScheduledTaskInfo -TaskName "follow-white-rabbit-daily" | Select-Object NextRunTime, LastRunTime, LastTaskResult
```

`StartWhenAvailable` means if the PC was off at 09:00, the task fires when you next log in. The 2 h `ExecutionTimeLimit` is the kill switch in case workers hang.

Disable / re-enable / remove:

```powershell
Disable-ScheduledTask  -TaskName "follow-white-rabbit-daily"
Enable-ScheduledTask   -TaskName "follow-white-rabbit-daily"
Unregister-ScheduledTask -TaskName "follow-white-rabbit-daily" -Confirm:$false
```

### Logs

`cycle.ps1` writes one log per day to `.logs/research-YYYY-MM-DD.log` and prunes anything older than 7 days. Open the latest after each run to confirm all 5 workers finished and the publish step pushed to `gh-pages`.

### Run options

```powershell
.\cycle.ps1                  # full cycle (research + publish), default
.\cycle.ps1 -DryRun          # show what would run, don't spawn workers
.\cycle.ps1 -SkipPublish     # research only, no push to gh-pages
```

## Linux: systemd

Create two files:

**`~/.config/systemd/user/cc-deepfeed.service`**

```ini
[Unit]
Description=cc-deepfeed research cycle

[Service]
Type=oneshot
WorkingDirectory=/path/to/cc-deepfeed
ExecStart=/bin/bash run-research.sh
TimeoutStartSec=1800
```

**`~/.config/systemd/user/cc-deepfeed.timer`**

```ini
[Unit]
Description=Run cc-deepfeed daily

[Timer]
OnCalendar=*-*-* 09:07:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
systemctl --user daemon-reload
systemctl --user enable --now cc-deepfeed.timer
```

Check status:

```bash
systemctl --user status cc-deepfeed.timer
journalctl --user -u cc-deepfeed.service
```

## Manual / One-off

```bash
# Interactive (inside Claude Code)
@research

# Headless
claude -p "@research run the research cycle"

# Single topic
claude -p "@research meta-news"

# Or directly via the bash orchestrator
bash run-research.sh
```
