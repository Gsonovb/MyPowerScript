$regpath="HKLM:\software\microsoft\windows nt\CurrentVersion"
Get-ItemProperty $regpath | Select ProductName,Current*,BuildLab*
pause
