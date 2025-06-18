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

enable_music  equ 0

alignment_marker equ $010     ; Green


KEY_SPACE	 	equ $39 
KEY_ARROW_LEFT	equ $4b
KEY_ARROW_RIGHT equ $4d

dbra_time       equ 4
dbra_time_loop  equ 3


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
 	; We call the main routine in supervisor mode
	; and when we come back, we return to the caller 
	move.l #super_main,-(sp)
	move.w #$26,-(sp)         ; XBIOS: SUPEXEC
	trap #14
	addq.w #6,sp

	clr.w -(sp)               ; GEMDOS: PTERM(0)
	trap #1

super_main
	move.l sp,usp               ; Save the stack pointer
	bsr SaveSettings
	bsr Initialization
.loop_forever
	bra.s	.loop_forever		; infinite wait loop
exit                            ; We actual come back here from anywhere, including IRQs
	move.w #$2700,sr            ; We just don't care, just restore the stack pointer and we are all good
	move.l usp,sp				; Restore the stack pointer
	bsr RestoreSettings
	move.w #$2300,sr
	rts

SaveSettings
	lea settings,a0
	move.l	$ffff8200.w,(a0)+
	move.b	$ffff820a.w,(a0)+
	move.b	$ffff8260.w,(a0)+
	move.l	$68.w,(a0)+
	move.l	$70.w,(a0)+
	move.l	$120.w,(a0)+
	move.l	$134.w,(a0)+
	move.b	$fffffa07.w,(a0)+
	move.b	$fffffa09.w,(a0)+
	movem.l $ffff8240.w,d1-d7/a1
	movem.l d1-d7/a1,(a0)
	rts

RestoreSettings
	lea settings,a0
	move.l	(a0)+,$ffff8200.w
	move.b	(a0)+,$ffff820a.w
	move.b	(a0)+,$ffff8260.w
	move.l	(a0)+,$68.w
	move.l	(a0)+,$70.w
	move.l	(a0)+,$120.w
	move.l	(a0)+,$134.w
	move.b	(a0)+,$fffffa07.w
	move.b	(a0)+,$fffffa09.w
	movem.l (a0)+,d1-d7/a1
	movem.l d1-d7/a1,$ffff8240.w
	clr.b	$fffffa19.w
	clr.b	$ffff820a.w

  ifne enable_music
	jsr Music+4             ; Stop music
	jsr YmSilent
  endc
	rts


SetScreen
	lea $ffff8201.w,a0               	; Screen base pointeur (STF/E)
	move.l #screen_buffer+256,d0
	clr.b d0
	lsr.l #8,d0					        ; Allign adress on a byte boudary for STF compatibility
	movep.w d0,0(a0) 
	sf.b 12(a0)					        ; For STE low byte to 0
	rts


YmSilent
	move.b #8,$ffff8800.w		; Volume register 0
	move.b #0,$ffff8802.w      	; Null volume
	move.b #9,$ffff8800.w		; Volume register 1
	move.b #0,$ffff8802.w      	; Null volume
	move.b #10,$ffff8800.w		; Volume register 2
	move.b #0,$ffff8802.w      	; Null volume
	rts


Initialization
	bsr FillScreen
	bsr SetScreen
	;jsr HandleDemoTrack

 ifne enable_music
	moveq #1,d0             ; Subtune number
	jsr Music+0             ; Init music
  endc

	clr.b	$fffffa07.w		; iera
	clr.b	$fffffa09.w		; ierb

	clr.b	$fffffa19.w		; timer A - stop
	clr.b	$fffffa1b.w		; timer B - stop

	lea	VblHandler(pc),a0
	move.l	a0,$70.w

	moveq	#0,d0
	lea	$ffff820a.w,a0
	lea	$ffff8260.w,a1
	stop	#$2300
	move.b	d0,(a1)
	move	a0,(a0)
	rts



VblHandler:
	movem.l d0-d7/a0-a6,-(sp)

	; Keyboard handling
	btst #0,$fffffc00.w
	beq end_key

	move.b $fffffc02.w,d0

	cmp.b #KEY_SPACE,$fffffc02.w
	beq	exit
end_key	

	;
	; Demo part is here
	;
	lea $ffff8240.w,a6
	lea Whatever,a0

_auto_jsr	
	jsr DemoWhatever

 ifne enable_music
	;move.w #$700,$ffff8240.w
	jsr Music+8             ; Play music
	;move.w #$333,$ffff8240.w
 endc 

	movem.l (sp)+,d0-d7/a0-a6

	bclr.b	#5,$fffffa0f.w
	rte




DoNothing
	rts


DemoWhatever

	; First palette change
	lea sommarhack_pictconv,a0
	lea $ffff8240.w,a1
	REPT 8
	move.l (a0)+,(a1)+
	ENDR


	; Wait for the screen start
	move #$100,$ffff8240.w
	moveq #16,d0
.wait_sync
	move.b $ffff8209.w,d1
	beq.s .wait_sync
	sub.b d1,d0
	lsl.b d0,d1
	move #$222,$ffff8240.w
	pause 80



	; Palette change test
	move.w #200,d7
.loop_resol_change
	lea $ffff8240.w,a1
	REPT 8
	move.l (a0)+,(a1)+
	ENDR
	move #alignment_marker,$ffff8240.w   ; Green horizontal band
	pause 82-dbra_time_loop
	dbra d7,.loop_resol_change

	move.w #$000,$ffff8240.w
	rts


FillScreen
	move.l #screen_buffer+256,d0
	clr.b d0
	move.l d0,a0
	move.l #sommarhack_pictconv+6400,a1

	move.w #200-1,d7
.loop
	; 160 bytes per scanline
	; /4 = 40 bytes per bitplane
	REPT 40
	move.l (a1)+,(a0)+
	ENDR
	
	dbra d7,.loop	

	rts


; MARK: - DATA -
	SECTION DATA

; 38400
; 32000+6400
sommarhack_pictconv
	incbin "export\sommarhack_multipalette.bin"

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

settings        ds.b    256
screen_buffer	ds.b	160*276+256

	even


Whatever	 		ds.l 1

	end

 