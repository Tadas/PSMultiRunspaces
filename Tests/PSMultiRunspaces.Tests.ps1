$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")

Import-Module "$here\..\$sut" -Force

Describe "PSMultiRunspaces" {
	Context "thread management"{
		It "sets up and tears down threads" {
			$RunspaceScript = "TestRunspace-Empty.ps1"
			$WorkerThread = New-WorkerThread -ThreadScript "$here\$RunspaceScript"
			
			Get-Runspace -Name $RunspaceScript | Should Not Be $null
			
			Remove-WorkerThread $WorkerThread
			
			Get-Runspace -Name $RunspaceScript | Should Be $null
		}
	}
	
	Context "no parameters for worker" {
		BeforeEach { # use a script that expects no parameters
			$RunspaceScript = "TestRunspace-Empty.ps1"
			$WorkerThread = New-WorkerThread -ThreadScript "$here\$RunspaceScript"
		}
		AfterEach { # In any case we clean up the runspace
			Remove-WorkerThread $WorkerThread
		}
		
		It "creates a working quit event" {
				$WorkerThread.QuitEvent.GetType().FullName | Should Be "System.Threading.ManualResetEvent"
				
				$MyRunspace = Get-Runspace -Name $RunspaceScript
				$MyRunspace.RunspaceAvailability | Should Be "Busy"
				$WorkerThread.QuitEvent.Set()
				
				# Give 10 seconds for the runspace script to stop
				for ($i = 0; $i -lt 50; $i++) {
					if ($WorkerThread.Job.IsCompleted){
						break
					} else {
						[System.Threading.Thread]::Sleep(200)
					}
				}
				$WorkerThread.Job.IsCompleted | Should Be $true
				$MyRunspace.RunspaceAvailability | Should Be "Available"
		}
		
		It "sets the ScriptRoot path" {
			$WorkerThread.ScriptRoot | Should Be $here
		}
	}
	
	Context "with parameters for worker"{
		It "passes our parameters" {
			$FileName = Join-Path $TestDrive "TestFile-$((Get-Date).ToFileTime()).txt"
			$FileContents = "1234567890"
			$WorkerThread = New-WorkerThread -ThreadScript "$here\TestRunspace-SimpleParam.ps1" `
				-ScriptParameters @{"CustomFileName" = $FileName; "FileContents" = $FileContents }
				
				
			# Give 10 seconds for the runspace script to stop
			for ($i = 0; $i -lt 50; $i++) {
				if ($WorkerThread.Job.IsCompleted){
					break
				} else {
					[System.Threading.Thread]::Sleep(200)
				}
			}
			$WorkerThread.Job.IsCompleted | Should Be $true
			$FileName | Should Exist
			$FileName | Should ContainExactly $FileContents
			
			Remove-WorkerThread $WorkerThread
		}
	}
}
