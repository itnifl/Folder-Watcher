function FileChangedEvent {
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
		
}