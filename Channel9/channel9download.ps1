#https://github.com/Gsonovb/MyPowerScript


Add-Type -AssemblyName System.Web

$langs = ("en","zh-cn")

$overwrite = $false

$Quality = ("HIGH","MID","LOW")
$VideoType = ("MP4","WMV")


$dir = get-location




$urls=("https://channel9.msdn.com/Series/IntroToAD") #,"https://channel9.msdn.com/Series/ConnectOn-Demand"

$ScriptFileName = "DownloadNuGetPackage.psm1"
$RequesetAssembliy ="HtmlAgilityPack.dll"

$nugetScript = "F:\temp\DownloadNuGetPackage.psm1"


if( [String]::IsNullOrEmpty($PSScriptRoot)){
    $filename = Join-Path -Path $PWD -ChildPath $RequesetAssembliy
}
else
{
    $filename = Join-Path -Path $PSScriptRoot -ChildPath $RequesetAssembliy
}

if(Test-Path -Path $filename){  
}
else
{

    if(Test-Path -Path $nugetScript){
        
    }elseif([String]::IsNullOrEmpty($PSScriptRoot)){
        $nugetScript = Join-Path -Path $PWD -ChildPath $ScriptFileName
    }
    else{
        $nugetScript = Join-Path -Path $PSScriptRoot -ChildPath $ScriptFileName
    }

    if( -not (Test-Path -Path $nugetScript)){  
        #Download script   
    }

    Import-Module  $nugetScript

    $libfile =  DownloadNuGetPackage -PackageName "HtmlAgilityPack" 

    Copy-Item -Path $libfile -Destination $filename  

    $filename = $libfile

}


Add-Type -Path $filename




#清理文件名中的无效字符
function RemoveInvalidChars ($filename)
{
    
    foreach($item in [System.IO.Path]::GetInvalidFileNameChars())
    {
        $filename=$filename.Replace($item ,"_")
    }

    foreach($item in [System.IO.Path]::GetInvalidPathChars())
    {
        $filename=$filename.Replace($item ,"_")
    }
    
    return $filename
}




$htmldoc = New-Object HtmlAgilityPack.HtmlDocument
$webClient = New-Object System.Net.WebClient 
$webClient.Encoding=[System.Text.Encoding]::UTF8




$linkfeeds = New-Object -TypeName System.Collections.ArrayList


#获取所有下载页面的连接
foreach($url in $urls){


    Write-Host "Get  $url ..."

    $pagecontent = $webClient.DownloadString($url)
    $htmldoc.LoadHTML($pagecontent)

    $titlestr  = $htmldoc.DocumentNode.SelectSingleNode("//h1") | Select-Object -ExpandProperty InnerText

    if(-not [string]::IsNullOrEmpty($titlestr)) 
    {
        $title  = [System.Web.HttpUtility]::HtmlDecode($titlestr)
    }


    $baselink = ([System.Uri]$url)

    $links = $htmldoc.DocumentNode.SelectNodes('//a[@class="title"]') |Select-Object -ExpandProperty Attributes | Where-Object -Property Name -EQ "href" | Select-Object -ExpandProperty Value
        
  
    $hasnextpage = $false

    do
    {
        Write-Host "find links Count: " $links.Count
        
        foreach($link in $links)
        {
            $linkurl = New-Object -Typename "System.Uri" ($baselink , [System.Web.HttpUtility]::UrlDecode($link))
    
            $feed = [PSCustomObject][Ordered]@{SerieName = $title;
                                               Url   = $linkurl}

            $r=$linkfeeds.Add($feed)
        }

        
        
        $nextstr = $htmldoc.DocumentNode.SelectSingleNode('//li[@class="next"]/a') |Select-Object -ExpandProperty Attributes | Where-Object -Property Name -EQ "href" | Select-Object -ExpandProperty Value
        
        $hasnextpage = -not [String]::IsNullOrEmpty($nextstr)

        if( $hasnextpage ){

            $nextlink = [System.Web.HttpUtility]::UrlDecode($nextstr)
            $linkurl = New-Object -Typename "System.Uri" ($baselink ,  $nextlink)

            Write-Host "Get Next Page $linkurl ..."


            $pagecontent = $webClient.DownloadString($linkurl)
            $htmldoc.LoadHTML($pagecontent)

            $links = $htmldoc.DocumentNode.SelectNodes('//a[@class="title"]') |Select-Object -ExpandProperty Attributes | Where-Object -Property Name -EQ "href" | Select-Object -ExpandProperty Value
     
        }       

    }
    while ($hasnextpage)
    

}





#要下载连接，以及保存文件名

$downloadfeeds = New-Object -TypeName System.Collections.ArrayList


