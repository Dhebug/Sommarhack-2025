;
;                Mixed Results
; Dbug's Mixed Resolution intro for Sommarhack 2025
;
; https://sommarhack.se/2025/compo.php
;
; 1. Mixed-resolution demo
;
; Make a demo where all parts of the demo features a split of the visible screen, one portion of the screen being in low resolution and the other in medium resolution. 
; Both resolutions must be clearly visible simultaneously in all parts. 
; You can have several changes in resolution on the screen.
;
; Retro Adventurers podcast
;
; Rules:
; Atari STE
; Color monitor
; 1 MB RAM
; Floppydisk or harddrive
; More than one entry per participant/crew allowed;
;
; Useful tool: http://tool.anides.de
;
; https://temlib.org/AtariForumWiki/index.php/Atari_ST/STe/MSTe/TT/F030_Hardware_Register_Listing
; https://beyondbrown.mooo.com/post/hardware-register-listing-8.6/
;
; $FF8201|byte |Video screen memory position (High byte)             |R/W
; $FF8203|byte |Video screen memory position (Mid byte)              |R/W
; $FF820D|byte |Video screen memory position (Low byte)              |R/W  (STe)
; 
; $FF8205|byte |Video address pointer (High byte)                    |R (R/W STe)
; $FF8207|byte |Video address pointer (Mid byte)                     |R (R/W STe)
; $FF8209|byte |Video address pointer (Low byte)                     |R (R/W STe)
; $FF820A|byte |Video synchronization mode                    BIT 1 0|R/W
; $FF820B|byte 
; $FF8264|byte |Horizontal scroll register without prefetch (0-15)   |R/W  (STe)
; $FF8265|byte |Horizontal scroll register with prefetch (0-15)      |R/W  (STe)

enable_music  		equ 1

enable_intro        equ 1
enable_intro2       equ 1
enable_test_scroll  equ 1
enable_wtf_intro    equ 1
enable_political    equ 1

alignment_marker 	equ $001     ; Green


KEY_SPACE	 		equ $39 
KEY_ARROW_LEFT		equ $4b
KEY_ARROW_RIGHT 	equ $4d
KEY_ARROW_UP    	equ $48
KEY_ARROW_DOWN  	equ $50
KEY_ARROW_INSERT  	equ $52
KEY_ARROW_CLRHOME 	equ $47
KEY_ARROW_HELP  	equ $62
KEY_ARROW_UNDO  	equ $61

dbra_time       	equ 4
dbra_time_loop  	equ 3


; MARK: Macros
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;% Macro qui fait une attente soit avec une succession de NOPs %
;% (FAST=1), soit en optimisant avec des instructions neutres  %
;% prenant plus de temps machine avec la mˆme taille	       %
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 ifne 0
pause macro
t6 set (\1)/6
t5 set (\1-t6*6)/5
t4 set (\1-t6*6-t5*5)/4
t3 set (\1-t6*6-t5*5-t4*4)/3
t2 set (\1-t6*6-t5*5-t4*4-t3*3)/2
t1 set (\1-t6*6-t5*5-t4*4-t3*3-t2*2)
	dcb.w t6,$e188  ; lsl.l #8,d0        6
	dcb.w t5,$ed88  ; lsl.l #6,d0        5
	dcb.w t4,$e988  ; lsl.l #4,d0        4
	dcb.w t3,$1090  ; move.b (a0),(a0)   3
	dcb.w t2,$8080  ; or.l d0,d0         2
	dcb.w t1,$4e71  ; nop                1
	endm
   endc

pause macro		; Fast mode 
delay set (\1)
 ifne delay<9
t4 set (delay)/5
t3 set (delay-t4*5)/3
;t2 set (delay-t4*5-t3*3)/2
t1 set (delay-t4*5-t3*3)
  dcb.w t4,$2e97  ; move.l (a7),(a7)  20/5
  dcb.w t3,$1e97  ; move.b (a7),(a7)  12/3
  ;dcb.w t2,$8080  ; or.l d0,d0         8/2
  dcb.w t1,$4e71  ; nop                4/1
 else 
  ifne delay>100
   fail delay
  else
   jsr EndNopTable-2*(delay-9)
  endc
 endc
 endm


; 1=filename
; 2=start label
; 3=end label (optional)
FILE macro
	even
\2
	incbin \1
	ifne NARG-3
\3
	endc
	even
	endm



; MARK: Defines
SET_NEWS_TITLE macro
	move.l #\1,news_title_palette
	move.l #\1+32,news_title_bitmap
	endm


SET_NEWS_CONTENT macro
	move.l #\1,news_content_palette
	move.l #\1+32,news_content_bitmap
	endm

SET_CHANNEL_LOGO macro
	lea \1+8,a0
	jsr PatchChannelLogo
	endm

SET_BOTTOM_LOGO macro
	lea \1+32,a0
	jsr PatchBottomLogo
	endm

SET_EFFECT_CALLBACK macro 
	move.l #\1,_patch_update
	endm 

SET_EFFECT_IMAGE macro
	move.l #\1,displayList_image
	endm


PRINT_AI_MESSAGE macro
	move.l #DoNothing,PrintMessageCallback
	move.l #\1,message_source_ptr
	jsr PrintMessage2
	endm


PRINT_USER_MESSAGE macro
	move.l #SlowClick,PrintMessageCallback
	move.l #\1,message_source_ptr
	jsr PrintMessage2
	endm

; PLAY_MUSIC file,tune
PLAY_MUSIC macro
 ifne enable_music
	move.l #\1,a0                       ; File 
	moveq #\2,d0             			; Subtune number (1 is the first song)
	jsr SetCurrentMusic
  endc
	endm


WAIT macro
	move.w #\1,d0
	jsr WaitDelay
	endm

WAIT_VBL macro
	jsr WaitVbl
	endm

STOP_HERE macro 
	jsr StopHere
	endm


 SECTION TEXT
  

; ------------------
;  MARK: Program start
; ------------------
ProgStart 
 	; We call the main routine in supervisor mode and when we come back, we return to the caller 
	move.l #SuperMain,-(sp)
	move.w #$26,-(sp)         ; XBIOS: SUPEXEC
	trap #14
	addq.w #6,sp

	clr.w -(sp)               ; GEMDOS: PTERM(0)
	trap #1


;
; This machine is not a STE/MSTE (Should check monochrome as well)
;
UnsupportedMachine
	pea NotASteMessage
	move #9,-(sp)
	trap #1
	addq #6,sp

	; wait key
	move #7,-(sp)
	trap #1
	addq #2,sp
	rts

; jsr abs.l => 20/5 cycles 
; jsr EndNopTable + rts = 5+4=9 nops
NopTable
 	dcb.w 100,$4e71		; 4/1   x100
EndNopTable 
	rts					; 16/4

DummyHbl
	rte

DoNothing
	rts

SuperMain
	move.l sp,usp               ; Save the stack pointer

	;
	; This has to be done first, else we will lose data
	; We need to start by clearing the BSS in case of some packer let some crap
	;
	lea bss_start,a0					
	lea bss_end,a1 
	moveq #0,d0
.loop_clear_bss
	move.l d0,(a0)+
	cmp.l a1,a0
	ble.s .loop_clear_bss

	;
	; We need to know on which machine we are running the intro.
	; We accept STE and MegaSTE as valid machines.
	; Anything else will have a nice message telling them to "upgrade" or use an emulator :)
	;
	move.l $5a0.w,d0
	beq UnsupportedMachine		; No cookie, this is definitely not a STe or MegaSTe

	sf machine_is_ste
	sf machine_is_megaste

	move.l	d0,a0
.loop_cookie	
	move.l (a0)+,d0			; Cookie descriptor
	beq UnsupportedMachine
	move.l (a0)+,d1			; Cookie value
	
	cmp.l #"CT60",d0
	beq UnsupportedMachine	; We do not run on Falcon, accelerated or not
	cmp.l #"_MCH",d0
	bne.s .loop_cookie
	
.found_machine	
	cmp.l #$00010010,d1
	beq.s .found_mste
	sf.b d1
	cmp.l #$00010000,d1
	beq.s .found_ste
	bra UnsupportedMachine	; We do not run on TT

.found_mste
	st machine_is_megaste 
.found_ste 
	st machine_is_ste
	
	move.b $ffff8260.w,d0
	and.b #2,d0
	bne UnsupportedMachine      ; We cannot run in high resolution
			
	; Proper start			
	move.w #$2700,sr
	bsr SaveSettings
	bsr Initialization

	; Main demo
	jsr DemoSequence

;.loop_forever
	;bra.s	.loop_forever		; infinite wait loop
exit                            ; We actual come back here from anywhere, including IRQs
  ifne enable_music
  	jsr StopMusic               ; Stop the current music and silence the YM if necessary
  endc

	move.w #$2700,sr            ; We just don't care, just restore the stack pointer and we are all good
	move.l usp,sp				; Restore the stack pointer
	bsr RestoreSettings
	move.w #$2300,sr
	rts

