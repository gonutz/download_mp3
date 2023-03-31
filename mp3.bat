@echo off
setlocal

:: This script takes a URL - either as the parameter or, if no parameter is given,
:: uses the URL from the clipboard - and downloads that video as an mp3 file into
:: the user's Music folder.

:: Do everything in a directory where we have write access.
pushd %APPDATA%

:: Set var "url" to either the first argument or use clipboard content.
set url=%*
if "%~1" == "" (for /f %%i in ('powershell -command "Get-Clipboard"') do set url=%%i)

:: Find the file name that the video will be downloaded to.

:: First create a unique temp file to store the file name.
for /f %%# in ('wMIC Path Win32_LocalTime Get /Format:value') do @for /f %%@ in ("%%#") do @set %%@
set tempFile=temp_%day%_%hour%_%minute%_%second%

:: We use Western Europe's code page in case there are Umlauts in the video name.
chcp 1252>NUL

youtube-dl --get-filename --extract-audio --audio-format mp3 --output %%^(title^)s.mp3  %url%>%tempFile%
if %errorlevel% neq 0 (del %tempFile% && goto end)
set /p audioFile=<%tempFile%
del %tempFile%

:: Ask the user for the file name, using the youtube-dl file as default.
set outputFile=%audioFile%
echo|set /p=%outputFile%|clip
set /p "outputFile=Press Ctrl+V and enter mp3 name: "
echo|set /p=%url%|clip

:: Download the video.
youtube-dl --extract-audio --audio-format mp3 --output %%^(title^)s.mp3  %url%

:: Normalize the audio file, videos have different loudnesses.
normalize "%audioFile%"

:: Copy the file to our user's Music folder.
move "%audioFile%" "%userprofile%\Music\%outputFile%"

:end

popd
