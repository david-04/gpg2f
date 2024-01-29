# powershell -File ...ps1

Add-Type -AssemblyName System.Windows.Forms
$global:balmsg = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Process -id $pid).Path
$balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
$balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$balmsg.BalloonTipText = "$env:GPG2F_NOTIFICATION_TEXT"
# $balmsg.BalloonTipTitle = "$env:GPG2F_NOTIFICATION_TEXT"
$balmsg.Visible = $true
$balmsg.ShowBalloonTip(20000)