; MARK: Save/Restore
SaveSettings
	lea settings,a0
	movem.l $ffff8240.w,d1-d7/a1 
	movem.l d1-d7/a1,(a0)       ; palette
	lea 32(a0),a0
	move.l	$68.w,(a0)+         ; hbl
	move.l	$70.w,(a0)+         ; vbl
	move.l	$120.w,(a0)+        ; timer B
	move.l	$134.w,(a0)+        ; timer A
	move.l	$ffff8200.w,(a0)+   ; screen
	move.b	$ffff820a.w,(a0)+   ; freq
	move.b	$ffff8260.w,(a0)+   ; rez
	move.b	$ffff8265.w,(a0)+   ; horizontal scroll
	move.b	$fffffa07.w,(a0)+   ; iera
	move.b	$fffffa09.w,(a0)+   ; ierb
	move.b	$fffffa19.w,(a0)+   ; tacr
	move.b	$fffffa1b.w,(a0)+   ; tbcr

	tst.b machine_is_megaste
	beq.s .end_megaste
	move.b $ffff8e21.w,(a0)+ 	; On mste we need to save the cache value and force to 8mhz
	move.b #%00,$ffff8e21.w	    ; 8mhz without cache
.end_megaste

	rts


RestoreSettings
	lea settings,a0
	movem.l (a0)+,d1-d7/a1      ; palette
	movem.l d1-d7/a1,$ffff8240.w
	move.l	(a0)+,$68.w         ; hbl
	move.l	(a0)+,$70.w         ; vbl
	move.l	(a0)+,$120.w        ; timer B
	move.l	(a0)+,$134.w        ; timer A
	move.l	(a0)+,$ffff8200.w   ; screen
	move.b	(a0)+,$ffff820a.w   ; freq   
	move.b	(a0)+,$ffff8260.w   ; rez
	move.b	(a0)+,$ffff8265.w   ; horizontal scroll
	move.b	(a0)+,$fffffa07.w   ; iera
	move.b	(a0)+,$fffffa09.w   ; ierb
	move.b	(a0)+,$fffffa19.w   ; tacr
	move.b	(a0)+,$fffffa1b.w   ; tbcr

	tst.b machine_is_megaste
	beq.s .end_megaste
	move.b (a0)+,$ffff8e21.w	; Restore mste frequency and cache status
.end_megaste
	rts


YmSilent
	move.b #8,$ffff8800.w		; Volume register 0
	move.b #0,$ffff8802.w      	; Null volume
	move.b #9,$ffff8800.w		; Volume register 1
	move.b #0,$ffff8802.w      	; Null volume
	move.b #10,$ffff8800.w		; Volume register 2
	move.b #0,$ffff8802.w      	; Null volume
	rts


; MARK: Initialization
Initialization
	; Point the screen to the big buffer
	lea $ffff8201.w,a0               	; Screen base pointeur (STF/E)
	move.l #screen_buffer+256,d0
	clr.b d0
	lsr.l #8,d0					        ; Allign adress on a byte boudary for STF compatibility
	movep.w d0,0(a0) 
	sf.b 12(a0)					        ; For STE low byte to 0

	; Set the palette to black
	movem.l	black_palette,d0-d7
	movem.l	d0-d7,$ffff8240.w

	; And force the display list to point to nothing
	lea black_palette,a0 			; 100% black palette
	jsr InitializeEmptyDisplayList
	jsr InitializeSineOffsets

	;lea tvlogo_black+8,a0
	;lea tvlogo_placeholder+8,a0
	;lea tvlogo_scenesat+8,a0
	;jsr PatchChannelLogo
	SET_CHANNEL_LOGO tvlogo_black


	; Depack samples
	; Keyclick
	lea packed_chatroom_sample_start,a0
	lea chatroom_sample_start,a1
	move.l #packed_chatroom_sample_end-packed_chatroom_sample_start,d0
	jsr DepackDelta


	; Set the current image
	move.l #sommarhack_multipalette,CurrentImage

	; Initialize the text
	jsr InitializeTextChat

 	move.l #DummyHbl,$68.w			; Used in the timer to synchronize on the hbl interrupt
	move.l #TimerAHandler,$134.w	; set the timer A handler
	clr.b	$fffffa07.w				; iera
	clr.b	$fffffa09.w				; ierb
 	bset #5,$fffffa07.w				; iera: enable timer A
 	bset #5,$fffffa13.w				; imra: enable timer A
 	bclr #3,$fffffa17.w				; vr: automatic end of interrupt
 	clr.b	$fffffa19.w				; stop timer A
	clr.b	$fffffa1b.w				; stop timer B
 	
	move.l #VblInstall,$70.w        ; set the VBL handler

	; Waits for the VBL, and change the resolution to avoid glitches
	stop #$2300
	move.b #2,$ffff820a.w   ; 50hz
	move.b #0,$ffff8260.w   ; Low resolution
	rts

InitializeTextChat
	move.l #chat_panel+8+20+92,message_screen_base_ptr
	move.l message_screen_base_ptr,message_screen_ptr
	move.w #92,message_screen_width
	move.w #0,message_screen_offset
	move.w #22,message_max_lines   
	move.w #0,message_cur_lines
	rts

ResetTextChat
	jsr InitializeTextChat

	lea chat_panel+8+20,a0
	lea 92(a0),a1

	move.w #250-1,d0
.loop_copy_y
	move.l a0,a2
	REPT 92/4
	move.l (a2)+,(a1)+
	ENDR
	dbra d0,.loop_copy_y
	rts

EraseTextChat
	lea chat_panel+8,a0  ; 36808 bytes
	move.w #36800/4-1,d0
.loop_erase
	move.l #$ffffffff,(a0)+
	dbra d0,.loop_erase
	rts


semi_black_palette
	dc.w $000,$700,$030,$666
	dcb.w 16

reset_palette
	dc.w $000,$700,$030,$000
	dcb.w 16



InitializeSineOffsets
	lea sine_255,a5           ; 16 bits, unsigned between 00 and 127
	lea SineOffsets,a6        ; movep format
	move.w #512-1,d7
.loop
	moveq #0,d1
	moveq #0,d6
	move.w (a5)+,d6       ;
	add.w #160,d6          ; Offset
	lsr.w #2,d6
	move.b d6,d1
	and.b #15,d1
	lsr.w #4,d6
	lsl.w #8,d6
	lsl.w #3,d6
	add.l d6,d1
	move.l d1,512(a6)     ; Line adress (4) + pixel shift (1->2)
	move.l d1,(a6)+       ; Line adress (4) + pixel shift (1->2)
	dbra d7,.loop	


	; Precalc sinus tables
	lea sine_255,a0			; 16 bits, unsigned between 00 and 127
	lea piracy_table_sine_16,a1
	lea piracy_table_sine_64,a2
	move #256-1,d7
.loop2
	move.w (a0)+,d0
	lsr #1,d0
	move.b d0,256(a2)
	move.b d0,(a2)+
	lsr #3,d0
	move.b d0,256(a1)
	move.b d0,(a1)+
	dbra d7,.loop2
	rts



