@echo off
setlocal
cd /d "%~dp0"
rem Amazing Maze original Intel 8080 ROM build - zmac v1.3; no Python.
if defined ZMAC (
  set "ZMAC_BIN=%ZMAC%"
) else if exist "tools\zmac.exe" (
  set "ZMAC_BIN=tools\zmac.exe"
) else (
  set "ZMAC_BIN=zmac"
)
where "%ZMAC_BIN%" >nul 2>&1
if errorlevel 1 if not exist "%ZMAC_BIN%" (echo ERROR: zmac v1.3 not found.& exit /b 1)
if not exist "src\amazing-maze.asm" (echo ERROR: Missing src\amazing-maze.asm& exit /b 1)
if not exist "roms\original\maze.zip" (echo ERROR: Missing original archive& exit /b 1)
echo Amazing Maze original ROM build
echo [1/4] Prepare output
if not exist build mkdir build
del /q "build\amazing-maze.bin" "build\amazing-maze.lst" "roms\maze.zip" >nul 2>&1
for %%F in (maze.h maze.g) do if exist "build\%%F" del /q "build\%%F"
echo [2/4] Assemble native Intel 8080 source (zmac v1.3)
"%ZMAC_BIN%" -c -o "build\amazing-maze.bin" -x "build\amazing-maze.lst" "src\amazing-maze.asm"
if errorlevel 1 (echo ERROR: Assembly failed.& exit /b 1)
echo [3/4] Split and verify two 2 KB ROMs
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';" ^
 "$bytes=[IO.File]::ReadAllBytes('build\amazing-maze.bin');if($bytes.Length -ne 4096){throw 'Binary image must contain exactly 4096 bytes'};" ^
 "$names=@('maze.h','maze.g');$sha=@('62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c','893f0a7621e7df19f777be991faff0db4a9ad571');" ^
 "for($i=0;$i -lt 2;$i++){ $part=[byte[]]::new(2048);[Array]::Copy($bytes,$i*2048,$part,0,2048);$file=Join-Path 'build' $names[$i];[IO.File]::WriteAllBytes($file,$part);$actual=(Get-FileHash $file -Algorithm SHA1).Hash.ToLowerInvariant();if($actual -ne $sha[$i]){throw ($names[$i]+' SHA1 mismatch: '+$actual)};Write-Host ($names[$i]+' OK '+$actual) }"
if errorlevel 1 (echo ERROR: ROM splitting or verification failed.& exit /b 1)
echo [4/4] Package roms\maze.zip
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';Compress-Archive -LiteralPath @('build\maze.h','build\maze.g') -DestinationPath 'roms\maze.zip' -Force"
if errorlevel 1 (echo ERROR: ROM packaging failed.& exit /b 1)
echo Build complete: roms\maze.zip
exit /b 0
