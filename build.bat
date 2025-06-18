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
del MixedRez.prg 2>NUL
del final\MixedRez.prg

:: -quiet 
bin\vasm.exe -m68000 -Ftos -noesc -no-opt -o MixedRez.prg MixedRez.s
IF ERRORLEVEL 1 GOTO ErrorVasm

:: Copy to the emulator folder
copy MixedRez.prg D:\_emul_\atari\_mount_\DEFENCEF.RCE\MIXEDREZ

:: Copy to the SD Card for the UltraSatan is available
if exist S:\sommarhack\MixedRez.prg copy MixedRez.prg S:\sommarhack\MixedRez.prg

::pause
goto :End

:ErrorVasm
ECHO. 
ECHO %ESC%[41mAn Error has happened. Build stopped%ESC%[0m
::pause
goto :End


:End
ECHO done