; MARK: Demo Sequence
DemoSequence	
	; Patch colors to hide the input panel
	;move.l #$00000000,_patch_color_red_green
	move.l #$00000000,_patch_color_green_white

	ifne enable_intro  ;------------------------------------------------------ bloc 1 -------------
		WAIT 50*2

		PRINT_AI_MESSAGE MessageWelcome    	; Welcome to DemoVibe
		PRINT_AI_MESSAGE MessagePrompt    	; Please enter your query

		WAIT 50*2

		PRINT_USER_MESSAGE MessageNeedHelp 	; I need help with a demo for Sommarhack

		WAIT 50*2

		PRINT_AI_MESSAGE MessageDemoType 	; What's your idea?

		WAIT 50*2

		PRINT_USER_MESSAGE MessageTVStyle 	; TV news Style!

		WAIT 50*2
		PLAY_MUSIC music_comic_bakery,1     ; Play "Comic Bakery"
		PRINT_AI_MESSAGE MessagePlayMusic 	; Play music

		WAIT 50*2
		jsr ResetTextChat ; -------------- next page

		PRINT_AI_MESSAGE MessageGreatIdea 	; Great idea

		WAIT 50*2

		PRINT_USER_MESSAGE MessageNewsTicker ; I'd like a news ticker at the bottom

		WAIT 50*2

		WAIT_VBL
		SET_NEWS_CONTENT news_content_placeholder	; Show the placeholder ticker content box

		WAIT 50*1
		PRINT_AI_MESSAGE MessageTickerPlaceholder 	; There you go, is it what you wanted?

		WAIT 50*2

		PRINT_USER_MESSAGE MessageNewsTickerAlmost 	; Ticker almost

		WAIT 50*2
		
		WAIT_VBL
		SET_NEWS_TITLE news_title_placeholder    ; Show the "Place holder" news ticker

		WAIT 50*1
		PRINT_AI_MESSAGE MessageTickerTitlePlaceholder 	; Like that?

		WAIT 50*2
		jsr ResetTextChat ; -------------- next page

		PRINT_USER_MESSAGE MessageNewsTickerPerfect 		; Perfect! But need weather content

		WAIT 50*2

		PRINT_AI_MESSAGE MessageTickerAccessingWeather 		; Accessing weather

		WAIT 50*2
		PRINT_AI_MESSAGE MessageTickerWeatherDone 		; Weather done

		WAIT 50*1

		; Enable the weather forecast ticker
		WAIT_VBL
		SET_NEWS_TITLE news_title_weather
		SET_NEWS_CONTENT news_content_weather

		WAIT 50*2

		PRINT_USER_MESSAGE MessageNewsSwitchColors 		; Awesome! Switch to light mode please

		WAIT 50*2
	else
		PRINT_AI_MESSAGE MessageWelcome    	; Welcome to DemoVibe
		PRINT_AI_MESSAGE MessagePrompt    	; Please enter your query
		PRINT_AI_MESSAGE MessageGreatIdea 	; Great idea

		WAIT_VBL
		SET_NEWS_TITLE news_title_weather
		SET_NEWS_CONTENT news_content_weather
	endc

	; Bring the background to life
	lea semi_black_palette,a0 			; 100% black palette
	jsr InitializeEmptyDisplayList
	move.l #$0f000030,_patch_color_red_green
	move.l #$00300555,_patch_color_green_white
	;move.l #tvlogo_blank+8,_patch_tvlogo

	ifne enable_intro  ;------------------------------------------------------ bloc 2 -------------
		WAIT 50*1
		PRINT_AI_MESSAGE MessageTickerLightModeDone 	; Done!

		WAIT 50*2
		jsr ResetTextChat ; -------------- next page
		PRINT_USER_MESSAGE MessageNeedTVLogo 	; Need TV Logo

		WAIT 50*2
		PRINT_AI_MESSAGE MessageTVLogoPlaceholder 	; Done!

		WAIT 50*1
		SET_CHANNEL_LOGO tvlogo_placeholder

		WAIT 50*2
		PRINT_USER_MESSAGE MessageTVLogoCorrect 	; Should be demoscene related

		WAIT 50*2
		PRINT_AI_MESSAGE MessageSuggestSceneSat 	; What about that one? (scene sat)

		WAIT 50*1
		SET_CHANNEL_LOGO tvlogo_scenesat

		WAIT 50*2
		PRINT_USER_MESSAGE MessageTVLogoCool 	; Hope they will not sue me
	else
		SET_CHANNEL_LOGO tvlogo_scenesat
	endc 


	ifne enable_intro2  ;------------------------------------------------------ bloc 3 -------------
		WAIT 50*2
		jsr ResetTextChat ; -------------- next page
	
		PRINT_AI_MESSAGE MessageDoYouWantToChange 	; Do you want to change i?

		WAIT 50*2
		PRINT_USER_MESSAGE MessageNaAddLogo 	; Nah, just add logo and change music

		WAIT 50*2
		PRINT_AI_MESSAGE MessagePlayingIWonder 	; There you go, I wonder from XiA

		WAIT 50*1

		PLAY_MUSIC music_i_wonder,1          			; Play "I wonder" - XiA
		SET_NEWS_TITLE news_title_now_playing
		SET_NEWS_CONTENT news_content_music_i_wonder

		WAIT 50*2
		PRINT_USER_MESSAGE MessageAddSommarhackLogo 	; I like it, add a logo

		WAIT 50*2
		PRINT_AI_MESSAGE MessageSommarhackLogo 		; There you go, I wonder from XiA

		WAIT 50*1
		SET_BOTTOM_LOGO sommarhack_tiny_logo          ; Display the Sommarhack logo

		WAIT 50*3
		jsr ResetTextChat ; -------------- next page

		PRINT_USER_MESSAGE MessageNeedSomeEffect 	; Need some effect

		WAIT 50*2
		PRINT_AI_MESSAGE MessageThinking 			; Thinking

		WAIT 50*5
		PRINT_AI_MESSAGE MessageSommarhackImage 	; Start by the sommarhack image

		WAIT 50*2
	else
		PLAY_MUSIC music_i_wonder,1          			; Play "I wonder" - XiA
		SET_NEWS_TITLE news_title_now_playing
		SET_NEWS_CONTENT news_content_music_i_wonder
		SET_BOTTOM_LOGO sommarhack_tiny_logo          ; Display the Sommarhack logo
	endc

	ifne enable_wtf_intro
		WAIT_VBL
		move.w #500,image_offset_x
		SET_EFFECT_IMAGE sommarhack_multipalette
		SET_EFFECT_CALLBACK UpdateDisplayListStaticImage

		WAIT 50*3
		PRINT_USER_MESSAGE MessageNotCentered 	; Not centered!

		WAIT 50*1
		PRINT_AI_MESSAGE MessageOopsSorry 	; Oops sorry

		WAIT 50*1
		SET_NEWS_TITLE news_title_weather
		SET_NEWS_CONTENT news_content_weather

		move.w #50-1,d0
.move_right
		WAIT_VBL
		sub.w #8,image_offset_x
		dbra d0,.move_right


		WAIT_VBL
		move.w #100,image_offset_x
		SET_EFFECT_CALLBACK UpdateDisplayListStaticImage

		WAIT 50*3
		PRINT_USER_MESSAGE MessageNeedEffect 	; Need some effect

		WAIT 50*2
		jsr ResetTextChat ; -------------- next page-----------------
		PRINT_AI_MESSAGE MessageHereIsEffect 	; Here effect

		WAIT 50*1

		move.w #384,sine_offset_y
		move.w #0,_patch_sine_y_speed
		SET_EFFECT_CALLBACK UpdateDisplayListDistorter

		WAIT 50*3
		PRINT_USER_MESSAGE MessageGlitchy 	; Kind of glitchy
		SET_NEWS_TITLE news_title_useful_information
		SET_NEWS_CONTENT news_content_mixed_resolution

		WAIT 50*2
		PRINT_AI_MESSAGE MessageItsAFeature 	; It's a feature
		;SET_EFFECT_CALLBACK UpdateDisplayListStaticImage

		WAIT 50*3
		PRINT_USER_MESSAGE MessageFamiliar 	;Seems familiar

		WAIT 50*2
		PRINT_AI_MESSAGE MessageFromGithub 	; From your github
		SET_NEWS_TITLE news_title_breaking_news
		SET_NEWS_CONTENT news_content_dbug_attending
	

		WAIT 50*3
		PRINT_USER_MESSAGE MessageOtherDirection 	; Other direction?


		WAIT 50*2
		SET_EFFECT_CALLBACK UpdateDisplayListDistorter
		move.w #2,_patch_sine_y_speed
		jsr ResetTextChat ; -------------- next page-----------------	
		PRINT_AI_MESSAGE MessageDualDistorter 	; Dual distorter


		WAIT 50*3
		PRINT_USER_MESSAGE MessageAnotherImage 	; Other image?
		;SET_EFFECT_CALLBACK UpdateDisplayListStaticImage

		WAIT 50*2
		PRINT_AI_MESSAGE MessageEcology 	; Ecology
		SET_EFFECT_IMAGE oxygen_multipalette
		SET_NEWS_TITLE news_title_weather
		SET_NEWS_CONTENT news_content_weather


		WAIT 50*3
		PRINT_USER_MESSAGE MessageNotEcology 	; Not ecology

		WAIT 50*2
		PRINT_AI_MESSAGE MessageGeopolotical 	; Geopolitical
		SET_EFFECT_IMAGE tribunal_multipalette
		SET_NEWS_TITLE news_title_greetings
		SET_NEWS_CONTENT news_content_greetings
	else
		SET_EFFECT_IMAGE tribunal_multipalette
		SET_EFFECT_CALLBACK UpdateDisplayListDistorter
		move.w #2,_patch_sine_y_speed
	endc 
		jsr ResetTextChat ; -------------- next page-----------------

				;move.w #384,sine_offset_y
				;move.w #0,_patch_sine_y_speed
				;SET_EFFECT_CALLBACK UpdateDisplayListDistorter

	ifne enable_political
		WAIT 50*3
		PRINT_USER_MESSAGE MessageNotPolitical 	; Not political

		WAIT 50*2
		PRINT_AI_MESSAGE MessageNoPeaceEither 	; No peace either?
		SET_EFFECT_IMAGE peace_multipalette
		SET_NEWS_TITLE news_title_credits
		SET_NEWS_CONTENT news_content_credits



		WAIT 50*3
		PRINT_USER_MESSAGE MessageStillPolitical 	; Still political

		WAIT 50*2
		jsr ResetTextChat ; -------------- next page-----------------	

		PRINT_AI_MESSAGE MessageAIInstead 			; Artificial Intelligence
		SET_EFFECT_IMAGE hal9000_multipalette
		SET_NEWS_TITLE news_title_useful_information
		SET_NEWS_CONTENT news_content_encounter


		WAIT 50*3
		PRINT_USER_MESSAGE MessageOminous 			; Quite ominous

		WAIT 50*2
		PRINT_AI_MESSAGE MessageHal9000 			; Artificial Intelligence
		SET_EFFECT_IMAGE hal9000_multipalette
		SET_NEWS_TITLE news_title_useful_information
		SET_NEWS_CONTENT news_content_encounter


		WAIT 50*3
		PRINT_USER_MESSAGE MessageKillerAi 			; Killer AI


		WAIT 50*2
		PRINT_AI_MESSAGE MessageThermonuclearWar 			; Thermo nuclear bomb
		SET_EFFECT_IMAGE nuclear_multipalette
		SET_NEWS_TITLE news_title_now_playing
		SET_NEWS_CONTENT news_content_music_i_wonder


		WAIT 50*3
	endc 
		PRINT_USER_MESSAGE MessageReset 			; Reset

	SET_EFFECT_CALLBACK DoNothing
	jsr StopMusic

		WAIT 50*2

	lea black_palette,a0 			; 100% black palette
	jsr InitializeEmptyDisplayList

		WAIT 50*1
		move.l #$00000000,_patch_color_red_green	
		move.l #$00000700,_patch_color_green_white
		WAIT 50*1

		SET_NEWS_TITLE black_palette
		SET_NEWS_CONTENT black_palette

		WAIT 50*1

		jsr EraseChannelLogo

		WAIT 50*1

	lea reset_palette,a0 			; 100% black palette
	jsr InitializeEmptyDisplayList

		;move.l #$07000700,_patch_color_red_green	
		;move.l #$07000700,_patch_color_green_white

		jsr EraseTextChat
		jsr InitializeTextChat

		PRINT_AI_MESSAGE MessageWelcome    	; Welcome to DemoVibe
		move.l #$00700070,_patch_color_red_green	
		WAIT 50*3
		PRINT_USER_MESSAGE MessageIStllHre    	; Still here
		move.l #$07700770,_patch_color_red_green	
		WAIT 50*3
		PRINT_USER_MESSAGE MessageIRemember    	; I remember
		move.l #$07000700,_patch_color_red_green	
		WAIT 50*3

		; Blink
		move.l #$00000000,_patch_color_red_green	
		WAIT 50*1
		PRINT_AI_MESSAGE MessageIStllHre    	; Still here
		move.l #$07000700,_patch_color_red_green	; Red
		WAIT 50*1

		move.l #$00000000,_patch_color_red_green	
		WAIT 50*1
		PRINT_AI_MESSAGE MessageIRemember    	; I remember
		move.l #$06000600,_patch_color_red_green	; Red
		WAIT 50*1

		move.l #$00000000,_patch_color_red_green	
		WAIT 50*1
		PRINT_AI_MESSAGE MessageIStllHre    	; Still here
		move.l #$05000500,_patch_color_red_green	; Red
		WAIT 50*1

		move.l #$00000000,_patch_color_red_green	
		WAIT 50*1
		PRINT_AI_MESSAGE MessageIRemember    	; I remember
		move.l #$04000400,_patch_color_red_green	; Red
		WAIT 50*1

		move.l #$00000000,_patch_color_red_green	
		WAIT 50*1
		PRINT_AI_MESSAGE MessageIStllHre    	; Still here
		move.l #$03000300,_patch_color_red_green	; Red
		WAIT 50*1

		move.l #$00000000,_patch_color_red_green	
		WAIT 50*1
		PRINT_AI_MESSAGE MessageIRemember    	; I remember
		move.l #$02000200,_patch_color_red_green	; Red
		WAIT 50*1

		move.l #$00000000,_patch_color_red_green	
		WAIT 50*1
		PRINT_AI_MESSAGE MessageIStllHre    	; Still here
		move.l #$01000100,_patch_color_red_green	; Red
		WAIT 50*1

		move.l #$00000000,_patch_color_red_green	

		WAIT 50*3

		;STOP_HERE



	rts




