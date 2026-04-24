#!/bin/bash
MESSAGE=$(cat - | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message', 'Claude precisa de você'))" 2>/dev/null || echo "Claude precisa de você")

powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
\$notify = New-Object System.Windows.Forms.NotifyIcon
\$notify.Icon = [System.Drawing.SystemIcons]::Information
\$notify.BalloonTipTitle = 'Claude Code'
\$notify.BalloonTipText = '$MESSAGE'
\$notify.Visible = \$true
\$notify.ShowBalloonTip(5000)
Start-Sleep -Seconds 2
\$notify.Dispose()
"