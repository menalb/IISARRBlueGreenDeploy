Write-Host "Warmup"

$URI1 = $homeUrl

$request = [System.Net.WebRequest]::Create($URI1)
$response = $request.GetResponse()
$reqstream = $response.GetResponseStream()
$sr = new-object System.IO.StreamReader $reqstream
$result = $sr.ReadToEnd()
write-host $result