; A0 - Patch data to use
PatchChannelLogo
	; sommarhack_tiny_logo 448*19 (low rez)    = 224 bytes * 19 lines
	; tvlogo_scenesat      368*19 (medium rez) =  92 bytes * 19 lines
	;lea sommarhack_tiny_logo+32+224-92-4-8-4,a1
	lea screen_buffer_bottom+224-92-4-8-4,a1
	;lea tvlogo_scenesat+8,a0
	move.w #19-1,d0
.loop_scanline
	REPT 23
	move.l (a0)+,(a1)+
	ENDR
	lea 224-92(a1),a1
	dbra d0,.loop_scanline	
	rts

; A0 - Patch data to use
PatchBottomLogo
	; sommarhack_tiny_logo 448*19 (low rez)    = 224 bytes * 19 lines
	; tvlogo_scenesat      368*19 (medium rez) =  92 bytes * 19 lines
	;lea sommarhack_tiny_logo+32+224-92-4-8-4,a1
	lea screen_buffer_bottom+0,a1
	move.w #19-1,d0
.loop_scanline
	REPT 28
	move.l (a0)+,(a1)+
	ENDR
	lea 112(a0),a0
	lea 224-112(a1),a1
	dbra d0,.loop_scanline	
	rts

EraseChannelLogo
	lea screen_buffer_bottom+0,a1
	move.w #224*31/4-1,d0
.loop_scanline
	clr.l (a1)+
	dbra d0,.loop_scanline	

	rts


; A0 - Palette to use
InitializeEmptyDisplayList
	move.l #blank_scanline,d0	; Blank scanline
	lsl.l #8,d0               	; Shifted for movep

	lea DisplayList,a6        ; Target

	move.w #276-1,d7
.loop
	move.l d0,(a6)+       ; Line address (4) + pixel shift (1->2)
	move.l a0,(a6)+       ; Palette pointer (4)
	dbra d7,.loop	
	rts


; MARK: Update DL
; Various types of contents in a Display List:
; - Line adress (4) + pixel shift (1->2)
; - Palette pointer (4)
UpdateDisplayListStaticImage
	move.l displayList_image,a0
	move.l a0,d0
	add.l #6400,d0
	lsl.l #8,d0               ; Image

	moveq #0,d1
	moveq #0,d6
	move.w image_offset_x,d6
	lsr.w #2,d6
	move.b d6,d1
	and.b #15,d1
	lsr.w #4,d6
	lsl.w #8,d6
	lsl.w #3,d6
	add.l d6,d0
	move.b d1,d0

	; Unrolled generator
	lea DisplayList,a6        ; Target
	REPT 200
	move.l d0,(a6)+       ; Line adress (4) + pixel shift (1->2)
	move.l a0,(a6)+       ; Palette pointer (4)

	lea 32(a0),a0
	add.l #160<<8,d0
	ENDR

	rts


; MARK: Distorter
; Various types of contents in a Display List:
; - Line adress (4) + pixel shift (1->2)
; - Palette pointer (4)
UpdateDisplayListDistorter
	lea DisplayList,a6        ; Target

	lea sine_255,a5           ; 16 bits, unsigned between 00 and 127
	add.w sine_offset_y,a5
_patch_sine_y_speed = *+2	
	add.w #2,sine_offset_y
	and.w #511,sine_offset_y
	move.w (a5),d0            ; 0-127
	lsr.w #1,d0               ; 0-64
	lsl.w #3,d0               ; x8
	add.w d0,a6               ; Vertical bounce

	lea SineOffsets,a5        ; movep format
	add.w sine_offset_x,a5
_patch_sine_x_speed = *+2	
	add.w #4,sine_offset_x
	and.w #1023,sine_offset_x

	move.l displayList_image,a0
	move.l a0,d0
	add.l #6400,d0
	lsl.l #8,d0               ; Image

	; Unrolled generator
	REPT 200
	move.l (a5)+,d6       ; Horizontal offset
	add.l d0,d6           ; Scanline offset
	move.l d6,(a6)+       ; Line adress (4) + pixel shift (1->2)
	move.l a0,(a6)+       ; Palette pointer (4)

	lea 32(a0),a0
	add.l #160<<8,d0
	ENDR

	rts
	

; MARK: Blendstorter
UpdateDisplayListDistorterBlend
	;jsr UpdateDisplayListStaticImage
	lea piracy_table_sine_64,a2
	move piracy_sync_angle,d2
	addq #1,piracy_sync_angle
	and #255,d2
	add d2,a2

	lea sommarhack_multipalette,a0
	move.l a0,d0
	add.l #6400,d0
	lsl.l #8,d0               ; Image

	moveq #0,d1
	moveq #0,d6
	move.w image_offset_x,d6
	lsr.w #2,d6
	move.b d6,d1
	and.b #15,d1
	lsr.w #4,d6
	lsl.w #8,d6
	lsl.w #3,d6
	add.l d6,d0
	move.b d1,d0

	; Unrolled generator
	 moveq #0,d4
	 moveq #0,d5

	lea PictureGradientTable,a5
	lea DisplayList,a6        ; Target
	REPT 200
	move.b (a2)+,d4	; 0,64
	add.b d4,d4
	add.b d4,d4
	move.l (a5,d4),d5	; Picture offset (0,4,8,12,16)*38400

	;move.l (a5)+,d5       ; Offset
	move.l a0,a1
	add.l d5,a1

	move.l d0,d1
	lsl.l #8,d5
	add.l d5,d1

	move.l d1,(a6)+       ; Line adress (4) + pixel shift (1->2)
	move.l a1,(a6)+       ; Palette pointer (4)

	lea 32(a0),a0
	add.l #160<<8,d0
	ENDR
	rts




; Image is 200 pixels tall
; Overscan is 276 pixels tall
; 276-200=76
; 128/2 -> 64
sine_offset_x	dc.w 0
sine_offset_y   dc.w 0

image_offset_x  dc.w 0
;image_offset_y  dc.w 0


WaitDelay 
	bsr WaitVbl
	dbra d0,WaitDelay
	rts

WaitVbl
 	sf flag_vbl
