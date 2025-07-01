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

enable_music  		equ 0

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

.loop_forever
	bra.s	.loop_forever		; infinite wait loop
exit                            ; We actual come back here from anywhere, including IRQs
  ifne enable_music
	jsr Music+4                 ; Stop music
	jsr YmSilent
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

	; Set the current image
	move.l #sommarhack_multipalette,CurrentImage

	; Initialize the text
	move.l #medium_rez+8+20,message_screen_ptr
	move.l #92,message_screen_width
	move.l #0,message_screen_offset

 ifne 0
	lea MessageEaster1,a0

	moveq #0,d0
	bsr PrintMessage2 	 ; Brought to you by...

	moveq #0,d0
	bsr PrintMessage2   ; Software:
 endc

	; Initialize the music	 
 ifne enable_music
	moveq #1,d0             ; Subtune number
	jsr Music+0             ; Init music
  endc

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


semi_black_palette
	dc.w $000,$700,$070,$777
	dcb.w 16


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
	rts

; MARK: Defines

SET_NEWS_TITLE macro
	move.l #\1,news_title_palette
	move.l #\1+32,news_title_bitmap
	endm


SET_NEWS_CONTENT macro
	move.l #\1,news_content_palette
	move.l #\1+32,news_content_bitmap
	endm


; MARK: Demo Sequence
DemoSequence	
	; Patch colors to hide the input panel
	;move.l #$00000000,_patch_color_red_green
	move.l #$00000000,_patch_color_green_white

	move.w #50*2,d0
	jsr WaitDelay

	lea MessageEaster1,a0

	moveq #0,d0
	bsr PrintMessage2 	 ; Brought to you by...

	move.w #50*2,d0
	jsr WaitDelay

	; Enable the breaking news logo
	jsr WaitVbl
	SET_NEWS_TITLE news_title_placeholder

	;rts

	move.w #50*2,d0
	jsr WaitDelay

	jsr WaitVbl
	moveq #0,d0
	bsr PrintMessage2   ; Software:

	; Show the "Place holder" news ticker
	jsr WaitVbl
	SET_NEWS_CONTENT news_content_placeholder

	move.w #50*2,d0
	jsr WaitDelay

	; Show the "Encounter sales" news ticker
	jsr WaitVbl
	SET_NEWS_TITLE news_title_breaking_news
	SET_NEWS_CONTENT news_content_encounter

	move.w #50*2,d0
	jsr WaitDelay

	; Enable the weather forecast ticker
	jsr WaitVbl
	SET_NEWS_TITLE news_title_weather
	SET_NEWS_CONTENT news_content_weather

	move.w #50*2,d0
	jsr WaitDelay

	jsr WaitVbl
	moveq #0,d0
	bsr PrintMessage2   ; Software:

	; Bring the background to life
	lea semi_black_palette,a0 			; 100% black palette
	jsr InitializeEmptyDisplayList
	move.l #$0f0000f0,_patch_color_red_green
	move.l #$00f00fff,_patch_color_green_white

	move.w #50*2,d0
	jsr WaitDelay

	jsr WaitVbl
	moveq #0,d0
	bsr PrintMessage2   ; Software:

	; Enable the main distorter event
	move.l #UpdateDisplayList,_patch_update

	; Loop the news ticker
.loop_news
	; Weather forecast for Sommarhack
	jsr WaitVbl
	SET_NEWS_TITLE news_title_weather
	SET_NEWS_CONTENT news_content_weather

	move.w #50*5,d0
	jsr WaitDelay

	; Sommarhack mixed resolution information
	jsr WaitVbl
	SET_NEWS_TITLE news_title_useful_information
	SET_NEWS_CONTENT news_content_mixed_resolution

	move.w #50*5,d0
	jsr WaitDelay

	jsr WaitVbl
	SET_NEWS_TITLE news_title_breaking_news
	SET_NEWS_CONTENT news_content_dbug_attending

	move.w #50*5,d0
	jsr WaitDelay

	bra .loop_news


	rts



