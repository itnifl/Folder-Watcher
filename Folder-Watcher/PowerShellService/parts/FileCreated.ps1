function FileCreatedEvent {
	param(
		[Parameter(Mandatory = $True, Position = 0)]
		[Alias("Filename")]
		[String]$strFileName,
		[Parameter(Mandatory = $True, Position = 1)]
		[Alias("Fullpath")]
		[String]$strFullPath,
		[Parameter(Mandatory = $True, Position = 2)]
		[Alias("DateTime")]
		[Datetime]$date
	)
	<# This is where you write your code that happens on this event. Remembe that exceptions are not automatically 
	output to the console of this function is running inside an event. Therefore, test the function by itself or manuallu output
	errors to console with Write-Host or LogMessage found in Commom-Functions.ps1 #>
	
	LogMessage -Message "Now performing actions designated for the FileCreatedEvent"
	do {
		LogMessage -Message "Checking if $strFullPath is locked"
		Start-Sleep -s 5
	} while(Test-IfFileLock -Path $strFullPath) 
	LogMessage -Message "Verifying that $strFullPath is not locked"
	if((Test-IfFileLock -Path $strFullPath) -eq $false) {
		$currentFileLocation = $strFullPath | Split-Path -Parent
		$systemBase = $PSScriptRoot | Split-Path -Parent
		#Get Credentials
		LogMessage -Message "Going to read settings from $systemBase\transferSettings.ini"
		$transferSettings = Get-Ini -ConfigFilePath "$systemBase\transferSettings.ini"
		$username = $transferSettings."[Credentials]".Username
		$destination = $transferSettings."[Locations]".Destination
		#$sourcepath = $transferSettings.Get_Item("Sourcepath")
		LogMessage -Message "Received username: $username, source: $strFullPath and destination for file copy is: $destination"
		if((Test-Path "$systemBase\securepassword.conf") -eq $false -and [Environment]::UserInteractive) {
			LogMessage -Message "No secure password found, please enter a password and press enter:"
			Read-Host -assecurestring | convertfrom-securestring | out-file "$systemBase\securepassword.conf"
		}
		$password = cat "$systemBase\securepassword.conf" | convertto-securestring
		$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
		#Map location
		LogMessage -Message "Mapping P to $destination"
		New-PSDrive -Name P -PSProvider FileSystem -Root $destination -Credential $credentials
		#Copy file to location
		LogMessage -Message "Copying $strFullPath to p:\ ($destination)"
		Copy-Item -Path $strFullPath -Destination P:\ -Confirm:$false
		#Log success				
		$transferSettings = Get-Ini -ConfigFilePath $GlobalTransferSettingsFile
		if($transferSettings."[SQLSettings]".UseSQLLogging.ToLower() -eq "true") { $UseSQLLogging = $true }
		if($UseSQLLogging) {
			DoDBInsert -SQL [string]::Format("INSERT INTO filecopy_register (filename, full_source_path, full_destination_path, date_registered, change_event, log_message) VALUES ('{0}','{1}','{2}',(SELECT SYSDATETIME()),'{3}','{4}');", $strFileName, $strFullPath, $destination, "Created", "File was copied to destination P:\")
		} else {
			LogMessage -Message "$strFileName, $strFullPath, $date, File was copied to destination P:\" -SetLogLocation "$currentFileLocation\file-transfer.log"
		}
	}	
}
<#
filename, full_source_path, full_destination_path, date_registered, change_event, log_message
#>