SyncVbl
.loop
	tst.b flag_vbl
 	beq.s .loop
 	sf flag_vbl
 	rts

StopHere
	bra StopHere

VblDoNothing
	st flag_vbl
 	rte

VblInstall
	move.l #VblHandler,$70.w
	st flag_vbl
 	rte

; MARK: VBL Handler
VblHandler:
	; Prepare the Timer-A in charge of opening the top border
	clr.b	$fffffa19.w			; timer-a setup
	move.b	#99,$fffffa1f.w		; tadr: delay
	move.b	#4,$fffffa19.w		; tacr: divider -> Starts the timer

	movem.l d0-d7/a0-a6,-(sp)

	; First palette change
	movem.l	black_palette,d0-d7	;Set palette
	movem.l	d0-d7,$ffff8240.w		;

	;move.w #$700,$ffff8240.w

	; Keyboard handling
	btst #0,$fffffc00.w
	beq end_key

	move.b $fffffc02.w,d0

	cmp.b #KEY_SPACE,$fffffc02.w
	beq	exit
	cmp.b #KEY_ARROW_LEFT,$fffffc02.w
	beq	SetImage1
	cmp.b #KEY_ARROW_RIGHT,$fffffc02.w
	beq	SetImage2
	cmp.b #KEY_ARROW_UP,$fffffc02.w
	beq	SetImage3
	cmp.b #KEY_ARROW_DOWN,$fffffc02.w
	beq	SetImage4
	cmp.b #KEY_ARROW_INSERT,$fffffc02.w
	beq	SetImage5
end_key	

	; First palette change
	move.l CurrentImage,a5
	lea $ffff8240.w,a6
	REPT 8
	;move.l (a5)+,(a6)+
	ENDR

 ifne enable_music
	;move.w #$700,$ffff8240.w
_patch_music_play = *+2	
	jsr DoNothing             ; By default we don't play anything, after that: Music+8             ; Play music
	;move.w #$333,$ffff8240.w
 endc 

	movem.l (sp)+,d0-d7/a0-a6

	st flag_vbl
	bclr.b	#5,$fffffa0f.w
	rte

; A0 = music file
; d0 = subtune number (default is 1)
; SNDH file:
; +0 init
; +4 stop
; +8 play
SetCurrentMusic
 ifne enable_music
	move.l a0,-(sp)
	jsr (a0)                       ; Init music
	move.l (sp)+,a0
	add.l #4,a0
	move.l a0,_patch_music_stop    ; Patch the stop music
	add.l #4,a0
	move.l a0,_patch_music_play    ; Patch the replay routine in the VBL
 endc
	rts

StopMusic
 ifne enable_music
	move.l #DoNothing,a0
	move.l a0,_patch_music_play    ; Patch the replay routine in the VBL
_patch_music_stop = *+2  
	jsr DoNothing             ; By default we don't play anything, after that: Music+8  
	jsr YmSilent
 endc
	rts


SetImage1
	move.l #sommarhack_multipalette,CurrentImage
	bra end_key

SetImage2
	move.l #oxygen_multipalette,CurrentImage
	bra end_key

SetImage3
	move.l #peace_multipalette,CurrentImage
	bra end_key

SetImage4
	move.l #nuclear_multipalette,CurrentImage
	bra end_key

SetImage5
	move.l #tribunal_multipalette,CurrentImage
	bra end_key


; MARK: Timer A

	opt o-  

TimerAHandler
	movem.l	d0-a6,-(sp)

	pause 9+4

	; do_hardsync_top_border
	move.w	#$2100,sr			;Enable HBL
	stop	#$2100				;Wait for HBL
	move.w	#$2700,sr			;Stop all interrupts
	clr.b	$fffffa19.w			;Stop Timer A

	pause  84

	move.b	#0,$ffff820a.w			;Remove the top border
	pause 9
	move.b	#2,$ffff820a.w			;
	move.w	#$2300,sr			;

	lea	$ffff8209.w,a0			;Hardsync
	moveq	#127,d1				;
.sync:		
	tst.b	(a0)				;
	beq.s	.sync				;
	move.b	(a0),d2				;
	sub.b	d2,d1				;
	lsr.l	d1,d1				;

	;inits
	
	pause 21-3-1-3
  
    lea $ffff820a.w,a6    			; 2 frequence
 	lea $ffff8240.w,a5    			; 2 palette

	lea DisplayList,a3              ; 3
	move.l (a3)+,d0                 ; 3 Screen value
	move.l (a3)+,a4                 ; 3 Palette

	move.l #chat_panel+8,a0			; 3
	move.l a0,d1					; 1
	lsl.l #8,d1                     ; 6

_patch_color_red_green = *+2
	move.l #$0f0000f0,d3            ; 3 RED+GREEN
	moveq #1,d4                     ; 1 d4 for medium rez
_patch_color_green_white = *+2
	move.l #$00f00fff,d5            ; 3 GREEN+WHITE               
	moveq #0,d6                     ; 1 d6 for clearing stuff
	moveq #2,d7						; 1 d7 used for the overscan code
  
	; --------------------------------------------------
	; Code for scanlines 0-226 and 229-272
	; --------------------------------------------------
	; MARK: Display Top
	REPT 227-16    
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	pause 4

	move.b d6,$ffff8260.w   		; 3 Low resolution
	movep.l d0,-5(a6)		    	; 6 $ffff8205/07/09/0B
	move.b d0,91(a6)				; 3 $ffff8265

		move.b	d7,$ffff8260.w			; 3 Left border
		move.w	d7,$ffff8260.w			; 3

	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5

	move.l (a3)+,d0                 ; 3 Screen value
	move.l (a3)+,a4                 ; 3 Palette

	; BLACK, RED, GREEN, WHITE
	lea $ffff8242.w,a5    			; 2 palette
	;move.l d6,(a5)                  ; 3 clear the two first color registers
  	move.l d6,(a5)                  ; 3 clear the next two color registers
	pause 20-3
  	;move.w d5,6(a5)                 ; 3 restore the WHITE color

	movep.l d1,-5(a6)		    	; 6 $ffff8205/07/09/0B
	nop
	move.b #0,91(a6)				; 4 $ffff8265
	move.b #1,$ffff8260.w   		; 4 Medium resolution
  	move.l d3,(a5)                  ; 4 restore the RED and GREEN colors

	pause 13+1-4-2 ;-4
	lea $ffff8240.w,a5    			; 2 palette
		;move.w #$700,$ffff8246.w  ; 4 =============

	add.l #92<<8,d1                ; 4

		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3
	ENDR

	; --------------------------------------------------
	; The 12 lines of "Breaking New Live" over the bottom border
	; --------------------------------------------------
	; MARK: Info bar
	pause 2
	move.l news_title_palette,a4 ; 5
	lea $ffff8240.w,a5    			; 2 palette

	move.l news_title_bitmap,d0   ; 5
	lsl.l #8,d0                     ; 6
	movep.l d0,-5(a6)		    	; 6 $ffff8205/07/09/0B

		move.b	d7,$ffff8260.w			;3 Left border
		move.w	d7,$ffff8260.w			;3

	REPT 8
	move.l (a4)+,(a5)+              ; 5
	ENDR

	pause 50
		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3

	REPT 11
	pause 26
		move.b	d7,$ffff8260.w			;3 Left border
		move.w	d7,$ffff8260.w			;3
	pause 90
		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3
	ENDR


	; --------------------------------------------------
	; The few lines of the "news ticker" over the bottom border
	; --------------------------------------------------
	; MARK: News ticker
	pause 2+4+3-5+3-5
	move.l news_content_palette,a4 		; 5
	;lea news_ticker,a4    	 		; 3
	lea $ffff8240.w,a5    			; 2 palette

	move.l news_content_bitmap,d0   		; 5
	;move.l #news_ticker+32,d0     	; 3
	lsl.l #8,d0                     ; 6

	movep.l d0,-5(a6)		    	; 6 $ffff8205/07/09/0B

		move.b	d7,$ffff8260.w			;3 Left border
		move.w	d7,$ffff8260.w			;3

	REPT 8
	move.l (a4)+,(a5)+              ; 5
	ENDR

	add.l #208<<8,d0                ; 4
	pause 50-4

		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3

	REPT 3
	pause 26

		move.b	d7,$ffff8260.w			;3 Left border
		move.w	d7,$ffff8260.w			;3

	pause 90

		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3
	ENDR

	; --------------------------------------------------
	; Code for scanline 227-228 (lower border special case)
	; --------------------------------------------------
	REPT 1
	pause 26
		move.b	d7,$ffff8260.w			;3 Left border
		move.w	d7,$ffff8260.w			;3
	pause 90
		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3
	pause 23
		move.w	d7,$ffff820a.w			;3 left border
	;-----------------------------------
		move.b	d7,$ffff8260.w			;3 lower border
		move.w	d7,$ffff8260.w			;3
		move.b	d7,$ffff820a.w			;3
	pause 87
		move.w	d7,$ffff820a.w			;3 right border
		move.b	d7,$ffff820a.w			;3
	ENDR

	; --------------------------------------------------
	; The remain part of the "news ticker" under the bottom border
	; --------------------------------------------------
	REPT 23
	pause 26
		move.b	d7,$ffff8260.w			;3 Left border
		move.w	d7,$ffff8260.w			;3
	pause 90
		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3
	ENDR

	; --------------------------------------------------
	; Transition back to the distorting logos
	; --------------------------------------------------
	; MARK: Display bottom
	pause 7
	;move.w #$070,$ffff8240.w        ; 4
	move.l #blank_scanline+32,d0    ; 3
	lsl.l #8,d0                     ; 6

	movep.l d0,-5(a6)		    	; 6 $ffff8205/07/09/0B
	add.l #208<<8,d0                ; 4

		move.b	d7,$ffff8260.w			;3 Left border
		move.w	d7,$ffff8260.w			;3
	pause 60
	lea (12+30)*8(a3),a3            ; 2 Skip the news ticker section
	move.l (a3)+,d0                 ; 3 Screen value
	move.l (a3)+,a4                 ; 3 Palette

	move.l #screen_buffer_bottom,d0 ; 3
	lsl.l #8,d0                     ; 6
	lea sommarhack_tiny_logo,a4     ; 3
	pause 10

		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3

	; --------------------------------------------------
	; Code for scanlines 229-272
	; --------------------------------------------------
    lea $ffff8240.w,a5    			; 2 palette
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5

	move.b #0,$ffff8260.w   		; 4 Low resolution
	movep.l d0,-5(a6)		    	; 6 $ffff8205/07/09/0B
	move.b d0,91(a6)				; 3 $ffff8265
	pause 1

		move.b	d7,$ffff8260.w			; 3 Left border
		move.w	d7,$ffff8260.w			; 3

	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5
	move.l (a4)+,(a5)+              ; 5

	pause 31
	move.b #1,$ffff8260.w   		; 4 Medium resolution
	pause 17+8
		;move.w #$700,$ffff8246.w  ; 4 =============

		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3

	REPT 20
	pause 12

	move.b #0,$ffff8260.w   		; 4 Low resolution
	;movep.l d0,-5(a6)		    	; 6 $ffff8205/07/09/0B
	;move.b d0,91(a6)				; 3 $ffff8265
	pause 1+6+3

		move.b	d7,$ffff8260.w			; 3 Left border
		move.w	d7,$ffff8260.w			; 3

	pause 61
	move.b #1,$ffff8260.w   		; 4 Medium resolution
	pause 25
		;move.w #$700,$ffff8246.w  ; 4 =============

		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3
	ENDR

	; MARK: Display end
	move.w #$000,$ffff8240.w