; Various types of contents in a Display List:
; - Line adress (4) + pixel shift (1->2)
; - Palette pointer (4)
UpdateDisplayList
	lea DisplayList,a6        ; Target

	lea sine_255,a5           ; 16 bits, unsigned between 00 and 127
	add.w sine_offset_y,a5
	add.w #2,sine_offset_y
	and.w #511,sine_offset_y
	move.w (a5),d0            ; 0-127
	lsr.w #1,d0               ; 0-64
	lsl.w #3,d0               ; x8
	add.w d0,a6               ; Vertical bounce

	lea SineOffsets,a5        ; movep format
	add.w sine_offset_x,a5
	add.w #4,sine_offset_x
	and.w #1023,sine_offset_x

	lea oxygen_multipalette,a0 ; Palette
	;lea sommarhack_multipalette,a0
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
	

; Image is 200 pixels tall
; Overscan is 276 pixels tall
; 276-200=76
; 128/2 -> 64
sine_offset_x	dc.w 0
sine_offset_y   dc.w 0


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
	jsr Music+8             ; Play music
	;move.w #$333,$ffff8240.w
 endc 

	movem.l (sp)+,d0-d7/a0-a6

	st flag_vbl
	bclr.b	#5,$fffffa0f.w
	rte


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

	move.l #medium_rez+8,a0			; 3
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
	lea $ffff8240.w,a5    			; 2 palette
	move.l d6,(a5)                  ; 3 clear the two first color registers
  	move.l d6,4(a5)                 ; 4 clear the next two color registers
	pause 13-3
  	move.w d5,6(a5)                 ; 3 restore the WHITE color

	movep.l d1,-5(a6)		    	; 6 $ffff8205/07/09/0B
	nop
	move.b #0,91(a6)				; 4 $ffff8265
	move.b #1,$ffff8260.w   		; 4 Medium resolution
  	move.l d3,2(a5)                 ; 4 restore the RED and GREEN colors

	pause 13-4 ;-4
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
	pause 82-3-1-6
	lea (12+30)*8(a3),a3            ; 2 Skip the news ticker section
	move.l (a3)+,d0                 ; 3 Screen value
	move.l (a3)+,a4                 ; 3 Palette

	move.l #scene_sat_logo+8,a0			; 3
	move.l a0,d1					; 1
	lsl.l #8,d1                     ; 6

		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3

	; --------------------------------------------------
	; Code for scanlines 229-272
	; --------------------------------------------------
	REPT 44-23
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

	move.l (a3)+,d0                 ; 3 Screen value
	move.l (a3)+,a4                 ; 3 Palette

	pause 22

	movep.l d1,-5(a6)		    	; 6 $ffff8205/07/09/0B
	nop
	move.b #1,$ffff8260.w   		; 4 Medium resolution
	move.b #0,91(a6)				; 4 $ffff8265
	add.l #92<<8,d1                ; 4

	pause 13 ;-4
		;move.w #$700,$ffff8246.w  ; 4 =============

		move.w	d7,$ffff820a.w			;3 Right border
		move.b	d7,$ffff820a.w			;3
	ENDR

	; MARK: Display end
	move.w #$000,$ffff8240.w

_patch_update = *+2
	jsr DoNothing
	;jsr UpdateDisplayList
	;move.w #$000,$ffff8240.w

	; Overscan end
	movem.l	(sp)+,d0-a6
	move.w	#$2300,sr
	rte


	opt o+



; a0 = message
; d0 = x coordinate
; message_screen_ptr=scanline screen location
PrintMessage2
 movem.l d1/d2/d3/d4/d5/d6/a1/a2/a3,-(sp)

	move.l #$00030001,d6

 move.l message_screen_offset,d5
 move.l message_screen_ptr,a1
 add d0,a1

 moveq #0,d4
print_message_loop
 moveq #0,d1
 move.b (a0)+,d1
 beq print_message_end

 cmp #1,d1
 bne .no_carriage_return
 move.l message_screen_width,d1
 lsl.l #3,d1
 add.l d1,message_screen_ptr
 add.l d1,a1 
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
 add.l message_screen_width,a3
var set var+1  
 endr 
 add.w d6,a1
 add.w d6,d0
 swap d6

 opt o-
PrintMessageCallback
 jsr DoNothing
 opt o+

 bra print_message_loop

print_message_end
 movem.l (sp)+,d1/d2/d3/d4/d5/d6/a1/a2/a3
 rts


