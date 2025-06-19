@ECHO OFF
cls
setlocal


:: Create a ESC environment variable containing the escape character
:: See: https://gist.github.com/mlocati/fdabcaeb8071d5c75a2d51712db24011#file-win10colors-cmd
for /F %%a in ('"prompt $E$S & echo on & for %%b in (1) do rem"') do set "ESC=%%a"

echo %ESC%[1mBuild started: %date% %time%%ESC%[0m

md export
bin\PictConv.exe -m1 -f1 -o7 data\sommarhack_multipalette.png export\sommarhack_multipalette.bin

::
:: http://sun.hasenbraten.de/vasm/index.php?view=tutorial
:: http://sun.hasenbraten.de/vasm/release/vasm.html
::
SET ATARIPRG=MixedRez.prg
del %ATARIPRG% 2>NUL
del final\%ATARIPRG%

:: -quiet 
bin\vasm.exe -m68000 -Ftos -noesc -no-opt -o %ATARIPRG% MixedRez.s
IF ERRORLEVEL 1 GOTO ErrorVasm

:: Copy to the emulator folder
copy %ATARIPRG% D:\_emul_\atari\_mount_\DEFENCEF.RCE\MIXEDREZ

:: Copy to the SD Card for the UltraSatan is available
if exist S:\sommarhack\%ATARIPRG% copy %ATARIPRG% S:\sommarhack\%ATARIPRG%


:: UIP setup
:: Launch G:\Network`\uipV310.tos
:: DHCP IP: 192.168.1.128
:: Can browse the disk content on http://192.168.1.128
::
:: uIP-tools documentation on https://bitbucket.org/sqward/uip-tools/src/master/
:: Upload file:    curl -0T filename.tos 192.168.1.1/d/filename.tos
:: Run executable: curl -0 192.168.1.1/c/filename.tos?run="command line"
::
SET ATARIP=192.168.1.128
echo %ESC%[1mUploading Executable to the Atari%ESC%[0m
bin\curl.exe -0T %ATARIPRG% %ATARIP%/g/sommarhk/%ATARIPRG%

echo %ESC%[1mLaunching Executable on the Atari%ESC%[0m
bin\curl.exe -0 %ATARIP%/g/sommarhk/%ATARIPRG%?run="command line"


::pause
goto :End

:ErrorVasm
ECHO. 
ECHO %ESC%[41mAn Error has happened. Build stopped%ESC%[0m
::pause
goto :End


:End
ECHO done

