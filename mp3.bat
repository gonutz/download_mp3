:: This script takes a URL - either as the parameter or, if no parameter is given,
:: uses the URL from the clipboard - and downloads that video as an mp3 file into
:: the user's Music folder.

@echo off
setlocal

:: Since youtube-dl has an unresolved issue at the time of this writing (April 2023),
:: we use yt-dlp instead.
set ytdl=yt-dlp

:: Do everything in a directory where we have write access.
pushd %APPDATA%

:: Set var "url" to either the first argument or use clipboard content.
set url=%*
if "%~1" == "" (for /f %%i in ('powershell -command "Get-Clipboard"') do set url=%%i)

:: Create a unique temp file name, used multiple times below.
for /f %%# in ('wMIC Path Win32_LocalTime Get /Format:value') do @for /f %%@ in ("%%#") do @set %%@
set tempFile=temp_%day%_%hour%_%minute%_%second%

:: We use Western Europe's code page in case there are Umlauts in the video name.
chcp 1252>NUL

:: Ask the download tool for the video name.
%ytdl% --get-filename --output %%^(title^)s  %url%>%tempFile%
if %errorlevel% neq 0 (del %tempFile% && goto end)
set /p videoName=<%tempFile%
del %tempFile%

:: Ask the user for the file name, using the one provided by the tool as default.
set outputName=%videoName%
echo|set /p=%outputName%|clip
set /p "outputName=Press Ctrl+V and enter file name: "
echo|set /p=%url%|clip
set audioFile=%outputName%.mp3

:: Download the video. This will not actually use tempFile as the file name, it will
:: add an extension, e.g. .mp4 or .webm. Since we do not know which video format is
:: downloaded, we look fore the actual file name afterwards.
%ytdl% --output %tempFile% %url%

:: Look for the actual video file name, we know it starts with our tempFile.
for %%f in (%tempFile%*) do set videoFile=%%f

:: Convert the video to mp3.
ffmpeg -i "%videoFile%" "%audioFile%"
del "%videoFile%"

:: Normalize the audio file, videos have different loudnesses.
normalize "%audioFile%"

:: Copy the file to our user's Music folder.
move "%audioFile%" "%userprofile%\Music\%audioFile%"

:end

popd
