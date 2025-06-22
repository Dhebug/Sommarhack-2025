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
; $FF8201|byte |Video screen memory position (High byte)             |R/W
; $FF8203|byte |Video screen memory position (Mid byte)              |R/W
; $FF820D|byte |Video screen memory position (Low byte)              |R/W  (STe)
; 
; $FF8205|byte |Video address pointer (High byte)                    |R (R/W STe)
; $FF8207|byte |Video address pointer (Mid byte)                     |R (R/W STe)
; $FF8209|byte |Video address pointer (Low byte)                     |R (R/W STe)
; $FF820B|byte 

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

SuperMain
	move.l sp,usp               ; Save the stack pointer
	move.w #$2700,sr
	bsr SaveSettings
	bsr Initialization
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
	move.b	$fffffa07.w,(a0)+   ; iera
	move.b	$fffffa09.w,(a0)+   ; ierb
	move.b	$fffffa19.w,(a0)+   ; tacr
	move.b	$fffffa1b.w,(a0)+   ; tbcr
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
	move.b	(a0)+,$fffffa07.w   ; iera
	move.b	(a0)+,$fffffa09.w   ; ierb
	move.b	(a0)+,$fffffa19.w   ; tacr
	move.b	(a0)+,$fffffa1b.w   ; tbcr
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

	; Set the current image
	move.l #sommarhack_multipalette,CurrentImage

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
 	
	move.l #VblHandler,$70.w        ; set the VBL handler

	; Waits for the VBL, and change the resolution to avoid glitches
	stop #$2300
	move.b #2,$ffff820a.w   ; 50hz
	move.b #0,$ffff8260.w   ; Low resolution
	rts


DummyHbl
	rte

DoNothing
	rts

; MARK: VBL Handler
VblHandler:
	; Prepare the Timer-A in charge of opening the top border
	clr.b	$fffffa19.w			; timer-a setup
	move.b	#99,$fffffa1f.w		; tadr: delay
	move.b	#4,$fffffa19.w		; tacr: divider -> Starts the timer

	movem.l d0-d7/a0-a6,-(sp)

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
	move.l (a5)+,(a6)+
	ENDR

 ifne enable_music
	;move.w #$700,$ffff8240.w
	jsr Music+8             ; Play music
	;move.w #$333,$ffff8240.w
 endc 

	movem.l (sp)+,d0-d7/a0-a6

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
TimerAHandler
	opt o-

	pause 41

	move.w #$2100,sr			; Wait for the next hardware HBL
	stop #$2100
	move.w #$2700,sr			; Disable interrupts
	clr.b $fffffa19.w			; stop timer a

	movem.l d0-a6,-(sp)
	pause 51  ;52-2-2-3-3-4+3+3+3+2+2

	move.b	#0,$ffff820a.w		; remove top border
	pause 9
	move.b	#2,$ffff820a.w

	; STE hardware compatible synchronization code
 	move.b #0,$ffff8209.w
 
	; Wait for the screen start
	move #$100,$ffff8240.w
	moveq #16,d0
.wait_sync
	move.b $ffff8209.w,d1
	beq.s .wait_sync
	sub.b d1,d0
	lsl.b d0,d1

	pause 50
	move.l CurrentImage,d0
	add.l #6400,d0
	lsl.l #8,d0
    lea $ffff8205.w,a1    		; 8/2 frequence
	movep.l d0,0(a1)		    ; (6) $ffff8205/07/09/0B

	move #$222,$ffff8240.w

	; Palette change test
	move.l CurrentImage,a5
	;lea 32(a5),a5
	move.w #200-1,d7
.loop_resol_change
	lea $ffff8240.w,a6
	REPT 8
	move.l (a5)+,(a6)+
	ENDR
	move #alignment_marker,$ffff8240.w   ; Green horizontal band
	pause 82-dbra_time_loop
	dbra d7,.loop_resol_change

	; Force the palette to black at the end
	lea $ffff8240.w,a6
	REPT 8
	move.l #0,(a6)+
	ENDR

	movem.l (sp)+,d0-a6
	rte

	opt o+


; MARK: - DATA -
	SECTION DATA

; 38400
; 32000+6400
sommarhack_multipalette
	incbin "export\sommarhack_multipalette.bin"

oxygen_multipalette
	incbin "export\oxygen_multipalette.bin"

peace_multipalette
	incbin "export\peace_multipalette.bin"

nuclear_multipalette
	incbin "export\nuclear_multipalette.bin"

tribunal_multipalette
	incbin "export\tribunal_multipalette.bin"

sine_255				; 16 bits, unsigned between 00 and 127
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"
	incbin "data\sine_255.bin"


Music
	incbin "data\SOS.SND"

	even

; MARK: - BSS -
	SECTION BSS

	even

bss_start:

CurrentImage	ds.l 1

settings        ds.b    256
screen_buffer	ds.b	160*276+256


	even



	end

 