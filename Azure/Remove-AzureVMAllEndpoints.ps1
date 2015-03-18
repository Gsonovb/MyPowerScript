# Arguments.
param 
(
	[Microsoft.WindowsAzure.Commands.ServiceManagement.Model.ServiceOperationContext]$vm = $(throw "'vm' 参数是必须的。")
)


$allendpoints=Get-AzureEndpoint -VM $vm

foreach($ep in $allendpoints)
{
   if( ($ep.Name -ine "Powershell") -and ($ep.Name -ine "Remote Desktop") -and ($ep.Name -ine "SSH"))
   {
     write-host "Deleting EndPoint "$ep.Name
     $r=  Remove-AzureEndpoint -VM $vm -Name $ep.Name
   }
}




# Update VM.
Write-Host -Fore Green "更新 虚机..."
$vm | Update-AzureVM 
Write-Host -Fore Green "完成."