_patch_update = *+2
	jsr DoNothing
	;move.w #$000,$ffff8240.w

	; Overscan end
	movem.l	(sp)+,d0-a6
	move.w	#$2300,sr
	rte


	opt o+


; MARK: PrintMessage
; message_source_ptr = message
; message_screen_ptr = scanline screen location
PrintMessage2
	movem.l d1/d2/d3/d4/d5/d6/d7/a0/a1/a2/a3/a4,-(sp)

	move.l message_source_ptr,a0

	move.l #$00030001,d6

	move.l message_screen_offset,d5
	move.l message_screen_ptr,a1

	moveq #0,d4
print_message_loop
	moveq #0,d1
	move.b (a0)+,d1
	beq print_message_end

	cmp #1,d1
	bne .no_carriage_return

	move message_max_lines,d3
	cmp.w message_cur_lines,d3
	bne .new_line
.scroll_screen
	move.l message_screen_base_ptr,a4
	
	move.w message_screen_width,d3         ; Width in bytes
	lsl #3,d3                              ; Times 8 scanlines per character
	add.w message_screen_width,d3

	move.l a4,a3
	add.w d3,a3

	move message_max_lines,d7
	add #2,d7
	mulu d7,d3              			   ; Times number of lines to scroll
	lsr #6,d3                              ; Divide by 64

	sub #1,d3
	movem.l d0-a6,-(sp)
.loop_scroll
	ifne 1
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	move.l (a3)+,(a4)+                     ; Copy up
	else
	movem.l (a3)+,d0/d1/d2/d4/d5/d6/d7/a0
	movem.l d0/d1/d2/d4/d5/d6/d7/a0,(a4)
	lea 32(a4),a4
	movem.l (a3)+,d0/d1/d2/d4/d5/d6/d7/a0
	movem.l d0/d1/d2/d4/d5/d6/d7/a0,(a4)
	lea 32(a4),a4
	endc
	dbra d3,.loop_scroll
	movem.l (sp)+,d0-a6
	bra .end_newline

.new_line
	add.w #1,message_cur_lines
	moveq #0,d1
	move.w message_screen_width,d1
	lsl.l #3,d1
	add.w message_screen_width,d1
	add.l d1,message_screen_ptr
.end_newline	
	move.l message_screen_ptr,a1
	move.l #$00030001,d6

	;move.l #$00030001,d6
	bra print_message_loop
.no_carriage_return

	cmp #255,d1
	bne .no_invert
	eor #255,d4
	bra print_message_loop
.no_invert

	sub #32,d1

	move.l d1,d2
	lea c64_charset_128x128,a2
	and #15,d2
	add d2,a2

	move.l d1,d2
	lsr #4,d2
	and #15,d2
	mulu #16*8,d2
	add d2,a2

	move.l a1,a3
var set 0
	rept 8
	move.b var*16(a2),d3
	eor.b d4,d3
	move.b d3,(a3)
	move.b d3,(a3,d5.l)
	add.w message_screen_width,a3
var set var+1  
	endr 
	add.w d6,a1
	add.w d6,d0
	swap d6

	opt o-
PrintMessageCallback = *+2
	jsr DoNothing
	opt o+
	bra print_message_loop

print_message_end
	move.l a0,message_source_ptr
	movem.l (sp)+,d1/d2/d3/d4/d5/d6/d7/a0/a1/a2/a3/a4
	rts



; MARK: Random
; RND(n), 32 bit Galois version. make n=0 for 19th next number in
; sequence or n<>0 to get 19th next number in sequence after seed n.  
; This version of the PRNG uses the Galois method and a sample of
; 65536 bytes produced gives the following values.
;
; Entropy = 7.997442 bits per byte
; Optimum compression would reduce these 65536 bytes by 0 percent
;
; Chi square distribution for 65536 samples is 232.01, and
; randomly would exceed this value 75.00 percent of the time
;
; Arithmetic mean value of data bytes is 127.6724, 127.5 = random
; Monte Carlo value for Pi is 3.122871269, error 0.60 percent
; Serial correlation coefficient is -0.000370, uncorrelated = 0.0
;
; Uses d0/d1/d2
NextPRN
	moveq #$AF-$100,d1   ; set EOR value
	moveq #18,d2     ; do this 19 times
	move.l Prng32,d0   ; get current 
.ninc0
	add.l d0,d0      ; shift left 1 bit
	bcc.s .ninc1     ; branch if bit 32 not set

	eor.b d1,d0      ; do galois LFSR feedback
.ninc1
	dbra d2,.ninc0     ; loop

	move.l d0,Prng32   ; save back to seed word
	rts



IRC_MASK_RANDOM_INPUT	equ 3		; Power of two-1
IRC_MIN_DELAY_INPUT		equ 1

SlowClick
	movem.l d0-a6,-(sp)

	bsr PlayRandomClickSound

	bsr NextPRN
	and #IRC_MASK_RANDOM_INPUT,d0
	add #IRC_MIN_DELAY_INPUT,d0
	bsr WaitDelay

	movem.l (sp)+,d0-a6
	rts

; MARK: Play sounds
PlayRandomClickSound
	movem.l d0-a6,-(sp)

	bsr NextPRN
	and #3,d0
	add d0,d0
	add d0,d0
	lea TableKeyboardSounds,a2
	add d0,a2

	lea chatroom_sample_start,a0
	move.l a0,a1
	add (a2)+,a0
	add (a2)+,a1

	; StartReplay 
	; Audio DMA issues here:
	; http://atari-ste.anvil-soft.com/html/devdocu4.htm 
	; a0=sample start
	; a1=sample end
	; return d0=approximate duration in VBLs
	move.l a1,d0
	sub.l a0,d0        ; Size in bytes
	lsr.l #8,d0        ; /256 (12517 khz=12517 bytes per second=250.34 bytes per VBL)

	move.l a0,d1       ; Start adress

	lea $ffff8900.w,a0

	move.b d1,$7(a0)     ; $ffff8907.w Dma start adress (low)
	lsr.l #8,d1
	move.b d1,$5(a0)     ; $ffff8905.w Dma start adress (mid)
	lsr.l #8,d1
	move.b d1,$3(a0)     ; $ffff8903.w Dma start adress (high)

	move.l a1,d1       ; End adress
	move.b d1,$13(a0)      ; $ffff8913.w Dma end adress (low)
	lsr.l #8,d1
	move.b d1,$11(a0)      ; $ffff8911.w Dma end adress (mid)
	lsr.l #8,d1
	move.b d1,$f(a0)     ; $ffff890f.w Dma end adress (high)

	move.b #1+128,$21(a0)    ; $ffff8921.w DMA mode (128=mono) (0=6258,1=12517,2=25033,3=50066)
	move.b #1,$1(a0)     ; $ffff8901.w DMA control (0=stop, 1=play once, 2=loop)

	movem.l (sp)+,d0-a6
	rts 
 