MessageEaster1  dc.b "Brought to ",255,"you",255," by...   ",0
MessageEaster2  dc.b 1,1,"Software:",0
MessageEaster3  dc.b 1,"Fred Bowen",0
MessageEaster4  dc.b 1,"Terry Ryan",0
MessageEaster5  dc.b 1,"Von Ertwine",0
MessageEaster6  dc.b 1,1,"Herdware:",0
MessageEaster7  dc.b 1,"Bill Herd",0
MessageEaster8  dc.b 1,"Dave Haynie",0
MessageEaster9  dc.b 1,"Frank Palaia",0
MessageEaster10  dc.b 1,1,255,"Link arms, don't make them.",0
MessageEaster11  dc.b 1,1,"ready.",0



; MARK: - DATA -
	SECTION DATA

medium_rez
	incbin "export\midrez_panel.bin"


	FILE "export\black_ticker.bin",black_ticker                     ; Black "ticker" image
	FILE "export\scenesat_logo_black.bin",scenesat_logo_black       ; Black tv canal image
	FILE "export\c64_charset_converted.pi3",c64_charset_128x128     ; C64 character set


; MARK: News title entries
; Here are all the small images (476x11) used to display titles to the news ticker
; Font used is "Spartan Light" Bold in size 7
	FILE "export\news_title_placeholder.bin",news_title_placeholder 				; News title: Placeholder
	FILE "export\news_title_breaking_news.bin",news_title_breaking_news 			; News title: Breaking news
	FILE "export\news_title_useful_information.bin",news_title_useful_information 	; News title: Useful information
	FILE "export\news_title_weather.bin",news_title_weather 						; News title: Weather forecast


; MARK: News content entries
; Here are all the larger images (476x30) with the actual news ticker content
; Font used is "Spartan Extra Bold" in size 8
	FILE "export\news_content_placeholder.bin",news_content_placeholder 			; News content: Placeholder
	FILE "export\news_content_encounter.bin",news_content_encounter 				; News content: Encounter
	FILE "export\news_content_mixed_resolution.bin",news_content_mixed_resolution	; News content: Mixed-Resolution
	FILE "export\news_content_weather.bin",news_content_weather						; News content: Weather
	FILE "export\news_content_dbug_attending.bin",news_content_dbug_attending		; News content: Dbug attending


; MARK: Multipalette images
; These are the large images moving around and distorting on the left side
; 6400 bytes of palette followed by 32000 bytes of bitmap data
	FILE "export\sommarhack_multipalette.bin",sommarhack_multipalette				; Sommarhack logo
	FILE "export\oxygen_multipalette.bin",oxygen_multipalette						; Oxygen album image with the earth
	FILE "export\peace_multipalette.bin",peace_multipalette							; Love and peace logo
	FILE "export\nuclear_multipalette.bin",nuclear_multipalette						; Nuclear symbol
	FILE "export\tribunal_multipalette.bin",tribunal_multipalette					; International Penal Court image




scene_sat_logo
	incbin "export\scenesat_logo.bin"

; 649x69 = 160*60 = 11040
; 11048 bytes
sommarhack_logo
	;incbin "export\sommarhack_logo.bin"

sine_255				; 16 bits, unsigned between 00 and 127
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"


Music
	incbin "data\SOS.SND"



NotASteMessage
 	dc.b 27,"E","This demo works only on STE or MegaSTE,",10,13,"with a color screen",0

	even

; These are pointers that can be replaced
news_title_palette		dc.l black_ticker
news_title_bitmap		dc.l black_ticker+32

news_content_palette	dc.l black_ticker
news_content_bitmap		dc.l black_ticker+32

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

	even

; Various types of contents in a Display List:
; - Line adress (4) + pixel shift (1->2)
; - Palette pointer (4)
DisplayList_Top	ds.b 400*(4+4)	; Security crap
DisplayList		ds.b 276*(4+4)	; Screen Pointer + Pixel offset + Palette adress, for each line
 				ds.b 400*(4+4)	; Security crap

	even

message_screen_offset 	ds.l 1
message_screen_width	ds.l 1  
message_screen_ptr		ds.l 1

SineOffsets		ds.l 512*2


bss_end       	ds.l 1 						; One final long so we can clear stuff without checking for overflows

	end

 