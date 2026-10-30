# Time Clock host. Serves index.html on http://localhost:47653/, stores the data as files under
# %LOCALAPPDATA%\TimeClock, and logs workstation lock/unlock while it runs.
# Runs as a normal user: no admin rights, no install, nothing listens beyond localhost.

$ErrorActionPreference = 'Stop'
$port    = 47653
$url     = "http://localhost:$port/"
$dir     = Join-Path $env:LOCALAPPDATA 'TimeClock'
$page    = Join-Path $PSScriptRoot 'index.html'
$dataFile = Join-Path $dir 'data.json'
$logFile  = Join-Path $dir 'lock-events.csv'

New-Item -ItemType Directory -Force -Path $dir | Out-Null

function Show-Error([string]$message)
{
    Add-Content -Path (Join-Path $dir 'error.log') -Value ('{0}  {1}' -f (Get-Date).ToString('o'), $message)
    (New-Object -ComObject WScript.Shell).Popup($message, 0, 'Time Clock', 16) | Out-Null
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try
{
    $listener.Start()
}
catch
{
    if ($_.Exception.InnerException -and $_.Exception.InnerException.ErrorCode -eq 183)
    {
        Start-Process $url      # already running: just open the page
        exit 0
    }
    Show-Error ("Could not start the local service on port $port.`n" + $_.Exception.Message)
    exit 1
}

$map = @{
    SessionLock       = 'Lock'
    ConsoleDisconnect = 'Lock'
    RemoteDisconnect  = 'Lock'
    SessionLogoff     = 'Lock'
    SessionUnlock     = 'Unlock'
    ConsoleConnect    = 'Unlock'
    RemoteConnect     = 'Unlock'
    SessionLogon      = 'Unlock'
}

function Write-LockEvent([string]$type, [string]$reason)
{
    Add-Content -Path $logFile -Value ('{0},{1},{2}' -f (Get-Date).ToString('o'), $type, $reason) -Encoding UTF8
}

# If the last logged event was a lock (we weren't running at the unlock), close it now so the
# gap isn't counted as locked until the next unlock.
if (Test-Path $logFile)
{
    $last = Get-Content -Path $logFile -Tail 1
    if ($last -and $last.Split(',')[1] -eq 'Lock')
    {
        Write-LockEvent 'Unlock' 'ServiceStart'
    }
}

Register-ObjectEvent -InputObject ([Microsoft.Win32.SystemEvents]) -EventName SessionSwitch -SourceIdentifier TimeClockSession | Out-Null

function Send-Response($ctx, [int]$status, [byte[]]$bytes, [string]$type)
{
    $ctx.Response.StatusCode = $status
    $ctx.Response.ContentType = $type
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
}

function Send-Text($ctx, [int]$status, [string]$text, [string]$type = 'text/plain; charset=utf-8')
{
    Send-Response $ctx $status ([Text.Encoding]::UTF8.GetBytes($text)) $type
}

Start-Process $url
$running = $true

try
{
    while ($running)
    {
        $task = $listener.GetContextAsync()
        while (-not $task.IsCompleted)
        {
            $e = Wait-Event -SourceIdentifier TimeClockSession -Timeout 1
            if ($e)
            {
                $reason = [string]$e.SourceEventArgs.Reason
                Remove-Event -EventIdentifier $e.EventIdentifier
                if ($map.ContainsKey($reason))
                {
                    Write-LockEvent $map[$reason] $reason
                }
            }
        }

        $ctx = $task.Result
        try
        {
            $req = $ctx.Request
            $path = $req.Url.AbsolutePath

            # Reject DNS-rebinding (wrong Host) and cross-site calls (API needs a custom header,
            # which a foreign page cannot send without a CORS preflight we never answer).
            if ($req.Headers['Host'] -ne "localhost:$port")
            {
                Send-Text $ctx 403 'Forbidden'
            }
            elseif ($path -eq '/' -or $path -eq '/index.html')
            {
                Send-Response $ctx 200 ([IO.File]::ReadAllBytes($page)) 'text/html; charset=utf-8'
            }
            elseif ($path.StartsWith('/api/') -and $req.Headers['X-TimeClock'] -ne '1')
            {
                Send-Text $ctx 403 'Forbidden'
            }
            elseif ($path -eq '/api/data' -and $req.HttpMethod -eq 'GET')
            {
                $text = if (Test-Path $dataFile) { [IO.File]::ReadAllText($dataFile) } else { '{}' }
                Send-Text $ctx 200 $text 'application/json; charset=utf-8'
            }
            elseif ($path -eq '/api/data' -and $req.HttpMethod -eq 'PUT')
            {
                $reader = New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)
                $body = $reader.ReadToEnd()
                $null = $body | ConvertFrom-Json        # reject anything that isn't JSON
                if (Test-Path $dataFile)
                {
                    Copy-Item -Path $dataFile -Destination "$dataFile.bak" -Force
                }
                [IO.File]::WriteAllText($dataFile, $body)
                Send-Text $ctx 200 'ok'
            }
            elseif ($path -eq '/api/events' -and $req.HttpMethod -eq 'GET')
            {
                $text = if (Test-Path $logFile) { [IO.File]::ReadAllText($logFile) } else { '' }
                Send-Text $ctx 200 $text
            }
            elseif ($path -eq '/api/quit' -and $req.HttpMethod -eq 'POST')
            {
                Send-Text $ctx 200 'bye'
                $running = $false
            }
            else
            {
                Send-Text $ctx 404 'Not found'
            }
        }
        catch
        {
            try { Send-Text $ctx 500 $_.Exception.Message } catch { }
        }
        finally
        {
            $ctx.Response.Close()
        }
    }
}
finally
{
    Unregister-Event -SourceIdentifier TimeClockSession -ErrorAction SilentlyContinue
    $listener.Stop()
}
