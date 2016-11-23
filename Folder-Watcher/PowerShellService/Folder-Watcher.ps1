function RunService {
	<# This is a possible entry point, for instance when compiling to service with PowerGui #>
	Start-Monitoring -Path "C:\tmp\infiles" -NameFilter "*.*" -IncludeSubdirectories $true
}

function Start-Monitoring {
	Param(
		[Parameter(Mandatory=$True,Position=1)]
		[Alias("Path")]
		[string]$strWatchPath,
		[Parameter(Mandatory=$False,Position=2)]
		[Alias("NameFilter")]
		[string]$strNameFilter = "*.*",
		[Parameter(Mandatory=$False,Position=3)]
		[Alias("IncludeSubdirectories")]
		[bool]$boolIncludeSubdirectories = $false
	)
	. $PSScriptRoot/Common-Functions.ps1
	#. $PSScriptRoot/parts/FileCreated.ps1 #Contains the FileCreatedEvent function
	#. $PSScriptRoot/parts/FileDeleted.ps1 #Contains the FileDeletedEvent function
	#. $PSScriptRoot/parts/FileChanged.ps1 #Contains the FileChangedEvent function
	#. $PSScriptRoot/parts/FileRenamed.ps1 #Contains the FileRenamedEvent function
	
	if((Test-Path $GlobalSecurePasswordFile) -eq $false) {
		LogMessage -Message "The file $GlobalSecurePasswordFile does not exist, it must be created. It should contain a secure string password that goes with the user account defined in $GlobalTransferSettingsFile`n" -Error $true
		LogMessage -Message "This is how you store your password as a secure string: Read-Host -assecurestring | convertfrom-securestring | out-file $GlobalTransferSettingsFile" -Error $true
	} else {
		$transferSettings = Get-Ini -ConfigFilePath $GlobalTransferSettingsFile
		if($transferSettings."[Events]".OnChangedEvent.ToLower() -eq "true") { $OnChangedEvent = $true }
		if($transferSettings."[Events]".OnRenamedEvent.ToLower() -eq "true") { $OnRenamedEvent = $true }
		if($transferSettings."[Events]".OnCreatedEvent.ToLower() -eq "true") { $OnCreatedEvent = $true }
		if($transferSettings."[Events]".OnDeletedEvent.ToLower() -eq "true") { $OnDeletedEvent = $true }
			
		LogMessage -Message "Starting IO.FileSystemWatcher" -SetWhiteHighlighted $true
		if(Test-Path $strWatchPath) {
			$FileSystemWatcher = New-Object IO.FileSystemWatcher $strWatchPath, $strNameFilter -Property @{
				IncludeSubdirectories = $boolIncludeSubdirectories; 
				NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, CreationTime'
			}
			if($FileSystemWatcher) {
				LogMessage -Message "IO.FileSystemWatcher has been detected as started"
			}		
			if($FileSystemWatcher) {
				if($OnCreatedEvent) {
					LogMessage -Message "Registering FileCreated event"
					Register-ObjectEvent $FileSystemWatcher Created -SourceIdentifier FileCreated -Action {
						. $PSScriptRoot/Common-Functions.ps1
						. $PSScriptRoot/parts/FileCreated.ps1 #Contains the FileCreatedEvent function
						$name = $Event.SourceEventArgs.Name
						$fullPath = $Event.SourceEventArgs.FullPath
						$changeType = $Event.SourceEventArgs.ChangeType
						$timeStamp = $Event.TimeGenerated
						LogMessage -Message "The file '$name' was $changeType at $timeStamp"
						FileCreatedEvent -FileName $name -FullPath $fullPath -DateTime $timeStamp
						$transferSettings = Get-Ini -ConfigFilePath $GlobalTransferSettingsFile
						if($transferSettings."[SQLSettings]".UseSQLLogging.ToLower() -eq "true") { $UseSQLLogging = $true }
						if($UseSQLLogging) {
							$nonquerystring = [string]::Format("INSERT INTO change_register (name, change_event, date_registered, fullpath) VALUES ('{0}','{1}',(SELECT SYSDATETIME()),'{2}');", $name, $changeType, $fullPath)	
							DoDBInsert -SQL $nonquerystring
						}
					}
				}
				
				if($OnDeletedEvent) {
					LogMessage -Message "Registering FileDeleted event"
					Register-ObjectEvent $FileSystemWatcher Deleted -SourceIdentifier FileDeleted -Action {
						. $PSScriptRoot/Common-Functions.ps1
						. $PSScriptRoot/parts/FileDeleted.ps1 #Contains the FileDeletedEvent function
						$name = $Event.SourceEventArgs.Name
						$fullPath = $Event.SourceEventArgs.FullPath
						$changeType = $Event.SourceEventArgs.ChangeType
						$timeStamp = $Event.TimeGenerated
						LogMessage -Message "The file '$name' was $changeType at $timeStamp" -Error $true
						FileDeletedEvent -FileName $name -FullPath $fullPath -DateTime $timeStamp
						$transferSettings = Get-Ini -ConfigFilePath $GlobalTransferSettingsFile
						if($transferSettings."[SQLSettings]".UseSQLLogging.ToLower() -eq "true") { $UseSQLLogging = $true }
						if($UseSQLLogging) {
							$nonquerystring = [string]::Format("INSERT INTO change_register (name, change_event, date_registered, fullpath) VALUES ('{0}','{1}',(SELECT SYSDATETIME()),'{2}');", $name, $changeType, $fullPath)	
							DoDBInsert -SQL $nonquerystring
						}
					}
				}

				if($OnChangedEvent) {
					LogMessage -Message "Registering FileChanged event"
					Register-ObjectEvent $FileSystemWatcher Changed -SourceIdentifier FileChanged -Action {
						. $PSScriptRoot/Common-Functions.ps1
						. $PSScriptRoot/parts/FileChanged.ps1 #Contains the FileChangedEvent function
						$name = $Event.SourceEventArgs.Name
						$fullPath = $Event.SourceEventArgs.FullPath
						$changeType = $Event.SourceEventArgs.ChangeType
						$timeStamp = $Event.TimeGenerated
						LogMessage -Message "The file '$name' was $changeType at $timeStamp"
						FileChangedEvent -FileName $name -FullPath $fullPath -DateTime $timeStamp
						$transferSettings = Get-Ini -ConfigFilePath $GlobalTransferSettingsFile
						if($transferSettings."[SQLSettings]".UseSQLLogging.ToLower() -eq "true") { $UseSQLLogging = $true }
						if($UseSQLLogging) {
							$nonquerystring = [string]::Format("INSERT INTO change_register (name, change_event, date_registered, fullpath) VALUES ('{0}','{1}',(SELECT SYSDATETIME()),'{2}');", $name, $changeType, $fullPath)	
							DoDBInsert -SQL $nonquerystring
						}
					}
				}
				
				if($OnRenamedEvent) {
					LogMessage -Message "Registering FileRenamed event"
					Register-ObjectEvent $FileSystemWatcher Renamed -SourceIdentifier FileRenamed -Action {
						. $PSScriptRoot/Common-Functions.ps1
						. $PSScriptRoot/parts/FileRenamed.ps1 #Contains the FileRenamedEvent function
						$name = $Event.SourceEventArgs.Name
						$fullPath = $Event.SourceEventArgs.FullPath
						$changeType = $Event.SourceEventArgs.ChangeType
						$timeStamp = $Event.TimeGenerated
						LogMessage -Message "The file '$name' was $changeType at $timeStamp"
						FileRenamedEvent -FileName $name -FullPath $fullPath -DateTime $timeStamp
						$transferSettings = Get-Ini -ConfigFilePath $GlobalTransferSettingsFile
						if($transferSettings."[SQLSettings]".UseSQLLogging.ToLower() -eq "true") { $UseSQLLogging = $true }
						if($UseSQLLogging) {
							$nonquerystring = [string]::Format("INSERT INTO change_register (name, change_event, date_registered, fullpath) VALUES ('{0}','{1}',(SELECT SYSDATETIME()),'{2}');", $name, $changeType, $fullPath)	
							DoDBInsert -SQL $nonquerystring
						}
					}
				}
			} else {
				LogMessage -Message "Error: The file creation of a watcher object failed, please refer to previous output errors. Aborting script execution!" -Error $true
			}
		} else {
			LogMessage -Message "Error: The watch path does not exist: $strWatchPath. Aborting script execution!" -Error $true
		}	
	}		
}
#This function is not taken in use anywhere, but is supposed to serve as an example:
function Stop-Monitoring {
	Unregister-Event FileDeleted
	Unregister-Event FileCreated
	Unregister-Event FileChanged
	Unregister-Event FileRenamed
}