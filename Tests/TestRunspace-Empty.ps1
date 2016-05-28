while($true){
	if ($PSRunspaceContext.QuitEvent.WaitOne(10)){ break }
}