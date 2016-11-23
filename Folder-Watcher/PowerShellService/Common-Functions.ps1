Set-Variable -name GlobalTransferSettingsFile -value "$PSScriptRoot\transferSettings.ini" -scope global
Set-Variable -name GlobalSecurePasswordFile -value "$PSScriptRoot\securepassword.conf" -scope global

<#
.Synopsis
    Log a message both to the console and to a logfile
.DESCRIPTION
    Reads an ini file and creates an object based on the content of the file. One property per key/value. Sections will be named with surrounding brackets and will contain a list of objects based on the keys within that section.
    Comments will be ignored.

   Created by Atle Holm
   Email: atle@team-holm.net
   Web: http://itblog.team-holm.net
.EXAMPLE
   LogMessage -Messate "Going to work.."
.
.OUTPUTS
   Outputs to console and logfile, default file is execution-result.log
#>
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
		Write-Warning ('Failed to LogMessage "{0}" : {1} in "{2}"' -f $strMessage, $_.Exception.Message, $_.InvocationInfo.ScriptName)
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
	$status = Reset-Log -fileName $strLogFileLocation -filesize 4mb -logcount 10
}

<# 
.Synopsis
	The function is from https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Script-to-Roll-a96ec7d4 
#>
function Reset-Log { 
    #function checks to see if file in question is larger than the paramater specified if it is it will roll a log and delete the oldes log if there are more than x logs. 
    param([string]$fileName, [int64]$filesize = 1mb , [int] $logcount = 5) 
     
    $logRollStatus = $true 
    if(test-path $filename) 
    { 
        $file = Get-ChildItem $filename 
        if((($file).length) -ige $filesize) #this starts the log roll 
        { 
            $fileDir = $file.Directory 
            $fn = $file.name #this gets the name of the file we started with 
            $files = Get-ChildItem $filedir | ?{$_.name -like "$fn*"} | Sort-Object lastwritetime 
            $filefullname = $file.fullname #this gets the fullname of the file we started with 
            #$logcount +=1 #add one to the count as the base file is one more than the count 
            for ($i = ($files.count); $i -gt 0; $i--) 
            {  
                #[int]$fileNumber = ($f).name.Trim($file.name) #gets the current number of the file we are on 
                $files = Get-ChildItem $filedir | ?{$_.name -like "$fn*"} | Sort-Object lastwritetime 
                $operatingFile = $files | ?{($_.name).trim($fn) -eq $i} 
                if ($operatingfile) 
                 {$operatingFilenumber = ($files | ?{($_.name).trim($fn) -eq $i}).name.trim($fn)} 
                else 
                {$operatingFilenumber = $null} 
 
                if(($operatingFilenumber -eq $null) -and ($i -ne 1) -and ($i -lt $logcount)) 
                { 
                    $operatingFilenumber = $i 
                    $newfilename = "$filefullname.$operatingFilenumber" 
                    $operatingFile = $files | ?{($_.name).trim($fn) -eq ($i-1)} 
                    write-host "moving to $newfilename" 
                    move-item ($operatingFile.FullName) -Destination $newfilename -Force 
                } 
                elseif($i -ge $logcount) 
                { 
                    if($operatingFilenumber -eq $null) 
                    {  
                        $operatingFilenumber = $i - 1 
                        $operatingFile = $files | ?{($_.name).trim($fn) -eq $operatingFilenumber} 
                        
                    } 
                    write-host "deleting " ($operatingFile.FullName) 
                    remove-item ($operatingFile.FullName) -Force 
                } 
                elseif($i -eq 1) 
                { 
                    $operatingFilenumber = 1 
                    $newfilename = "$filefullname.$operatingFilenumber" 
                    write-host "moving to $newfilename" 
                    move-item $filefullname -Destination $newfilename -Force 
                } 
                else 
                { 
                    $operatingFilenumber = $i +1  
                    $newfilename = "$filefullname.$operatingFilenumber" 
                    $operatingFile = $files | ?{($_.name).trim($fn) -eq ($i-1)} 
                    write-host "moving to $newfilename" 
                    move-item ($operatingFile.FullName) -Destination $newfilename -Force    
                } 
            }                  
          } else { $logRollStatus = $false} 
    } else { 
        $logrollStatus = $false 
    } 
    $LogRollStatus 
} 

function Test-IfFileLock {
  param (
	[Alias("Path")]
    [parameter(Mandatory=$true)][string]$strPath
  )

  $oFile = New-Object System.IO.FileInfo $strPath

  if ((Test-Path -Path $strPath) -eq $false) {
	LogMessage -Message "Error: $strPath was not found" -Error $true
    return $false
  }

  try {
    $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

    if ($oStream) {
      $oStream.Close()
    }
	LogMessage -Message "$strPath is not locked"
    return $false
  } catch {
	LogMessage -Message "$strPath is locked"
    # file is locked by a process.
    return $true
  }
}
<#
.Synopsis
    Reads an ini file and creates an object based on the content of the file
.DESCRIPTION
    Reads an ini file and creates an object based on the content of the file. One property per key/value. Sections will be named with surrounding brackets and will contain a list of objects based on the keys within that section.
    Comments will be ignored.

   Created by John Roos 
   Email: john@roostech.se
   Web: http://blog.roostech.se
.EXAMPLE
   get-ini -Path "C:\config.ini"

   Opens the file config.ini and creates an object based on that file.
.OUTPUTS
   Outputs an custom object of the type File.Ini
