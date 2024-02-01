# powershell -File ...ps1

Add-Type -AssemblyName System.Windows.Forms
$global:balmsg = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Process -id $pid).Path
$balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
$balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$balmsg.BalloonTipText = "$env:NOTIFICATION"
# $balmsg.BalloonTipTitle = "$env:NOTIFICATION"
$balmsg.Visible = $true
$balmsg.ShowBalloonTip(20000)
