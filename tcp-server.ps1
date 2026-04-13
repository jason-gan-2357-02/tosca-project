$port = 8080
$endpoint = [System.Net.IPAddress]::Any
$listener = New-Object System.Net.Sockets.TcpListener($endpoint, $port)

try {
    $listener.Start()
    Write-Host "Server is running on port $port. Press Ctrl+C to stop." -ForegroundColor Cyan

    while ($true) {
        if ($listener.Pending()) {
            # Wait for a connection
            $client = $listener.AcceptTcpClient()
            $remoteIp = $client.Client.RemoteEndPoint
            Write-Host "Connection received from $remoteIp at $(Get-Date)" -ForegroundColor Green

            # Optional: Send a quick message to the client
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.WriteLine("You connected successfully to the PowerShell Server.")
            $writer.Flush()

            # Close the connection to this specific client so we can take the next one
            $client.Close()
        } else {
            Start-Sleep -Milliseconds 100
        }
    }
}
catch {
    Write-Error $_.Exception.Message
}
finally {
    # This ensures the port is released even if the script crashes
    $listener.Stop()
    Write-Host "`nServer stopped and port $port released." -ForegroundColor Yellow
}