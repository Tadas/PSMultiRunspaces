Param(
	$CustomFileName,
	$FileContents = "Thread is working!"
)

$FileContents | Out-File $CustomFileName