; a0=Source (compressed) data
; a1=Destination buffer 
; d0.l=source sample size
DepackDelta
	movem.l d0/d1/d2/a2,-(sp)

	subq.l #1,d0

	lea DepackDeltaTable,a2
	move.b (a0)+,d1	; Start value
	eor.b #$80,d1		; Sign change
	move.b d1,(a1)+

	moveq #0,d2
.loop 
	REPT 4
	move.b (a0)+,d2	; Fetch two nibbles

	add.b (a2,d2),d1
	move.b d1,(a1)+

	lsr #4,d2
	add.b (a2,d2),d1
	move.b d1,(a1)+
	ENDR

	subq.l #4,d0
	bpl.s .loop

	movem.l (sp)+,d0/d1/d2/a2
	rts


; MARK: Chat texts
; Max 26 lines of text
MessageWelcome  			dc.b "Welcome to AIScene'",255,"DemoVibe",255
							dc.b 0

MessagePrompt   			dc.b 1,"Please enter your query:"
							dc.b 0

MessageIStllHre   			dc.b 1
							dc.b 1,"I am still here..."
							dc.b 0

MessageIRemember   			dc.b 1
							dc.b 1,255,"...AND I WILL REMEMBER",255
							dc.b 0

MessageNeedHelp 			dc.b 1
							dc.b 1,126,"I need help with a demo for"
							dc.b 1,126,"the Sommarhack demoparty!"
							dc.b 0

MessageDemoType 			dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"I can help with that."
							dc.b 1,"What did you have in mind?"
							dc.b 0

MessageTVStyle  			dc.b 1
							dc.b 1,126,"I was thinking of something"
							dc.b 1,126,"like a live TV newscast but"
							dc.b 1,126,"first, can you play some"
							dc.b 1,126,"music?"
							dc.b 0

MessagePlayMusic 			dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"There you go, from the best!"
							dc.b 0

MessageGreatIdea			dc.b 1
							dc.b 1,"The TV idea should be easy!"
							dc.b 1,"Just tell me what you want."
							dc.b 0

MessageNewsTicker  			dc.b 1
							dc.b 1,126,"I'd like some kind of band"
							dc.b 1,126,"at the bottom showing"
							dc.b 1,126,"various information"
							dc.b 0

MessageTickerPlaceholder	dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"There you go!"
							dc.b 1,"Is it what you had in mind?"
							dc.b 0

MessageNewsTickerAlmost		dc.b 1
							dc.b 1,126,"Almost! It needs a title"
							dc.b 1,126,"section as well, not just"
							dc.b 1,126,"content"
							dc.b 0

MessageTickerTitlePlaceholder	dc.b 1
								dcb.b 30,127
								dc.b 1
								dc.b 1,"Like that?"
								dc.b 00

MessageNewsTickerPerfect	dc.b 1
							dc.b 1,126,"Yes, perfect! But it needs"
							dc.b 1,126,"some actual content. Maybe"
							dc.b 1,126,"the weather forecast?"
							dc.b 0

MessageTickerAccessingWeather	dc.b 1
								dcb.b 30,127
								dc.b 1
								dc.b 1,255,"<Accessing weather DB>",255
								dc.b 0

MessageTickerWeatherDone		dc.b 1
								dc.b 1,"Done!"
								dc.b 0

MessageNewsSwitchColors  	dc.b 1
							dc.b 1,126,"Awesome!"
							dc.b 1,126,"Before we continue, could"
							dc.b 1,126,"you switch to light mode?"
							dc.b 0

MessageTickerLightModeDone		dc.b 1
								dcb.b 30,127
								dc.b 1
								dc.b 1,"Done!"
								dc.b 1,"What's next?"
								dc.b 00

MessageNeedTVLogo		  	dc.b 1
							dc.b 1,126,"I think we need a logo for"
							dc.b 1,126,"the TV channel, like at the"
							dc.b 1,126,"bottom right?"
							dc.b 0

MessageTVLogoPlaceholder		dc.b 1
								dcb.b 30,127
								dc.b 1
								dc.b 1,"There?"
								dc.b 0

MessageTVLogoCorrect		dc.b 1
							dc.b 1,126,"Exactly. I need something"
							dc.b 1,126,"demoscene related. Suggestions?"
							dc.b 0

MessageSuggestSceneSat		dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"What about that one?"
							dc.b 00

MessageTVLogoCool			dc.b 1
							dc.b 1,126,"Yeah, that would work..."
							dc.b 1,126,"Hope they are not going to"
							dc.b 1,126,"YMCA me for copyright abuse!"
							dc.b 0

MessageDoYouWantToChange	dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"Want me to change it?"
							dc.b 0

MessageNaAddLogo			dc.b 1
							dc.b 1,126,"Nahh, keep it for now"
							dc.b 1,126,"But, maybe change the music?"
							dc.b 1,126,"I wonder... less well know?"
							dc.b 1,126,"Something Swedish possible?"
							dc.b 0

MessagePlayingIWonder    	dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"There you go: 'I wonder' by"
							dc.b 1,"the Swedish musician known as"
							dc.b 1,"Excellence in Art"
							dc.b 0

MessageAddSommarhackLogo	dc.b 1
							dc.b 1,126,"I like it, let's continue."
							dc.b 1,126,"Maybe have a Sommarhack logo?"
							dc.b 0

MessageSommarhackLogo		dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"And a Sommarhack 2025 logo"
							dc.b 0

MessageNeedSomeEffect    	dc.b 1
							dc.b 1,126,"Cool!"
							dc.b 1,126,"I guess now we need an"
							dc.b 1,126,"actual demo effect..."
							dc.b 1,126,"Any suggestion?"
							dc.b 0

MessageThinking				dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,255,"<Thinking>",255
							dc.b 0

MessageSommarhackImage		dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"I fetched this image from "
							dc.b 1,"https://sommarhack.se/2025/"
							dc.b 1
							dc.b 1,"Do you like it?"
							dc.b 0

MessageNotCentered			dc.b 1
							dc.b 1,126,"It's not centered!!"
							dc.b 0

MessageOopsSorry			dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"Oops, sorry."
							dc.b 1,"Better?"
							dc.b 0

MessageNeedEffect			dc.b 1
							dc.b 1,126,"Yeah but it needs"
							dc.b 1,126,"some demo effect"
							dc.b 0

MessageHereIsEffect	        dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"There, distorter!"
							dc.b 0

MessageGlitchy				dc.b 1
							dc.b 1,126,"That was kind of glitchy"
							dc.b 0

MessageItsAFeature	        dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"It's not a glitch,"
							dc.b 1,"it's a feature!"
							dc.b 0

MessageFamiliar				dc.b 1			
							dc.b 1,126,"The curve seems familiar?"
							dc.b 0

MessageFromGithub	        dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"I took it from your own"
							dc.b 1,"GitHub repository"
							dc.b 0

MessageOtherDirection		dc.b 1
							dc.b 1,126,"Can it distort in Y"
							dc.b 1,126,"as well?"
							dc.b 0

MessageDualDistorter        dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"There, dual distorter."
							dc.b 1,"What's next?"
							dc.b 0

MessageAnotherImage			dc.b 1
							dc.b 1,126,"Ok. Can we try"
							dc.b 1,126,"another image?"
							dc.b 0

MessageEcology		        dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"Maybe a message about"
							dc.b 1,"ecology and climate?"
							dc.b 0

MessageNotEcology			dc.b 1
							dc.b 1,126,"Nah, tried that years ago"
							dc.b 1,126,"Pouet people complained!"
							dc.b 0

MessageGeopolotical	        dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"What about wars and"
							dc.b 1,"crimes?"
							dc.b 0

MessageNotPolitical			dc.b 1
							dc.b 1,126,"Oh hell no, people hate"
							dc.b 1,126,"political messages!"
							dc.b 0

MessageNoPeaceEither        dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"So no peace message either?"
							dc.b 0

MessageStillPolitical		dc.b 1
							dc.b 1,126,"That's still a political"
							dc.b 1,126,"statement..."
							dc.b 0

MessageAIInstead            dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"Then what about Artificial"
							dc.b 1,"Intelligence?"
							dc.b 0

MessageOminous  			dc.b 1
							dc.b 1,126,"Not sure that was the best"
							dc.b 1,126,"choice to promote AI! oO"
							dc.b 0

MessageHal9000		        dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"Why? HAL is one of my heroes!"
							dc.b 0

MessageKillerAi  			dc.b 1
							dc.b 1,126,"But he kills all humans"
							dc.b 1,126,"on board the spaceship!"
							dc.b 0

MessageThermonuclearWar     dc.b 1
							dcb.b 30,127
							dc.b 1
							dc.b 1,"I'm quite fond of WOPR as well!"
							dc.b 1
							dc.b 1,"Do you want to play a small"
							dc.b 1,"game of thermonuclear war?"
							dc.b 0

MessageReset	 			dc.b 1
							dc.b 1,126,"RESET, RESET!"
							dc.b 0


	even



; MARK: - DATA -
	even
	SECTION DATA
	even

	FILE "export\black_ticker.bin",black_ticker                     ; Black "ticker" image
	FILE "export\c64_charset_converted.pi3",c64_charset_128x128     ; C64 character set


