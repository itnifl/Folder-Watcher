Function LogMessage {
	param(
		[Parameter(Mandatory = $False, Position = 0)]
		[Alias("Message")]
		[String]$strMessage,
		[Parameter(Mandatory = $False, Position = 1)]
		[Alias("Error")]
		[bool]$boolError,
		[Parameter(Mandatory = $False, Position = 2)]
		[Alias("SetWhiteHighlighted")]
		[bool]$boolSetWhite,
		[Parameter(Mandatory = $False, Position = 3)]
		[Alias("SetLogLocation")]
		[string]$strLogFileLocation = ".\execution-result.log"
	)
	
	if(-Not $strMessage) {
		return "";
	}
	Trap {
		Write-Warning ('Failed to LogAction "{0}" : {1} in "{2}"' -f $strMessage, $_.Exception.Message, $_.InvocationInfo.ScriptName)
		Continue;
	}
	$date = get-date
	if($psversiontable.Psversion.Major -lt 3) {
		if($boolError) { Write-Host -Foregroundcolor Red "$date - $strMessage"}
		elseif($boolSetWhite) { 
			Write-Host "##########################################################"
			Write-Host -Foregroundcolor White "$date - $strMessage"
			Write-Host "##########################################################"
		}
		else { Write-Host -Foregroundcolor Green "$date - $strMessage" }
	} else {
		if($boolError) { echo "$date - $strMessage" | Tee-Object -FilePath $strLogFileLocation -Append | Write-Host -Foregroundcolor Red -Backgroundcolor black }
		elseif($boolSetWhite) { 
			Write-Host "##########################################################"
			echo "$date - $strMessage" | Tee-Object -FilePath $strLogFileLocation -Append | Write-Host -Foregroundcolor White
			Write-Host "##########################################################"
		}
		else { echo "$date - $strMessage" | Tee-Object -FilePath $strLogFileLocation -Append | Write-Host -Foregroundcolor Green }
	}	
}