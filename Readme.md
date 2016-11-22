FolderWatcher
============

### Note:
This document is in Norewgian. For English version, you could always try translate.google.com. If the result is not understandable, try the simple instructions below. This readme fil will be updated with a full translation later.

--------

#### Simple instructions for C# FolderWatcher:
	1. Copy files to %PROGRAMFILES%\Folder-Watcher or custom folder.
	2. If you want a custom folder, it needs to be specified in 
		HKLM\SOFTWARE\Folder-Watcher with key configSource and with 
	content the full absolute path to mainConfig.xml.
	3. Install the exe as a service this way(requires .Net 4):
		C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\installutil.exe Folder-Watcher.exe
	4. Make sure mainConfig.xml is correctly configured and table in database created as in createRegister.sql.
 
--------
#### Simple instructions for PowerShell FolderWatcher:
	Service can be created by using for instance:
	1. [NSSM] (http://nssm.cc/): 
``` powershell
	Start-Process -FilePath .\nssm.exe -ArgumentList 'install Folder-Watcher "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "-command "& { . C:\ServiceScripts\FolderWatcher.ps1; Start-Monitoring }"" ' -NoNewWindow -Wait
```
	 
	2. [Windows Service Wrapper] (https://github.com/kohsuke/winsw)
	3. [PowerGUI] (https://powershell.org/tag/powergui/) and [Compile as a Service] (https://alistairbmackay.wordpress.com/2015/11/24/run-powershell-code-as-a-windows-service/)

--------
  
#### Norske instruksjoner for C# FolderWatcher:

* Før dette settes opp må .Net 4 være installert på systemet.
* Folder-Watcher.exe, mainConfig.xml, og mainConfig.xsd MÅ plasseres på:
	- sti definert under HKLM\SOFTWARE\Folder-Watcher\configSource i registry.
	- default sti er %PROGRAMFILES%\Folder-Watcher\mainConfig.xml om denne ikke eksisterer
* Service installeres og settes opp slik:  
	Kopier filer til %PROGRAMFILES%\Folder-Watcher
	cd %PROGRAMFILES%\Folder-Watcher
	C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\installutil.exe Folder-Watcher.exe
	Hvis annen sti ønskes, må dette spesifiseres i HKLM\SOFTWARE\Folder-Watcher\configSource
	i registry.
* Folder-Watcher er avhengig av at mainConfig.xml er satt opp rett.   
	Hvis det skal brukes windows credentials for pålogget bruker(antar servicebruker) kan
	man unnlate å spesifisere brukernavn of passord i mainConfig.xml
* Folder watcher avhenger av at databasen som det kobles til er satt opp med tiltenkt tabell
	ved navn register som har struktur slik anvist i vedlagt fil createRegister.sql.
	Tabellen må plasseres i database ved samme navn som spesifisert under
	<SQLCatalog> direktivet i mainConfig.xml.
* Verdt å påpeke:  
	Ønsker man feks en status kolonne i DB med en start verdi(feks 1), kan denne opprettes ved
	feks å lage en kolonne i tabellen med default verdi. Ønsker man å ha en kolonne
	som utgjør en del av en streng kan man lage en kolonne og populere denne med en trigger.

	Hvis <OnChangedMode>, <OnDeletedMode>, <OnCreatedMode> eller <OnRenamedMode> 
	er satt til noe som helst annet enn true (case insensitive),
	vil verdien bli tolket som false og Folder-Watcher vil ikke utføre overvåkning på den hendelsen. De står hendolsvis for change, delete, create, og rename hendelser der det overvåkes og velger om dette skal overvåkes eller ikke.

- Mulige fremtidige forbedringer:  
	Kunne legge til brukernavn og kryptert passord til mainConfig.xml
	Sette opp en installer slik at hele systemet lett kan installeres.

Meld gjerne bugs og ønsker til [atle@team-holm.net](atle@team-holm.net).
	
Atle Holm - 04.11.2012 og 22.11.2016