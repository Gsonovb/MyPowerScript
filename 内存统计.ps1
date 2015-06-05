Add-Type @"
using System.Collections.Generic;
  public class DataInfo
{
	public DataInfo()
	{}
	
    public string Name { get; set; }
    public string Company { get; set; }
	public long VirtualMemorySize { get; set; }
	public long PrivateMemorySize { get; set; }
    public long WorkingSet { get; set; }
    public long num { get; set; }


}


"@



$filters=("七星工作室","uChrome Studio","FlashPeak Inc.")


#$filters=("7chrome","chrome","slimjet")




Add-Type -AssemblyName System.Core

$dict =  new-object  "System.Collections.Generic.Dictionary[string,DataInfo]"

$time= [System.DateTime]::Now

$allProcess=Get-Process


foreach($proc in $allProcess )
{
   if($dict.ContainsKey($proc.Name))
   {
        $pinfo= $dict[$proc.Name]
        
        $pinfo.num +=1
        $pinfo.PrivateMemorySize +=$proc.PrivateMemorySize64
        $pinfo.VirtualMemorySize += $proc.VirtualMemorySize64
        $pinfo.WorkingSet += $proc.WorkingSet64
   }
   else
   {
        $pinfo= New-Object "DataInfo"
        $pinfo.Name = $proc.Name
        $pinfo.Company = $proc.Company
        $pinfo.num =1
        $pinfo.PrivateMemorySize =$proc.PrivateMemorySize64
        $pinfo.VirtualMemorySize =$proc.VirtualMemorySize64
        $pinfo.WorkingSet =$proc.WorkingSet64
        
        $dict.Add($proc.Name,$pinfo)

   }

   
}


$titlestr="Time"
$str = "$time"

foreach($f in $filters )
{


    foreach($key in $dict.Keys )
    {
	    $pinfo= $dict[$key]
        if($pinfo.Company -eq $f)
        {
            $titlestr += ",$($pinfo.Name) PrivateMemorySize(GB),$($pinfo.Name) WorkingSet(GB)"
            $str += ",$(($pinfo.PrivateMemorySize)/1GB),$(($pinfo.WorkingSet)/1GB)"        
        }
	   
    }     
        
}


	
$file= Join-Path -ChildPath "ProcessMemory.csv" -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::DesktopDirectory))

if(Test-Path -Path $file)
{

}
else
{
    #添加标题
    Out-File -FilePath $file -InputObject $titlestr  -Encoding utf8 -Append
}

Out-File -FilePath $file -InputObject $str  -Encoding utf8 -Append


