<#
.Synopsis
   转换VTT字幕到SRT字幕
.DESCRIPTION
   转换VTT字幕到SRT字幕
.EXAMPLE
    .\ConvertVTTtoSRT.ps1 
.EXAMPLE
    .\ConvertVTTtoSRT.ps1 -Path "G:\temp" 
.NOTES
    Copyright  Guanyc All rights reserved.
.FUNCTIONALITY
    搜索指定目标下的VTT文件，读取内容并转换成SRT字幕，然后保存。

.PARAMETER Path
     要查找VTT文件所在的文件夹，默认为当前路径。

.PARAMETER Force
     指示是否覆盖已有字幕文件
#>

[CmdletBinding(DefaultParameterSetName='PS', 
              SupportsShouldProcess=$true, 
              PositionalBinding=$false,
              HelpUri = 'https://github.com/Gsonovb/MyPowerScript/wiki/%E4%B8%8B%E8%BD%BDChannel9%E5%AD%97%E5%B9%95',
              ConfirmImpact='Medium')]
[Alias()]
[OutputType([String])]
Param
(
    [Parameter(ParameterSetName="PS")]
    [Alias("WorkDir")]
    [ValidateNotNullOrEmpty()]
    [String]
    $Path = $pwd ,

    [Parameter(ParameterSetName="PS")]
    [Switch]
    $Force = $False
)
Begin
{}
Process
{
    Write-Host "Find VTT Files in $Path"
    $files = Get-ChildItem -Path  $Path  -Filter "*.vtt" -Recurse

    $progress = 0 
    $pagepercent = 0 
    $entries= $files.Count 

    Write-Host "Find Files Count: $entries"

    $sb = New-Object -TypeName "System.Text.StringBuilder" 

    foreach($file in $files)
    {
        write-progress -activity "Converting ""$file""" -status "$pagepercent% ($progress / $entries) complete" -percentcomplete $pagepercent       
        $saveFileName = [System.IO.Path]::ChangeExtension($file.FullName ,".srt")

        if ( -not ($Force) -and ( Test-Path -Path $saveFileName ) ){ 
            $pagepercent = [Math]::floor((++$progress)/$entries*100) 
            Continue;
        }

        $r=$sb.Clear()
        $lines=Get-Content $file.Fullname -Encoding UTF8
        $i= 0

        for ($index = 0; $index -lt $lines.Count ; $index++){
            $line=$lines[$index]
        
            if([System.String]::IsNullOrEmpty($line)){}
            elseif($line.StartsWith("WEBVTT",[System.StringComparison]::CurrentCultureIgnoreCase)){}
            elseif(($line|Select-String -pattern '\d*:\d*:\d*' | Select-Object  -ExpandProperty  Matches ) -ne $null )
            {
                if($i -gt  0){
                    $r=$sb.AppendLine([System.Environment]::NewLine)
                }

                $r=$sb.AppendLine(++$i)
                $r=$sb.AppendLine($line.Replace(".",","))
            }
            else
            {
                if($line.StartsWith(">>" ,[System.StringComparison]::CurrentCultureIgnoreCase)){
                    $line=$line.Replace(">>","")
                }
                $r=$sb.Append(" ")
                $r=$sb.Append($line)        
            }
        }

        &{#TRY
            Write-Host "Converting ""$file"""
            Out-File -InputObject $sb.ToString() -FilePath $saveFileName -Encoding UTF8
        }
        trap [Exception]{
             write-host
             write-host ("Unable to Convert " + $file.FullName )
             continue; 
        }
        $pagepercent = [Math]::floor((++$progress)/$entries*100) 
    }

    Write-Host "Done."
}
End
{}