foreach($lf in $linkfeeds){
    
#    $lf = $linkfeeds[0]

    $url = $lf.Url
        
    Write-Host "Get download links from $url  ..."

    $pagecontent = $webClient.DownloadString($url)
    $htmldoc.LoadHTML($pagecontent)
        
    $titlestr = $htmldoc.DocumentNode.SelectSingleNode("//h1") | Select-Object -ExpandProperty InnerText

    if(-not [string]::IsNullOrEmpty($titlestr)) {
        $title  = [System.Web.HttpUtility]::HtmlDecode($titlestr)
    }

    
    $name=$title.Substring($title.LastIndexOf(":")+1).Trim()
            
    $name = RemoveInvalidChars($name)
        

    $links =  $htmldoc.DocumentNode.SelectNodes('//*[@id="video-download"]/ul/li/div/a') |Select-Object -ExpandProperty Attributes | Where-Object -Property Name -EQ "href" | Select-Object -ExpandProperty Value 

    foreach($vt in $VideoType){
        $parts =  $links | Select-String -Pattern $vt
        
        $link = $null
        
        if([String]::IsNullOrEmpty($link) -and $Quality.Contains("HIGH")){
            $link = $parts | Select-String -Pattern "high|source" | Select-Object -First 1
        }
        if([String]::IsNullOrEmpty($link) -and $Quality.Contains("MID")){
             $link = $parts | Select-String -Pattern "mid|\.wmv" | Select-Object -First 1
        }
        if([String]::IsNullOrEmpty($link) -and $Quality.Contains("LOW")){
             $link = $parts | Select-String -Pattern "\.mp4" | Select-Object -First 1
        }

        if([String]::IsNullOrEmpty($link)){
            Write-Warning "未找到匹配的类型链接"
        }
        else{
             $linkurl = [System.Web.HttpUtility]::UrlDecode($link)
             $filename = $name + [System.IO.Path]::GetExtension($linkurl)
             $feed = [PSCustomObject][Ordered]@{SerieName = $lf.SerieName;
                                                Filename  = $filename;
                                                   Url    = $linkurl;
                                                   Type   = 0 }
             $r=$downloadfeeds.Add($feed)
        }

    }

         
    foreach($lang in $langs)
    {
        $linkurl = $url.ToString() + "/captions?f=webvtt&l=$lang"
        $filename = "$name.$lang.vtt"
        $feed = [PSCustomObject][Ordered]@{SerieName = $lf.SerieName;
                                           Filename  = $filename;
                                              Url    = $linkurl;
                                              Type   = 1 }
        $r=$downloadfeeds.Add($feed)
    }
 
}





#下载文件
$feeds =  $downloadfeeds |Sort-Object –Property Type -Descending



#$webClient = New-Object System.Net.WebClient 
#$webClient.Encoding=[System.Text.Encoding]::UTF8


$entries = $feeds.Length
$progress = 0 
$pagepercent = 0 

#Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged; Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete; 

Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action { Write-Progress -Activity "Downloading:  $($EventArgs.BytesReceived) of $($EventArgs.TotalBytesToReceive) bytes. $($EventArgs.ProgressPercentage)% Completed" -Status $name -PercentComplete $EventArgs.ProgressPercentage -id 10 -ParentId 1;  }    
Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -SourceIdentifier WebClient.DownloadFileComplete -Action {  Write-Host "Download Complete - $name";  }  



foreach ($item in $feeds){
    $serie = RemoveInvalidChars($item.SerieName)
    $name  = $item.Filename
    $link  = $item.Url

    $path = Join-Path -Path $dir -ChildPath $serie

    if(-not (Test-Path $path)){
        $r= md $path
    }
    
    $saveFileName = Join-Path -Path  $path  -ChildPath $name


    if ((-not $overwrite) -and (Test-Path -path $saveFileName))     
    {        
        write-progress -activity "$saveFileName already downloaded" -status "$pagepercent% ($progress / $entries) complete" -percentcomplete $pagepercent    -id 1
    }    
    else     
    {        
        write-progress -activity "Downloading $saveFileName" -status "$pagepercent% ($progress / $entries) complete" -percentcomplete $pagepercent    -Id 1   
        &{#TRY
            
            if ($overwrite -or (-not (Test-Path -Path $saveFileNmae))){
                $webClient.DownloadFileAsync($link, $saveFileName)
            }

            do 
            {
                        sleep -Seconds 5
            } while ( $webClient.IsBusy)
            
            Write-Progress -Activity "Done" -Completed -Id 1
            
        }
        trap [Exception]{
            write-host
            write-host ("Unable to download " + $saveFileName)
            continue; 
        }
    }    
    $pagepercent = [Math]::floor((++$progress)/$entries*100) 
}



 .\ConvertVTTtoSRT.ps1 -Path $dir 

