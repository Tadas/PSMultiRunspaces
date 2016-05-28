function New-WorkerThread {
	Param(
		$ThreadScriptFile,
		[System.Collections.Hashtable]$ScriptParameters = @{}
	)
	$ErrorActionPreference = "Stop"
	
	if (-not(Test-Path -LiteralPath $ThreadScriptFile)) { throw "Worker thread script not found: $ThreadScriptFile" }
	
	
	$ThreadContext  = [PSCustomObject]@{
		PowerShell 	= $null    # PowerShell handle
		Job 		= $null
		
		# The thread should wait on this event to know when to stop
		QuitEvent 	= New-Object System.Threading.ManualResetEvent($false)
		
		# Since we cannot set PSScriptRoot and the script should know where it is running from, we create our own variable for this
		ScriptRoot 	= $(Split-Path -Parent $(Resolve-Path $ThreadScriptFile))
	}
	
	$ThreadScriptBlock = [scriptblock]::Create($(Get-Content (Resolve-Path $ThreadScriptFile) -Raw))
	$ThreadContext.PowerShell = [PowerShell]::Create().AddScript($ThreadScriptBlock).AddParameters($ScriptParameters) # With parameter splatting

	# Inject some context information into the runspace
	$ThreadContext.PowerShell.Runspace.SessionStateProxy.SetVariable('PSRunspaceContext', $ThreadContext)

	$ThreadContext.PowerShell.Runspace.Name = Split-Path -Leaf $ThreadScriptFile

	$ThreadContext.Job = $ThreadContext.PowerShell.BeginInvoke()

	return $ThreadContext
}
Export-ModuleMember New-WorkerThread


function Remove-WorkerThread {
	Param(
		[PSCustomObject]$ThreadContext
	)
	$ThreadContext.PowerShell.Dispose()
}
Export-ModuleMember Remove-WorkerThread