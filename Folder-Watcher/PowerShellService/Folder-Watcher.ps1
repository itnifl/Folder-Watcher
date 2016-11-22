function Start-Monitoring {
	Param(
		[Parameter(Mandatory=$True,Position=1)]
		[Alias("Path")]
		$strWatchPath,
		[Parameter(Mandatory=$False,Position=2)]
		[Alias("NameFilter")]
		$strNameFilter = "*.*",
		[Parameter(Mandatory=$False,Position=3)]
		[Alias("IncludeSubdirectories")]
		$boolIncludeSubdirectories = $false
	)
	. ./Common-Functions.ps1
	. ./parts/FileCreated.ps1 #Contains the FileCreatedEvent function
	. ./parts/FileDeleted.ps1 #Contains the FileDeletedEvent function
	. ./parts/FileChanged.ps1 #Contains the FileChangedEvent function
	. ./parts/FileRenamed.ps1 #Contains the FileRenamedEvent function
	LogMessage -Message "Starting IO.FileSystemWatcher" -SetWhiteHighlighted $true
	if(Test-Path $strWatchPath) {
		$FileSystemWatcher = New-Object IO.FileSystemWatcher $strWatchPath, $strNameFilter -Property @{
			IncludeSubdirectories = $boolIncludeSubdirectories; 
			NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, CreationTime'
		}

		if($FileSystemWatcher) {
			Register-ObjectEvent $FileSystemWatcher Created -SourceIdentifier FileCreated -Action {
				$name = $Event.SourceEventArgs.Name
				$changeType = $Event.SourceEventArgs.ChangeType
				$timeStamp = $Event.TimeGenerated
				LogMessage -Message "The file '$name' was $changeType at $timeStamp"
				FileCreatedEvent -FileName $name -DateTime $timeStamp -Message ""
			}

			Register-ObjectEvent $FileSystemWatcher Deleted -SourceIdentifier FileDeleted -Action {
				$name = $Event.SourceEventArgs.Name
				$changeType = $Event.SourceEventArgs.ChangeType
				$timeStamp = $Event.TimeGenerated
				LogMessage -Message "The file '$name' was $changeType at $timeStamp" -Error $true
				FileDeletedEvent -FileName $name -DateTime $timeStamp -Message ""
			}

			Register-ObjectEvent $FileSystemWatcher Changed -SourceIdentifier FileChanged -Action {
				$name = $Event.SourceEventArgs.Name
				$changeType = $Event.SourceEventArgs.ChangeType
				$timeStamp = $Event.TimeGenerated
				LogMessage -Message "The file '$name' was $changeType at $timeStamp"
				FileChangedEvent -FileName $name -DateTime $timeStamp -Message ""
			}
			
			Register-ObjectEvent $FileSystemWatcher Renamed -SourceIdentifier FileRenamed -Action {
				$name = $Event.SourceEventArgs.Name
				$changeType = $Event.SourceEventArgs.ChangeType
				$timeStamp = $Event.TimeGenerated
				LogMessage -Message "The file '$name' was $changeType at $timeStamp"
				FileRenamedEvent -FileName $name -DateTime $timeStamp -Message ""
			}
		} else {
			LogMessage -Message "Error: The file creation of a watcher object failed, please refer to previous output errors. Aborting script execution!" -Error $true
		}
	} else {
		LogMessage -Message "Error: The watch path does not exist: $strWatchPath. Aborting script execution!" -Error $true
	}		
}
function Start-Monitoring {
	Unregister-Event FileDeleted
	Unregister-Event FileCreated
	Unregister-Event FileChanged
	Unregister-Event FileRenamed
}