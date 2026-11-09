@echo off
setlocal EnableExtensions
cd /d "%~dp0"
echo Amazing Maze native ROM build
echo Source: src\maze.asm
echo.
if not exist "src\maze.asm" (
 echo BLOCKED: src\maze.asm has not yet been reconstructed from original Intel 8080 ROMs.
 echo The structural scanner is not a source build.
 exit /b 2
)
if not exist "tools\zmac.exe" (
 echo ERROR: missing bundled tools\zmac.exe
 exit /b 2
)
if not exist "roms" mkdir "roms"
echo [1/4] Assemble native source with bundled zmac
tools\zmac.exe -o src\maze.bin src\maze.asm
if errorlevel 1 exit /b 1
echo [2/4] Verify size and split the image into original 2 KB devices
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $b=[IO.File]::ReadAllBytes('src\maze.bin'); if($b.Length -ne 4096){throw ('Expected 4096 bytes; got '+$b.Length)}; [IO.File]::WriteAllBytes('roms\maze.h', $b[0..2047]); [IO.File]::WriteAllBytes('roms\maze.g', $b[2048..4095])"
if errorlevel 1 exit /b 1
echo [3/4] Verify both generated ROM SHA-1 hashes
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $expected=@{'roms\maze.h'='62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c'; 'roms\maze.g'='893f0a7621e7df19f777be991faff0db4a9ad571'}; foreach($p in $expected.Keys){$h=(Get-FileHash -LiteralPath $p -Algorithm SHA1).Hash.ToLowerInvariant(); Write-Host ($h+'  '+$p); if($h -ne $expected[$p]){throw ('Original SHA-1 mismatch: '+$p)}}"
if errorlevel 1 exit /b 1
echo [4/4] Package source-built MAME set
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; if(Test-Path 'roms\maze.zip'){Remove-Item -Force 'roms\maze.zip'}; Compress-Archive -Path 'roms\maze.h','roms\maze.g' -DestinationPath 'roms\maze.zip'"
if errorlevel 1 exit /b 1
echo PASS: exact original ROM SHA-1s verified.
echo MAME and hardware remain separate gates.
exit /b 0
