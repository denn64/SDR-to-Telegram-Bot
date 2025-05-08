# Telegram settings
$BotToken = "TOKEN"
$ChatID = "-ID"
$FolderPath = "C:\Users\miniPC\Desktop\record"
$LogFile = "C:\Users\miniPC\Desktop\SendToTelegram.log"
$TempFile = "C:\Users\miniPC\Desktop\record\temp.wav"

# Ensure log file is accessible
try {
    if (-not (Test-Path $LogFile)) {
        New-Item -Path $LogFile -ItemType File -Force
    }
    Add-Content -Path $LogFile -Value "$(Get-Date): Log file initialized." -ErrorAction Stop
} catch {
    Write-Host "Error accessing log file: $_"
    exit
}

# Verify folder exists
if (-not (Test-Path $FolderPath)) {
    Write-Host "Error: Folder $FolderPath does not exist."
    Add-Content -Path $LogFile -Value "$(Get-Date): Error: Folder $FolderPath does not exist." -ErrorAction Stop
    exit
}

# Track processed files
$ProcessedFiles = @{}

# Start monitoring
Add-Content -Path $LogFile -Value "$(Get-Date): Monitoring started." -ErrorAction Stop
Write-Host "Monitoring folder $FolderPath started. Waiting for new files..."

while ($true) {
    try {
        $Files = Get-ChildItem -Path $FolderPath -Filter "*.wav" -Recurse
        foreach ($File in $Files) {
            $FilePath = $File.FullName
            $FileName = [System.IO.Path]::GetFileName($FilePath)

            # Skip temporaryAudioRecord.wav
            if ($FileName -eq "temporaryAudioRecord.wav") {
                Add-Content -Path $LogFile -Value "$(Get-Date): Skipping temporary file: $FilePath" -ErrorAction Continue
                continue
            }

            if (-not $ProcessedFiles.ContainsKey($FilePath)) {
                Add-Content -Path $LogFile -Value "$(Get-Date): New file: $FilePath" -ErrorAction Continue
                Add-Content -Path $LogFile -Value "$(Get-Date): Waiting 15 seconds before processing..." -ErrorAction Continue
                Start-Sleep -Seconds 15
                
                Add-Content -Path $LogFile -Value "$(Get-Date): Checking file: $FilePath" -ErrorAction Continue
                $FileSize = (Get-Item $FilePath -ErrorAction Stop).Length / 1MB
                if ($FileSize -gt 50) {
                    Add-Content -Path $LogFile -Value "$(Get-Date): File $FileName is too large ($FileSize MB)." -ErrorAction Continue
                    $ProcessedFiles[$FilePath] = $true
                    continue
                }
                if (-not (Test-Path $FilePath -ErrorAction Stop)) {
                    Add-Content -Path $LogFile -Value "$(Get-Date): File $FileName does not exist or is inaccessible." -ErrorAction Continue
                    $ProcessedFiles[$FilePath] = $true
                    continue
                }

                # Check if file is locked
                try {
                    [System.IO.File]::Open($FilePath, 'Open', 'Read', 'None').Close()
                } catch {
                    Add-Content -Path $LogFile -Value "$(Get-Date): File $FileName is locked, will try again later: $_" -ErrorAction Continue
                    continue
                }
                
                # Copy file to temp.wav
                Copy-Item -Path $FilePath -Destination $TempFile -Force -ErrorAction Stop
                Add-Content -Path $LogFile -Value "$(Get-Date): Copied $FilePath to $TempFile" -ErrorAction Continue
                
                $Url = "https://api.telegram.org/bot$BotToken/sendDocument"
                $CurlCommand = "curl.exe -v -F chat_id=$ChatID -F document=@`"$TempFile`" -F caption=`"Recording: $FileName`" $Url"
                Add-Content -Path $LogFile -Value "$(Get-Date): Executing: $CurlCommand" -ErrorAction Continue
                
                $Result = & curl.exe -v -F chat_id=$ChatID -F document=@"$TempFile" -F caption="Recording: $FileName" $Url 2>&1
                $ResultString = $Result -join " "
                Add-Content -Path $LogFile -Value "$(Get-Date): curl result: $ResultString" -ErrorAction Continue
                
                if (Test-Path $TempFile) {
                    Remove-Item $TempFile -Force -ErrorAction Continue
                    Add-Content -Path $LogFile -Value "$(Get-Date): Removed temp file $TempFile" -ErrorAction Continue
                }
                
                if ($ResultString -match '"ok":true') {
                    Add-Content -Path $LogFile -Value "$(Get-Date): File $FileName sent successfully." -ErrorAction Continue
                } else {
                    Add-Content -Path $LogFile -Value "$(Get-Date): Failed to send $FileName. Response: $ResultString" -ErrorAction Continue
                }
                
                $ProcessedFiles[$FilePath] = $true
            }
        }
    } catch {
        Add-Content -Path $LogFile -Value "$(Get-Date): Error in loop: $_" -ErrorAction Continue
    }
    Start-Sleep -Seconds 5
}