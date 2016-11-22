function FileCreatedEvent {
	param(
		[Parameter(Mandatory = $True, Position = 0)]
		[Alias("Filename")]
		[String]$strFileName,
		[Parameter(Mandatory = $True, Position = 1)]
		[Alias("DateTime")]
		[Datetime]$date,
		[Parameter(Mandatory = $False, Position = 2)]
		[Alias("Message")]
		[String]$strMessage
	)
	<# This is where you do stuff and write your own code #>
}