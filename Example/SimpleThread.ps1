Param(
	$CustomFileName,
	$Delay
)

"Delay for thread $([Threading.Thread]::CurrentThread.ManagedThreadId.ToString()) is $Delay" | Out-File $CustomFileName

"`$PSScriptRoot is '$PSScriptRoot'" | Out-File $CustomFileName -Append
"`$PSRunspaceContext.ScriptRoot is '$($PSRunspaceContext.ScriptRoot)'" | Out-File $CustomFileName -Append

for ($i = 0; $i -lt 20; $i++) {
	"index is $i" | Out-File $CustomFileName -Append
	if ($PSRunspaceContext.QuitEvent.WaitOne($Delay)){
		"Was asked to stop..." | Out-File $CustomFileName -Append
		break
	}
}

"End of thread." | Out-File $CustomFileName -Append