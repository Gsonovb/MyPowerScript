
$dir = get-location

$files= Get-ChildItem -Path  $dir  -Filter "*.vtt" -Recurse

$progress = 0 
$pagepercent = 0 
$entries= $files.Count 


$sb = New-Object -TypeName "System.Text.StringBuilder" 


foreach($file in $files)
{
	     
    write-progress -activity "Converting ""$file""" -status "$pagepercent% ($progress / $entries) complete" -percentcomplete $pagepercent       
	
	$r=$sb.Clear()
	

	$lines=Get-Content $file.Fullname -Encoding UTF8
	
	$i= 0
	

    for ($index = 0; $index -lt $lines.Count ; $index++){
		$line=$lines[$index]
		
		
		if([System.String]::IsNullOrEmpty($line))
		{
		
		}
		elseif($line.StartsWith("WEBVTT",[System.StringComparison]::CurrentCultureIgnoreCase))
		{
		
		}
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
	
	

		
	$saveFileName= [System.IO.Path]::ChangeExtension($file.FullName ,".srt")
	

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
