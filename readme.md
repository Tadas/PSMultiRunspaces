# PSMultirunspaces
[![Build status](https://ci.appveyor.com/api/projects/status/hhwxe3um134fvd82?svg=true)](https://ci.appveyor.com/project/Tadas/psmultirunspaces)

Module facilitates creating separate threads (runspaces) from different script files. It is geared towards PowerShell applications with several threads which are working on different tasks ie. GUI thread and a background worker. It is not intended for running a pool of identical workers.

The thread scripts will have a `$PSRunspaceContext` hashtable. The members are:
 - **QuitEvent** - `[System.Threading.ManualResetEvent]` which the thread should monitor to know when to stop.
 - **ScriptRoot** - the full path of the script file. Alternative to $PSScriptRoot.


## Usage

### In the main thread/script
```powershell
$GUIThread = New-WorkerThread -ThreadScript ".\GUI.ps1" -ScriptParameters @{ Logo = "Logo.jpg" }
$NetworkClientThread = New-WorkerThread -ThreadScript ".\NetworkClient.ps1" -ScriptParameters @{ ServerIP = "127.0.0.1"; ServerPort = 31337 }

# Wait for a reason to quit or do something useful here aka. main loop
# ...

# Cleanup the threads
Remove-WorkerThread $GUIThread
Remove-WorkerThread $NetworkClientThread
```
 
### NetworkClient.ps1
```powershell
Param(
	[string]$ServerIP,
	[int]$ServerPort
)

# Connect to a server and do other initialization here...
# ....
# $Server.Connect($ServerIP, $ServerPort);
# ....

while($true){
	# Check for packets here...
	
	<# If something sets our QuitEvent we need to stop. 
	   Sleep 10 ms to avoid busy waiting, remove the delay if this
	   loop has other things to do
	#>
	if ($PSRunspaceContext.QuitEvent.WaitOne(10)){ break }
}
```