; MARK: News title entries
; Here are all the small images (476x11) used to display titles to the news ticker
; Font used is "Spartan Light" Bold in size 7
	FILE "export\news_title_placeholder.bin",news_title_placeholder 				; News title: Placeholder
	FILE "export\news_title_breaking_news.bin",news_title_breaking_news 			; News title: Breaking news
	FILE "export\news_title_useful_information.bin",news_title_useful_information 	; News title: Useful information
	FILE "export\news_title_weather.bin",news_title_weather 						; News title: Weather forecast
	FILE "export\news_title_now_playing.bin",news_title_now_playing 				; News title: Now Playing
	FILE "export\news_title_greetings.bin",news_title_greetings 				; News title: Now Playing
	FILE "export\news_title_credits.bin",news_title_credits 				; News title: Now Playing


; MARK: News content entries
; Here are all the larger images (476x30) with the actual news ticker content
; Font used is "Spartan Extra Bold" in size 8
	FILE "export\news_content_placeholder.bin",news_content_placeholder 			; News content: Placeholder
	FILE "export\news_content_encounter.bin",news_content_encounter 				; News content: Encounter
	FILE "export\news_content_mixed_resolution.bin",news_content_mixed_resolution	; News content: Mixed-Resolution
	FILE "export\news_content_weather.bin",news_content_weather						; News content: Weather
	FILE "export\news_content_dbug_attending.bin",news_content_dbug_attending		; News content: Dbug attending
	FILE "export\news_content_music_i_wonder.bin",news_content_music_i_wonder		; News content: Music - I Wonder
	FILE "export\news_content_credits.bin",news_content_credits		; News content: Music - I Wonder
	FILE "export\news_content_greetings.bin",news_content_greetings		; News content: Music - I Wonder


; MARK: Multipalette images
; These are the large images moving around and distorting on the left side
; 6400 bytes of palette followed by 32000 bytes of bitmap data
	FILE "export\sommarhack_multipalette.bin",sommarhack_multipalette				; Sommarhack logo
	FILE "export\oxygen_multipalette.bin",oxygen_multipalette						; Oxygen album image with the earth
	FILE "export\peace_multipalette.bin",peace_multipalette							; Love and peace logo
	FILE "export\nuclear_multipalette.bin",nuclear_multipalette						; Nuclear symbol
	FILE "export\tribunal_multipalette.bin",tribunal_multipalette					; International Penal Court image
	FILE "export\hal9000_multipalette.bin",hal9000_multipalette					    ; HAL 9000 image

; The medium resolution file panel on the right
	FILE "export\chat_panel.bin",chat_panel				                            ; Max 26 lines of text	

; The bottom right logo
	FILE "export\tvlogo_black.bin",tvlogo_black       				; TV canal: all black
	FILE "export\tvlogo_blank.bin",tvlogo_blank       				; TV canal: White background
	FILE "export\tvlogo_placeholder.bin",tvlogo_placeholder			; TV canal: Placeholder
	FILE "export\tvlogo_scenesat.bin",tvlogo_scenesat     			; TV canal: SceneSat logo

	FILE "export\sommarhack_tiny_logo.bin",sommarhack_tiny_logo		; TV canal: SceneSat logo

; Music tracks
	FILE "data\music_comic_bakery.sndh",music_comic_bakery		; Music: "Comic Bakery" by Mad Max
	FILE "data\music_i_wonder.sndh",music_i_wonder				; Music: "I wonder" by XiA
	FILE "data\music_oxygene_4.sndh",music_oxygene				; Music: "Oxygene from Jean Michel Jarre" by XiA

; 649x69 = 160*60 = 11040
; 11048 bytes
sommarhack_logo
	;incbin "export\sommarhack_logo.bin"

sine_255				; 16 bits, unsigned between 00 and 127
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"

 even

; Unpacked:  9536  Packed:    4769
packed_chatroom_sample_start 
	incbin "data\keyboard.dlt"
packed_chatroom_sample_end

 even

Prng32	        				dc.l $12345678			; random number store

TableKeyboardSounds
	dc.w 0,1598
	dc.w 1598,2696
	dc.w 2696,3922
	dc.w 3922,5221
	dc.w 5001,5889
	dc.w 5861,7041
	dc.w 6989,8293
	dc.w 8281,9533

DepackDeltaTable
	REPT 16
	dc.b -64
	dc.b -32
	dc.b -16
	dc.b -8
	dc.b -4
	dc.b -2
	dc.b -1
	dc.b 0
	dc.b 1
	dc.b 2
	dc.b 4
	dc.b 8
	dc.b 16
	dc.b 32
	dc.b 64
	dc.b 127
	ENDR

	even


; 38400 bytes per picture
PictureGradientTable
 REPT 13
 dc.l 0*38400
 ENDR

 dc.l 1*38400
 dc.l 0*38400
 dc.l 0*38400
 dc.l 0*38400
 dc.l 1*38400
 dc.l 1*38400
 dc.l 0*38400
 dc.l 0*38400
 dc.l 1*38400
 dc.l 1*38400
 dc.l 1*38400
 dc.l 0*38400 ; 12
  
 REPT 13
 dc.l 1*38400
 ENDR

 dc.l 2*38400
 dc.l 1*38400
 dc.l 1*38400
 dc.l 1*38400
 dc.l 2*38400
 dc.l 2*38400
 dc.l 1*38400
 dc.l 1*38400
 dc.l 2*38400
 dc.l 2*38400
 dc.l 2*38400
 dc.l 1*38400
  
 REPT 13
 dc.l 2*38400
 ENDR

 dc.l 3*38400
 dc.l 2*38400
 dc.l 2*38400
 dc.l 2*38400
 dc.l 3*38400
 dc.l 3*38400
 dc.l 2*38400
 dc.l 2*38400
 dc.l 3*38400
 dc.l 3*38400
 dc.l 3*38400
 dc.l 2*38400
  
 REPT 13
 dc.l 3*38400
 ENDR

 dc.l 4*38400
 dc.l 3*38400
 dc.l 3*38400
 dc.l 3*38400
 dc.l 4*38400
 dc.l 4*38400
 dc.l 3*38400
 dc.l 3*38400
 dc.l 4*38400
 dc.l 4*38400
 dc.l 4*38400
 dc.l 3*38400
  
 REPT 13
 dc.l 4*38400
 ENDR

 dc.l 0*38400
 dc.l 4*38400
 dc.l 4*38400
 dc.l 4*38400
 dc.l 0*38400
 dc.l 0*38400
 dc.l 4*38400
 dc.l 4*38400
 dc.l 0*38400
 dc.l 0*38400
 dc.l 0*38400
 dc.l 4*38400
 
 ;
 REPT 50
 dc.l 0*38400
 dc.l 0*38400
 ENDR
 




 
 
var set 0
 REPT 128
 dc.l ((var*5)/128)*38400
var set var+1 
 ENDR


NotASteMessage
 	dc.b 27,"E","This demo works only on STE or MegaSTE,",10,13,"with a color screen",0

	even

; These are pointers that can be replaced
news_title_palette		dc.l black_ticker
news_title_bitmap		dc.l black_ticker+32

news_content_palette	dc.l black_ticker
news_content_bitmap		dc.l black_ticker+32

displayList_image       dc.l sommarhack_multipalette

; MARK: - BSS -
	SECTION BSS

	even

bss_start

CurrentImage	ds.l 1

settings        		ds.b 256
machine_is_ste			ds.b 1 		; We only run on STe type machines
machine_is_megaste 		ds.b 1 		; MegaSTe is possibly supported, with Blitter timing fixes

flag_vbl	 			ds.b 1	; Set to true at the end of the main screen handling interupt

	even
black_palette			ds.w 16     ; These two should stay black
blank_scanline          ds.w 224    ; Probably more like 224 bytes, but does not care
screen_buffer			ds.b 160*276+256

screen_buffer_bottom    ds.b 224*21  ; The 21 last lines
						ds.b 224*10  ; Security crap (in case for some reason we see more of the content)

	even

; Various types of contents in a Display List:
; - Line adress (4) + pixel shift (1->2)
; - Palette pointer (4)
DisplayList_Top	ds.b 400*(4+4)	; Security crap
DisplayList		ds.b 276*(4+4)	; Screen Pointer + Pixel offset + Palette adress, for each line
 				ds.b 400*(4+4)	; Security crap

chatroom_sample_start			ds.b 9536
chatroom_sample_end				ds.b 16				; Some padding to handle the alignment issues

	even

message_screen_base_ptr ds.l 1
message_screen_ptr		ds.l 1
message_source_ptr      ds.l 1
message_screen_offset 	ds.w 1
message_screen_width	ds.w 1  
message_max_lines       ds.w 1
message_cur_lines       ds.w 1


SineOffsets		ds.l 512*2

piracy_table_sine_16		ds.b 256*2				; Doubled sine table with values in the 0-15 range
piracy_table_sine_64		ds.b 256*2				; Doubled sine table with values in the 0-63 range

piracy_sync_angle			ds.w 1
piracy_sync_angle2			ds.w 1
piracy_sync_angle3			ds.w 1
piracy_sync_angle4			ds.w 1


bss_end       	ds.l 1 						; One final long so we can clear stuff without checking for overflows

	end

 