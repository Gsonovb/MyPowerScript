#
#	检查Windows设备电池使用并在桌面生成报告
#

param(
    [switch]$IsRunAsAdmin = $false
)

# Get our script path
$ScriptPath = (Get-Variable MyInvocation).Value.MyCommand.Path


function LaunchElevated
{
    #设置参数
    $RelaunchArgs = '-ExecutionPolicy Unrestricted -file "' + $ScriptPath + '" -IsRunAsAdmin'

    # Launch the process and wait for it to finish
    try
    {
        $AdminProcess = Start-Process "$PsHome\PowerShell.exe" -Verb RunAs -ArgumentList $RelaunchArgs -PassThru
    }
    catch
    {
        $Error[0] # 输出错误
        exit 1
    }


    Start-Sleep -Seconds 3
    
}

function DoElevatedOperations
{
    
    
    cd $desktoppath

    write-Host "正在 分析系统中常见的能量效率和电池使用时间问题 ..."
    POWERCFG /ENERGY

    write-Host "正在 生成电池使用情况的报告 ..."
    POWERCFG /BATTERYREPORT

    write-Host "正在 生成诊断连接待机报告 ..."
    POWERCFG /SLEEPSTUDY
	

}

function DoStandardOperations
{
  
    Write-Host "运行此脚本需要管理员权限，请通过权限！"  -ForegroundColor Red
    write-Host "按Enter 开始检查"

    pause
    
    LaunchElevated
    
   
}


#
#主脚本入口
#


$sfs=Get-ItemProperty  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$desktoppath = $sfs.Desktop

write-Host "=========================================================================="
write-Host "==欢迎使用电源检查脚本。                                                =="
write-Host "==此脚本用于检查Windows设备电池使用并在桌面生成报告。                   =="
write-Host "==生成报告需要一段时间，请等待报告完成后再操作，以免影响结果。          =="
write-Host "=========================================================================="
write-Host 
write-Host "结果将保存到以下位置"
write-Host  $desktoppath


if ($IsRunAsAdmin)
{
    DoElevatedOperations
}
else
{
    DoStandardOperations
}

write-Host "完成"

