#
#	查询LBA对应的文件并在桌面生成报告
#
param(
    [switch]$IsRunAsAdmin = $false
)


#要检查的分区
$drive="c:"

#要查询的LBA块，（起始地址，终止地址）
$blocks=(("13091568","13091570"),("13092568","13092568"))

#输出文件名
$filename="output.txt"




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
    
    


    Write-Host "正在获取信息，请稍后..."



    $sb =New-Object System.Text.StringBuilder

    $r=$sb.AppendFormat("获取分区 {0} 信息",$drive)
    $r=$sb.AppendLine()


    $info=fsutil fsinfo ntfsinfo $drive

    $r=$sb.AppendLine($info)
    $r=$sb.AppendLine()

    $Match =$info| Select-String   "每个扇区字节数\W\s*(\d*)" |Select-Object -ExpandProperty "Matches" -First 1|Select-Object -ExpandProperty "Groups" |Select-Object -Skip 1

    #Bytes Per Sector  :               512  扇区大小
    #每个扇区字节数:    
    $sectorsize=512 

    if(-not ($Match -eq $null))
    {
        $sectorsize=[int]$Match.Value
    }


    $Match =$info| Select-String   "每个簇字节数\W\s*(\d*)" |Select-Object -ExpandProperty "Matches" -First 1|Select-Object -ExpandProperty "Groups" |Select-Object -Skip 1

    #Bytes Per Cluster   :               512  扇区大小
    #每个扇区字节数:    
    $clustersize=4096 

    if(-not ($Match -eq $null))
    {
        $clustersize=[int]$Match.Value
    }



    $r=$sb.AppendFormat("提取分区信息结果：每个扇区字节数: {0}  每个簇字节数: {1} ", $sectorsize,$clustersize)
    $r=$sb.AppendLine()




    foreach ($item in $blocks){
        [long]$start,[long]$end = $item


        for ($i = $start; $i -cle $end; $i++)
        { 

            [long]$index= $i /($clustersize / $sectorsize)

            $info=fsutil volume querycluster $drive $index
        
            $r=$sb.AppendFormat("正在查找磁盘块 {0} 对应的逻辑块 {1} 所对应的文件信息：", $i,$index)
        
            #$r=$sb.AppendLine()
            $r=$sb.AppendLine($info)
            #$r=$sb.AppendLine()
            Write-Host "正在查找磁盘块 $i 对应的逻辑块 $index 所对应的文件信息： $info"

        }
    }



    #输出路径
    $path= $desktoppath


    $outputfile= Join-Path -Path $path  -ChildPath $filename


    out-file -FilePath $outputfile -Encoding UTF8 -InputObject $sb.ToString()

    Write-Host "结果已经保存到 $outputfile 中，请查看。"

    pause

	

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
write-Host "==生成报告需要一段时间，请耐心等待报告完成。                            =="
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




