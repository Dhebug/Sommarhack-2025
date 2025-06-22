@ECHO OFF
cls
setlocal


:: Create a ESC environment variable containing the escape character
:: See: https://gist.github.com/mlocati/fdabcaeb8071d5c75a2d51712db24011#file-win10colors-cmd
for /F %%a in ('"prompt $E$S & echo on & for %%b in (1) do rem"') do set "ESC=%%a"

echo %ESC%[1mBuild started: %date% %time%%ESC%[0m

md export
bin\PictConv.exe -m1 -f1 -o7 data\sommarhack_multipalette.png export\sommarhack_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 data\oxygen.png export\oxygen_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 data\peace.png export\peace_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 data\nuclear.png export\nuclear_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 data\tribunal.png export\tribunal_multipalette.bin
::bin\PictConv.exe -m1 -f1 -o7 data\meme.png export\sommarhack_multipalette.bin

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
:: Launch G:\Network\uipV310.tos
:: DHCP IP: 192.168.1.128
:: Can browse the disk content on http://192.168.1.128
::
:: uIP-tools documentation on https://bitbucket.org/sqward/uip-tools/src/master/
:: Upload file:    curl -0T filename.tos 192.168.1.1/d/filename.tos
:: Run executable: curl -0 192.168.1.1/c/filename.tos?run="command line"
:: curl returns code 0 if the request works
:: curl returns code 2 if the syntax is wrong
:: curl returns code 28 if it could not connect or timed out
::
SET ATARIP=192.168.1.128
SET TIMEOUT=0.5

:: Check if we can access UIP (-s for silent mode, and -m for the timeout value in second)
curl -s -m %TIMEOUT% -0 %ATARIP%/c?dir >nul
if %ERRORLEVEL% equ 0 (
    ECHO.
    echo %ESC%[1mUploading Executable to the Atari%ESC%[0m
    bin\curl.exe -0T %ATARIPRG% %ATARIP%/g/sommarhk/%ATARIPRG%

    ECHO.
    echo %ESC%[1mLaunching Executable on the Atari%ESC%[0m
    bin\curl.exe -0 %ATARIP%/g/sommarhk/%ATARIPRG%?run="command line"
) else ( 
    ECHO.
    ECHO %ESC%[30;43m%ATARIP% is not reachable: The program was not uploaded to the ST%ESC%[0m
    ECHO Make sure that the ST is powered on and that G:\Network\uipV310.tos was launched
    ECHO.
)



::pause
goto :End

:ErrorVasm
ECHO. 
ECHO %ESC%[41mAn Error has happened. Build stopped%ESC%[0m
::pause
goto :End


:End
ECHO done
ECHO.
ECHO.
ECHO.
ECHO.