#>
function Get-Ini {
    [CmdletBinding()]
    param(
        # Enter the path for the ini file
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
		[Alias("ConfigFilePath")]
        [string]$Path
    )

    Process{
        if (!(Test-Path $Path)) {
            Write-Error 'Invalid path'
            break
        }

        $iniFile = Get-Content $Path -Verbose:$false
        $currentSection = ''
        $currentKey = ''
        $currentValue = ''
    
        [hashtable]$iniSectionHash = [ordered]@{}
        [hashtable]$iniConfigArray = [ordered]@{}

        foreach ($line in $iniFile) {
            if ( $line.Trim().StartsWith('[') -and $line.EndsWith(']') ) {
                Write-Verbose "Found new section."
                if ($currentSection -ne ''){
                    Write-Verbose "Creating section property based on array:"
                    $keyobj = New-Object PSObject -Property $iniConfigArray
                    $keyobj.PSObject.TypeNames.Insert(0,'File.Ini.Config')
                    $iniSectionHash.Add($currentSection,$keyobj)
                    [hashtable]$iniConfigArray = @{}
                    Write-Verbose "Created section property: $currentSection"
                }
                if ($iniConfigArray.count -gt 0) {
                    $rootSection = $iniConfigArray
                    [hashtable]$iniConfigArray = [ordered]@{}
                }
                $currentSection = $line
                Write-Verbose "Current section: $currentSection"
                continue
            }
            Write-Verbose "Parsing line: $line"
            if ( $line.Contains('=') ){
                $keyvalue = $line.Split('=')
                [string]$currentKey   = $keyvalue[0]
                [string]$currentValue = $keyvalue[1]
                $valuehash = @{
                    $currentKey = $currentValue
                }
                $iniConfigArray.Add($currentKey, $currentValue)
                Write-Verbose "Added keyvalue: $($keyvalue[0]) = $($keyvalue[1])"
            } 
            <# below was for handling comments, but I wont do it...
              elseif ($line.Contains('#') -or $line.Contains(';')) {
                [string]$currentKey   = $line
                [string]$currentValue = ""
                $valuehash = @{
                    $currentKey = $currentValue
                }
                $iniConfigArray.Add($currentKey, $currentValue)
                Write-Verbose "Added comment: $currentKey"
            }#>
        }
        $keyobj = New-Object PSObject -Property $iniConfigArray
        $keyobj.PSObject.TypeNames.Insert(0,'File.ini.Section')
        $iniSectionHash.Add($currentSection,$keyobj)
        Write-Verbose "Created last section property: $currentSection"
        $result = New-Object PSObject -Property $iniSectionHash
        if ($rootSection) {
            foreach ($key in $rootSection.keys){
                Add-Member -InputObject $result -MemberType NoteProperty -Name $key -Value $rootSection.$key
            }
        }
        $result.PSObject.TypeNames.Insert(0,'File.ini')
        Return $result
    }
}
<#
.Synopsis
    Composes an SQL connection string 
.DESCRIPTION
    Read parts for SQL Connection string from configuration file and return an appropriate string

   Created by Atle Holm
   Email: atle@team-holm.net
   Web: http://itblog.team-holm.net
.EXAMPLE
   GetConnectionString
.
.OUTPUTS
   A SQL connection string
#>
function GetConnectionString {
	$transferSettings = Get-Ini -ConfigFilePath $GlobalTransferSettingsFile
	$strSQLUser = $transferSettings."[SQLSettings]".SQLUser
	$strSQLPass = $transferSettings."[SQLSettings]".SQLPass
	$strSQLServer = $transferSettings."[SQLSettings]".SQLServer
	$strSQLCatalog = $transferSettings."[SQLSettings]".SQLCatalog
	$strSQLMDFFile = $transferSettings."[SQLSettings]".SQLMDFFile
	
	$strConnectionstring = "";
	if($strSQLMDFFile) {
		$strConnectionstring =  "Driver={SQL Native Client};Server=.\SQLExpress;AttachDbFilename=" + $strSQLMDFFile + "; Database=dbname;Trusted_Connection=Yes;"
	} elseif ([string]::IsNullOrEmpty($strSQLUser)) {
		$strConnectionstring = "Integrated Security=SSPI; Data Source=" + $strSQLServer + "; Initial Catalog=" + $strSQLCatalog + ";";		
	} else {
		$strConnectionstring = "Integrated Security=False;"
		+ "Data Source=" + $strSQLServer + ";"
		+ "initial catalog=" + $strSQLCatalog + ";"
		+ "User ID=" + $strSQLUser + ";"
		+ "Password=" + $strSQLPass;
	}
	return $strConnectionstring
}
<#
.Synopsis
    Performs a non query database operation
.DESCRIPTION
    Read parts for SQL Connection string from configuration file and return an appropriate string

   Created by Atle Holm
   Email: atle@team-holm.net
   Web: http://itblog.team-holm.net
.EXAMPLE
   DoDBInsert -SQL "INSERT INTO change_register (name, change_event, date_registered, fullpath) VALUES ('file1','Change',(SELECT SYSDATETIME()),'C:\tmp\file1');"
.
.OUTPUTS
   Nothing
#>
function DoDBInsert() {
	param(
		[Parameter(Mandatory = $True, Position = 0)]
		[Alias("SQL")]
		[String]$nonQueryString
	)
	try {
		$strConnectionstring = GetConnectionString
		LogMessage -Message "Attempting to use the following connection string: $strConnectionstring"
		LogMessage -Message "Attempting to use the following SQL string: $nonQueryString"
		$conn = New-Object System.Data.SqlClient.SqlConnection
		$conn.ConnectionString = $strConnectionstring
		$conn.open()
		$cmd = New-Object System.Data.SqlClient.SqlCommand
		$cmd.connection = $conn
		$cmd.commandtext = $nonQueryString
		$cmd.executenonquery()
	$conn.close()
	} catch {
		#Do noting
	}
}