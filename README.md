# SDR to Telegram Bot

This PowerShell script automatically sends audio recordings (.wav files) from SDR# to a Telegram channel. It monitors a specified folder, skips temporary files, and uploads completed recordings using the Telegram API.

## Features
- Monitors a folder for new `.wav` files recorded by SDR#.
- Ignores temporary files (`temporaryAudioRecord.wav`) during recording.
- Handles long filenames with spaces, commas, and Cyrillic characters.
- Logs all actions to a file (`SendToTelegram.log`).
- Works on Windows with PowerShell 5.1 or higher.

## Setup and Usage
See [HOWTO.md](HOWTO.md) for detailed setup instructions.

## License
MIT License (feel free to change this).

## Author
Created by [denn64].