Import-Module ..\PSMultiRunspaces.psm1

Write-Host "Starting thread one..."
$FileOne = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\File1.txt")
$ThreadOne = New-WorkerThread -ThreadScript ".\SimpleThread.ps1" -ScriptParameters @{"CustomFileName" = $FileOne; Delay = 100}


Write-Host "Starting thread two..."
$FileTwo = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\File2.txt")
$ThreadTwo = New-WorkerThread -ThreadScript ".\SimpleThread.ps1" -ScriptParameters @{"CustomFileName" =  $FileTwo; Delay = 1100}


# Here we can do whatever we want while waiting for the threads to do their thing
Write-Host "Press Q to stop waiting..."
while ($true){
	if ([Console]::KeyAvailable){
		if([System.Console]::ReadKey().key -eq "Q") {
			[void]$ThreadOne.QuitEvent.Set()
			[void]$ThreadTwo.QuitEvent.Set()
			break
		}
	}
	# Don't run this thread too often so we don't waste CPU cycles
	[System.Threading.Thread]::Sleep(200)
}


# Start shutting down
# First we wait for the threads to stop - we could get stuck if thread does not close
Write-Host "Waiting for thread one to stop..."
while(-not($ThreadOne.Job.IsCompleted)){ [System.Threading.Thread]::Sleep(200) }

Write-Host "Waiting for thread two to stop..."
while(-not($ThreadTwo.Job.IsCompleted)){ [System.Threading.Thread]::Sleep(200) }

# Dispose of the threads, let's not waste resources
Write-Host "Cleaning up..."
Remove-WorkerThread $ThreadOne
Remove-WorkerThread $ThreadTwo

Write-Host "Done!"