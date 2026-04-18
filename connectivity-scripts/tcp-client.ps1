param (
    [Parameter(Mandatory=$true, HelpMessage="Enter the IP or Hostname of the server")]
    [string]$server,

    [Parameter(Mandatory=$true, HelpMessage="Enter the TCP port number")]
    [int]$port
)

# Initialize the TCP Client
$client = New-Object System.Net.Sockets.TcpClient

try {
    Write-Host "Connecting to $server on port $port..." -ForegroundColor Cyan
    $client.Connect($server, $port)

    if ($client.Connected) {
        Write-Host "Connected!" -ForegroundColor Green

        # Get the network stream and create a reader to see the server's message
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)

        # Set a timeout so we don't hang forever if the server doesn't speak
        $stream.ReadTimeout = 5000 

        Write-Host "Waiting for server message..." -ForegroundColor Cyan
        
        # Read the message sent by the server
        $message = $reader.ReadLine()
        
        if ($message) {
            Write-Host "Server says: " -NoNewline -ForegroundColor Green
            Write-Host "$message" -ForegroundColor Yellow
        } else {
            Write-Host "Connected, but the server sent no data." -ForegroundColor DarkGray
        }

        Write-Host "Disconnecting..." -ForegroundColor Cyan
    }
}
catch {
    Write-Host "Failed to connect or read data: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Properly close the stream and the client connection
    if ($null -ne $reader) { $reader.Close() }
    if ($null -ne $client) { $client.Close() }
}