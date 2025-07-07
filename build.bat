@ECHO OFF
cls
setlocal


:: Create a ESC environment variable containing the escape character
:: See: https://gist.github.com/mlocati/fdabcaeb8071d5c75a2d51712db24011#file-win10colors-cmd
for /F %%a in ('"prompt $E$S & echo on & for %%b in (1) do rem"') do set "ESC=%%a"

echo %ESC%[1mBuild started: %date% %time%%ESC%[0m

::ECHO ON
md export
bin\PictConv.exe -m1 -f4 -o7 -p1 data\sommarhack_logo.png export\sommarhack_logo.bin

bin\PictConv.exe -m1 -f2 -o2 data\c64_charset.png export\c64_charset_converted.pi3

bin\PictConv.exe -m1 -f1 -o7 -p1 data\meme.png export\sommarhack_multipalette.bin

:: Distorter images
bin\PictConv.exe -m1 -f1 -o7 -p1 data\sommarhack_multipalette.png export\sommarhack_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 -p1 data\oxygen.png export\oxygen_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 -p1 data\peace.png export\peace_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 -p1 data\nuclear.png export\nuclear_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 -p1 data\tribunal.png export\tribunal_multipalette.bin
bin\PictConv.exe -m1 -f1 -o7 -p1 data\hal9000.png export\hal9000_multipalette.bin

:: News title entries
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_title_placeholder.png export\news_title_placeholder.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_title_breaking_news.png export\news_title_breaking_news.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_title_useful_information.png export\news_title_useful_information.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_title_weather.png export\news_title_weather.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_title_now_playing.png export\news_title_now_playing.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_title_greetings.png export\news_title_greetings.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_title_credits.png export\news_title_credits.bin

:: News content entries
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_content_placeholder.png export\news_content_placeholder.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_content_encounter.png export\news_content_encounter.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_content_mixed_resolution.png export\news_content_mixed_resolution.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_content_weather.png export\news_content_weather.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_content_dbug_attending.png export\news_content_dbug_attending.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_content_music_i_wonder.png export\news_content_music_i_wonder.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_content_greetings.png export\news_content_greetings.bin
bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_content_credits.png export\news_content_credits.bin

bin\PictConv.exe -m1 -f0 -o7 -p1 data\black_ticker.png export\black_ticker.bin

:: Medium resolution content on the right side
bin\PictConv.exe -m1 -f4 -o7 -p1 data\chat_panel.png export\chat_panel.bin
bin\PictConv.exe -m1 -f4 -o7 -p1 data\tvlogo_black.png export\tvlogo_black.bin
bin\PictConv.exe -m1 -f4 -o7 -p1 data\tvlogo_blank.png export\tvlogo_blank.bin
bin\PictConv.exe -m1 -f4 -o7 -p1 data\tvlogo_placeholder.png export\tvlogo_placeholder.bin
bin\PictConv.exe -m1 -f4 -o7 -p1 data\tvlogo_scenesat.png export\tvlogo_scenesat.bin

:: Bottom bar
bin\PictConv.exe -m1 -f0 -o7 -p1 data\sommarhack_tiny_logo.png export\sommarhack_tiny_logo.bin


:: Music
:: Vasm does not like spaces in subexpressions
::bin\SongToAky.exe -reladr --labelPrefix "Main_" -spbyte "dc.b" -spword "dc.w" -sppostlbl ":" -spomt "data\music_intro.aks" "export\music_intro.s"


:: Works: PictConv - Version 1.000 - (Jul  1 2024 / 19:59:32) - This program is a part of the OSDK (http://www.osdk.org)
:: Works: PictConv - Version 1.001 - (Nov 10 2024 / 12:46:04) - This program is a part of the OSDK (http://www.osdk.org)
::bin\PictConv.exe -m1 -f4 -o7 -p1 data\atari_text_640x200.png export\atari_text_640x200.bin
::bin\PictConv.exe -m1 -f0 -o7 -p1 data\news_ticker.png export\news_ticker.bin

:: -m1 -o7 -f4 D:\Git\Sommarhack-2025\data\atari_text_640x200.png D:\Git\Sommarhack-2025\export\atari_text_640x200.bin
:: -m1 -o7 -f1 D:\Git\Sommarhack-2025\data\sommarhack_multipalette.png D:\Git\Sommarhack-2025\export\sommarhack_multipalette.bin

:: -m1 -o7 -f1 D:\Git\Sommarhack-2025\data\sommarhack_multipalette.png D:\Git\Sommarhack-2025\export\sommarhack_multipalette.bin
:: -m1 -f4 -o7 -p1  D:\Git\Sommarhack-2025\data\atari_text_640x200.png D:\Git\Sommarhack-2025\export\atari_text_640x200.bin

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
    echo %ESC%[1mUploading Executable to the Atari to %ATARIP% %ESC%[0m
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

