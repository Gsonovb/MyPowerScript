function DownloadNuGetPackage
{
    <#
    .Synopsis
       下载 Nuget 包并返回类库路径
    .DESCRIPTION
       下载 Nuget 包并返回类库路径
    .EXAMPLE
       DownloadNuGetPackage -PackageName "HtmlAgilityPack" 
       
    .EXAMPLE
       Import-Module .\DownloadNuGetPackage.psm1
       DownloadNuGetPackage -PackageName "HtmlAgilityPack" -NetVersion Net40 -WorkingDirectory "g:\temp" -Force

    .NOTES
       Copyright  Guanyc  All rights reserved.
    .FUNCTIONALITY
       检查 Nuget 文件是否存在，并使用NuGet.exe 获取 NuGet Gallery 组件包，并返回要加载的类库文件路径。

    .PARAMETER PackageName
        要安装包的名称

    .PARAMETER nugetUrl
        程序的下载连接

    .PARAMETER WorkingDirectory
        工作文件夹 用于保存下载程序包的位置

    .PARAMETER Force
        指示是否强制更新 Nuget 文件

    .PARAMETER NetVersion
        返回 对应 .NET 版本的类库 


    #>

    [CmdletBinding(DefaultParameterSetName="BASE")] #,
    #HelpURI="http://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f")]

    Param
    (
        # 要安装包的名称
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='BASE')]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageName,

        # nuget 程序的下载连接
        [Parameter(ParameterSetName='BASE',Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe",

        #工作文件夹 用于保存下载程序包的位置
        [Parameter(ParameterSetName="BASE")]
        [Alias("WorkDir")]
        [ValidateNotNullOrEmpty()]
        [String]
        $WorkingDirectory = $pwd ,
        
        # 返回 对应 .NET 版本的类库 
        [Parameter(ParameterSetName='BASE')]
        [Alias("NetVer")]
        [String]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Net20","Net40","Net45","NetCore45","All")]
        $NetVersion = "NET45",

        #指示是否强制更新 Nuget 文件
        [Parameter(ParameterSetName="BASE")]
        [Switch]
        $Force = $False

    )

    Begin
    {


    }
    Process
    {
        
        if( -not ([String]::IsNullOrEmpty($WorkingDirectory) )) {
            if( -not (Test-Path -Path $WorkingDirectory)) { $r = md $WorkingDirectory}
            $path = $WorkingDirectory
        }
        elseif(Test-Path -Path $PSScriptRoot){
            $path = $PSScriptRoot
        }
        else{
            $path = Get-Location
        }


        $filename = Join-Path -Path $path -ChildPath "nuget.exe"

        Write-Host "Find Nuget.exe in $path "

 
        $webClient = New-Object System.Net.WebClient 
        
        $r = Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action { Write-Progress -Activity "Downloading:  $($EventArgs.BytesReceived) of $($EventArgs.TotalBytesToReceive) bytes." -PercentComplete $EventArgs.ProgressPercentage;  }    
        $r = Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -SourceIdentifier WebClient.DownloadFileComplete -Action {  Write-Host "Download Complete. ";  }  
        

        if( ( -not (Test-Path -Path $filename)) -or $Force ){
            Write-Host  "Can't Find Nuget.exe, so download it from url $nugetUrl ."  

           
            $webclient.DownloadFileAsync($nugetUrl,$filename)

            do{sleep -Seconds 1 } while ( $webClient.IsBusy)

            write-progress -activity "Downloading Nuget"  -percentcomplete 100 -Completed 
        }
        else{
            Write-Host "Finded Nuget.exe file."
        }
        
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged; Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete; 

        Set-Alias -Name nuget -Value $filename

        cd $path

        $r = nuget install $PackageName

        Write-Host $r

        $packagedir = Get-ChildItem  -Path $path -Directory  |Where-Object -Property Name -Like ("*" + $PackageName + "*") | Select-Object -Last 1

        $matchstr = "\\net"
        
        if( $NetVersion -eq "Net20") {$matchstr = "\\Net20"}
        if( $NetVersion -eq "Net40") {$matchstr = "\\Net40"}
        if( $NetVersion -eq "Net45") {$matchstr = "\\Net45"}
        if( $NetVersion -eq "NetCore45") {$matchstr = "\\NetCore45"}


        $dllfile = Get-ChildItem  -Path $packagedir -Include "*.dll" -Recurse | Where-Object -Property  DirectoryName -Match $matchstr | Select-Object -First 1

        Write-Host "Return File: " $dllfile.FullName
        return $dllfile.FullName


    }
    End
    {
    }

}


