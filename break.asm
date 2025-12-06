; =============================================================
; Breakout Clone - Converted for NASM .COM format (DOSBox)
; Compile with: nasm -f bin breakout.asm -o breakout.com
; =============================================================

org 100h            ; .COM programs always start at offset 100h


    jmp start       ; Jump over data to the main code

; -------------------------------------------------------------
; DATA SECTION (Initialized Variables)
; -------------------------------------------------------------
ErrorMsg:    db 'Error Occured', 13, 10, '$'
final_score_accumulator: dw 0  ; <--- ADD THIS LINE

padmov:      dw 0
ballSpeedx:      dw 1   
ballSpeedy:      dw -2 
timeadder:   dw 2
note:        dw 1387 
x:           dw 0
y:           dw 0
savekey:     db 0 
count:       dw 0
tempx:       dw 0 
ballminy:    dw 0
ballmaxy:    dw 0  
padminx:     dw 0
padmaxx:     dw 0 
savedcolor:  db 0
pady:        dw 185 
ballx:       dw 0 
bally:       dw 0 
ballrightx:  dw 0 
balltopy:    dw 0 
balldowny:   dw 0 
ballleftx:   dw 0
ballmiddlex: dw 0 
balltempy:   dw 0
balltempx:   dw 0 
counter:     dw 10     
timerballSpeed:  dw 12 
cubcolor:    dw 0 
linecounter: dw 0  
gamewinbol:  dw 0 
gameoverbol: dw 0
brickcounter: dw 0
destroyedbricks: dw 0  
lifecounter: dw 3 

; Strings
life3:   db 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,"   lifes left : 3$"  
life2:   db 13,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,"   lifes left : 2$" 
life1:   db 13,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,"   lifes left : 1$" 
ballSpeed:       db "      ballSpeed:$"
dollar:      times 3 db '$' 

secounter:   dw 0 
milisecounter: dw 0 
startx:      dw 0 
starty:      dw 0 
cheatx:      dw -1 
cheaty:      dw 0 
wallbol:     dw 0 
ballSpeedbol:    dw 0 
brickbol:    dw 0 
fasterbol:   dw 0 
slowbol:     dw 0
fastestball: dw 2 
keybol:      dw 1  
filehandle:  dw 0

; --- Message Text ---
rules_msg:   db 'Controls:', 13, 10
             db '  <- Left Arrow: Move Paddle Left', 13, 10
             db '  -> Right Arrow: Move Paddle Right', 13, 10
             db '  [ESC]: Pause Game (Press again to resume)', 13, 10, 13, 10
             db 'Game Status:', 13, 10
             db '  Lives: Start with 3. Game Over at 0.', 13, 10
             db '  final_score: Bricks destroyed (32 total)', 13, 10, 13, 10
             db 'Press [ENTER] to START GAME', 13, 10
             db 'Press [ESC] to EXIT Program', '$'

gameover_msg: db 'G A M E  E N D', 13, 10
              db 'Press any key to exit.', 13, 10, '$'
victory_msg: db 'V I C T O R Y', 13, 10
             db 'Press any key to exit.', 13, 10, '$'

final_score_label: db 'final_score: ', '$'
final_score_buffer: db '000', 13, 10, '$' ; Buffer for three digits (000)

; -------------------------------------------------------------
; CODE SECTION
; -------------------------------------------------------------

; -------------------------------------------------------------
; FINAL REVISED SUBROUTINE: ShowFinalfinal_score (Handles 3 Digits)
; -------------------------------------------------------------
ShowFinalfinal_score:
    push ax
    push bx
    push cx
    push dx

    ; 1. Set cursor position (Keep it where it is, or move left slightly for 3 digits)
    mov ah, 02h  ; Set Cursor Position
    mov bh, 0    ; Page 0
    mov dh, 22   ; Row
    mov dl, 28   ; Column: Moved slightly left (was 30) for 3 digits
    int 10h
    
    ; 2. Print "final_score: " label
    mov dx, final_score_label
    mov ah, 09h
    int 21h

    ; 3. Prepare final_score for conversion (max 320, needs 3 digits)
    mov ax, [final_score_accumulator] ; Load the calculated total final_score (0-320)
    mov bl, 10                ; Divisor (10)

    ; --- CALCULATE UNITS DIGIT ---
    xor ah, ah                ; Clear AH for division
    div bl                    ; AX / 10 -> AL=Quotient, AH=Remainder (Units)
    mov byte [final_score_buffer+2], ah; Save Units digit to buffer (position 2)
    
    ; AL now holds the remaining two digits (0-32). Move to AH for next division.
    mov ah, 0                   ; Prepare for next division
    mov al, al                  ; AL still holds the quotient (0-32)
    
    ; --- CALCULATE TENS DIGIT ---
    div bl                    ; AX (0-32) / 10 -> AL=Quotient (Hundreds), AH=Remainder (Tens)
    mov byte [final_score_buffer+1], ah; Save Tens digit to buffer (position 1)

    ; --- CALCULATE HUNDREDS DIGIT ---
    mov byte [final_score_buffer+0], al; AL holds the final quotient (0-3), save as Hundreds (position 0)


    ; 4. Convert all three digits to ASCII
    add byte [final_score_buffer+0], '0'   ; Hundreds
    add byte [final_score_buffer+1], '0'   ; Tens
    add byte [final_score_buffer+2], '0'   ; Units

    ; 5. Print the final_score
    mov dx, final_score_buffer
    mov ah, 09h
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax
    ret

ball: 
    mov cx, [ballx] 
    mov [balltempx], cx 
    add cx, 5 
    mov [ballrightx], cx 
    sub cx, 6 
    mov [ballleftx], cx 
    mov cx, [bally] 
    mov [balltempy], cx 
    mov [balltopy], cx 
    add cx, 5  
    mov [balldowny], cx 
    mov cx, [ballx] 
    inc cx 
    mov [ballmiddlex], cx  
    mov ah, 0ch 
    xor bx, bx   
    mov cx, 5   

nextballline:
    push cx 
    cmp cx, 5 
    je ballmaker 
    cmp cx, 1 
    je ballmaker 

    mov cx, [ballx]
    dec cx    
    mov [tempx], cx 
    mov cx, [bally] 
    inc cx 
    mov [bally], cx 
    mov cx, 5       
    jmp balline 

ballmaker:
    mov cx, [ballx]  
    mov [tempx], cx 
    mov cx, [bally] 
    inc cx 
    mov [bally], cx 
    mov cx, 3

balline:
    push cx 
    mov cx, [tempx] 
    mov dx, [bally]
    int 10h
    inc cx 
    mov [tempx], cx 
    pop cx 
    loop balline

    pop cx 
    loop nextballline
    ret 

bricks: 
    mov bx, 0 
    mov dx, -1  
    ; generate random number 
    mov ax, 40h 
    mov es, ax 
    mov ax, [es:0x6C] ; Access BIOS clock
    and al, 255     
    mov [savedcolor], al 
    mov cx, 5 
    mov [linecounter], cx 
cubscreen: 
    push cx
    mov [savedcolor], al 
    add al, cl 
    dec al
    inc dx 
    mov [y], dx 
    mov dx, -1  
    mov [x], dx
    mov cx, 8 

cubline: 
    push cx 
    dec al

    cmp al, 222 
    ja secondblack 
    cmp al, 8 
    je gray 
    cmp al, 7 
    je gray 
    cmp al, 0 
    je black 
    cmp al, 15   
    jae whit  
    jmp next101
    
secondblack:
    mov al, 222 
    jmp next101 
whit:   
    cmp al, 32 
    jae next101 
    add al, 17 
    jmp next101 
gray:
    mov al, 6 
    jmp next101 
black: 
    mov al, 12
next101: 

    inc word [brickcounter] 
    call cube 
     
    pop cx 
    loop cubline
     
    pop cx
    mov [savedcolor], al 
    loop cubscreen
    ret  

cube:
    mov ah, 0ch 
    xor bx, bx  
    mov cx, 40 
cub: 
    push cx  
    mov cx, 10 
    mov dx, [x]
    inc dx 
    mov [x], dx 
    mov dx, [y]   

prp: 
    push cx
    mov cx, [x]
    int 10h
    inc dx ;y 
    pop cx  
    loop prp

    pop cx 
    loop cub
    ret 

finalcheck:
    mov bx, 0 
    mov dx, -1 
    mov cx, 0 
    mov [destroyedbricks], cx  ; Reset destroyedbricks counter to 0
    
    ; REMOVE THIS LINE: mov word [final_score_accumulator], 0 ; DON'T reset final_score here!
    
    mov cx, [linecounter]    
cubscreen2: 
    push cx
    inc dx 
    mov [y], dx 
    mov dx, -1  
    mov [x], dx
    mov cx, 8 

cubline2: 
    push cx 
    mov ah, 0dh 
    xor bx, bx 
    mov cx, [x] 
    mov [startx], cx 
    mov cx, [y] 
    mov [starty], cx  
    mov cx, 40 

cub2: 
    push cx  
    mov cx, 10 
    mov dx, [x]
    inc dx 
    mov [x], dx 
    mov dx, [y]   

prp2: 
    push cx
    mov cx, [x]
    int 10h

    cmp al, 0 
    je stoploop ; Jumps here if brick is destroyed (color 0)
    inc dx ;y 
       
    pop cx  
    loop prp2

    pop cx 
    loop cub2
    jmp nextloop 
stoploop:
    pop cx 
    pop cx 
    mov cx, [startx] 
    mov [x], cx 
    mov cx, [starty] 
    mov [y], cx 
    mov al, 0 
    call cube 
    
    ; -----------------------------------------------------
    ; SCORING MODIFICATION:
    ; Increment the count of destroyed bricks
    inc word [destroyedbricks] 
    
    ; Calculate the total final_score: [destroyedbricks] * 10
    ; The final_score is stored in [final_score_accumulator] to be used by ShowFinalfinal_score.
    mov ax, [destroyedbricks]
    mov bl, 2               ; Each brick is worth 2 points
    mul bl                  ; AX = AL * BL (AL is final_score count, BL is 10)
    mov [final_score_accumulator], ax ; Save the calculated final_score (e.g., 3 bricks * 10 = 30)
    ; -----------------------------------------------------

nextloop: 
    pop cx 
    loop cubline2
     
    pop cx 
    loop cubscreen2
    call realtimefinal_score    ; Update final_score display after brick check
    ret

printboard:
    mov ax, [x] 
    mov [padminx], ax 
    mov al, 14
    mov ah, 0ch 
    mov dx, [pady]  
    mov cx, 48

prpb: 
    push cx
    mov cx, [x]
    int 10h
    inc cx 
    mov [x], cx  
    pop cx  
    loop prpb  
    mov ax, [x]
    mov [padmaxx], ax  
    ret 

cls:
    mov ax, 13h 
    int 10h 
    ret

Beep: 
    in al, 61h
    or al, 00000011b
    out 61h, al
    mov al, 0B6h
    out 43h, al
    mov ax, [note]
    out 42h, al 
    mov al, ah
    out 42h, al 
    mov cx, 8 
beeeeeeeeeeeeep:
    push cx 
    call keycheck
    call DelayProc
    pop cx 
    loop beeeeeeeeeeeeep
    in al, 61h
    and al, 11111100b
    out 61h, al
    ret

paintcorrection:
    mov ah, 0dh 
    mov cx, 0 
    mov [x], cx 
    mov [savedcolor], cl 
    mov dx, [pady] 
    mov cx, 319

mispaint: 
    push cx 
    mov cx, [x] 
    int 10h 
    inc cx 
    mov [x], cx

    cmp al, [savedcolor]
    jne potantialymissed  
    jmp lop 

potantialymissed:
    int 10h 
    cmp al, [savedcolor]
    jne lop 

    mov ah, 0ch 
    dec cx 
    int 10h 
    mov ah, 0dh
     
lop:
    mov [savedcolor], al
    pop cx 
    loop mispaint
    ret 

keycheck:
waitforkey:
    in al, 64h
    cmp al, 10b 
    je fin
    in al, 60h

    cmp al, 1 
    je fin 

    mov cx, [padmaxx]
    cmp cx, 317
    jae checkforleft

    mov cx, [padminx]
    cmp cx, 3 
    jbe checkforright

checkforleft: 
    cmp al, 0x4b        ; Left Arrow 
    je left

    mov cx, [padmaxx]
    cmp cx, 317    
    jae fin     

checkforright:
    cmp al, 0x4d        ; Right Arrow 
    je right

fin:
    ret 
left:   
    xor bx, bx 
    mov [padmov], bx
    mov dx, [pady] 
    mov ah, 0ch 
    mov al, 14
       
    mov cx, [padminx] 
    sub cx, 4
    mov [padminx], cx 
    mov [x], cx
    mov cx, 4
      
paintleft:
    push cx  
    mov cx, [x] 
    int 10h 
    inc cx
    mov [x], cx 
    pop cx 
    loop paintleft

    mov al, 0 
     
    mov cx, [padmaxx]
    sub cx, 4  
    mov [padmaxx], cx
    mov [x], cx
    mov cx, 4
    jmp delright
  
delright:
    push cx  
    mov cx, [x] 
    int 10h 
    inc cx
    mov [x], cx 
    pop cx 
    loop delright

    call paintcorrection
    ret 

right: 
    mov ax, 1 
    mov [padmov], ax 
    mov dx, [pady] 
    mov ah, 0ch 
    mov al, 0
     
    mov cx, [padminx] 
    add cx, 4
    mov [padminx], cx 
    mov [x], cx
    mov cx, 4
      
delleft:
    push cx  
    mov cx, [x] 
    int 10h 
    dec cx
    mov [x], cx 
    pop cx 
    loop delleft

    mov al, 14 
    mov cx, [padmaxx]
    mov [x], cx
    add cx, 4  
    mov [padmaxx], cx
    mov [x], cx
    mov cx, 4
      
paintright:
    push cx  
    mov cx, [x] 
    int 10h 
    dec cx
    mov [x], cx 
    pop cx 
    loop paintright

    call paintcorrection
    ret  

delball: 
    mov cx, [balltempy]        
    mov [bally], cx
    mov cx, [balltempx]
    mov [ballx], cx      
    mov al, 0 
    call ball
    ret 

timeiskey: 
    mov cx, [timerballSpeed] 
thekey:
    push cx 
    call DelayProc 
    call keycheck
    inc word [milisecounter]
    pop cx 
    loop thekey 
    cmp word [milisecounter], 70 
    jae countsec 
    ret 

countsec:
    mov word [milisecounter], 0 
    inc word [secounter] 
    ret 

addtoball:
    cmp word [ballSpeedy], 0
    jge addtodown
     
    mov ax, [ballSpeedy]  
    add ax, [balltopy]   
    mov [bally], ax 
    jmp after 

addtodown: 
    mov ax, [ballSpeedy]  
    add ax, [balldowny]   
    mov [bally], ax

after:
    cmp word [ballSpeedx], 0
    je nomove 
    jl addtoleft 
    mov ax, [ballrightx] 
    add ax, [ballSpeedx] 
    mov [ballx], ax
    ret

nomove:
    ret 
     
addtoleft:
    mov ax, [ballleftx] 
    add ax, [ballSpeedx] 
    mov [ballx], ax   
    ret 

checkhit: 
checkTHEplace:
    cmp word [ballSpeedy], 0 
    jg checkpadhit
    jl checkupperwall
    ret 
checkupperwall:
    cmp word [balltopy], 6        
    jbe upperWall
    cmp word [ballSpeedx], 0 
    jg checkrightwall 
    jl checkleftwall
    ret 
checkleftwall:
    cmp word [ballleftx],6 
    jbe leftwall
    ret 
checkrightwall: 
    cmp word [ballrightx],314     
    jae rightwall
    ret 
checkpadhit:
    cmp word [balldowny], 174    
    jae padhit
    cmp word [ballSpeedx], 0 
    jg checkrightwall 
    jl checkleftwall
    ret 

upperWall: 
    cmp word [ballSpeedy], 0 
    jl negate2 
    ret 
negate2: 
    mov word [note], 0e1fh 
    call Beep  
    neg word [ballSpeedy]     
    ret 

leftwall:
    mov word [wallbol], 3 
    call delball 
    mov ax, [balltempy] 
    mov [bally], ax 
    mov ax, 6    
    mov [ballx], ax
    mov al, 10
    call ball
    mov word [note], 0e1fh 
    call Beep  
    neg word [ballSpeedx]
    ret 

rightwall:
    mov word [wallbol], 3  
    call delball 
    mov ax, [balltempy] 
    mov [bally], ax 
    mov ax, 314   
    mov [ballx], ax
    mov al, 10
    call ball
    mov word [note], 0e1fh 
    call Beep   
    neg word [ballSpeedx]  
    ret 

padhit:
    cmp word [balldowny], 187  
    jae lost

    call delball 
 
    mov ax, [balltempx] 
    mov [ballx], ax 
    mov ax, 179 
    mov [bally], ax
    mov al, 10
    call ball
 
    mov cx, [padminx]  
    mov [x], cx 
    mov cx, [pady]  
    mov [y], cx
    call printboard
 
    call timeiskey
 
    mov word [note], 0d5ah
    call Beep  
 
    mov ax, [ballmiddlex] 
 
    mov bx, [padminx] 
    sub bx, 2 
    cmp ax, bx  
    jb lost 
 
    mov bx, [padmaxx] 
    add bx, 2    
    cmp ax, bx  
    ja lost 
 
    cmp word [padmov], 0 
    jz left2 
    cmp word [padmov], 1 
    je right2
    ret
lost: 
    mov ax, 1 
    mov [gameoverbol], ax 
    ret 
right2:
    mov ax, [padminx]  
    add ax, 22   
    cmp [ballmiddlex], ax    
    jb leftoftheright
    add ax, 4    
    cmp [ballmiddlex], ax 
    jb middleoftheright 
    add ax, 22  
    cmp [ballmiddlex], ax 
    jbe rightoftheright
    ret  
leftoftheright:
    mov ax, -8       
    mov [ballSpeedy], ax
    mov ax, 1      
    mov [ballSpeedx], ax 
    ret 
middleoftheright:
    mov ax, -4           
    mov [ballSpeedy], ax
    mov ax, 2      
    mov [ballSpeedx], ax 
    ret 
rightoftheright: 
    mov ax, -2    
    mov [ballSpeedy], ax
    mov ax, 6     
    mov [ballSpeedx], ax 
    ret  
    
left2: 
    mov ax, [padminx]    
    add ax, 22 
    cmp [ballmiddlex], ax 
    jb leftoftheleft  
    add ax, 4 
    cmp [ballmiddlex], ax 
    jb middleoftheleft  
    add ax, 22    
    cmp [ballmiddlex], ax
    jbe rightoftheleft 
    ret  
leftoftheleft:
    mov ax, -2    
    mov [ballSpeedy], ax
    mov ax, -6     
    mov [ballSpeedx], ax 
    ret 
middleoftheleft:
    mov ax, -4           
    mov [ballSpeedy], ax
    mov ax, -2      
    mov [ballSpeedx], ax 
    ret 
rightoftheleft: 
    mov ax, -8       
    mov [ballSpeedy], ax
    mov ax, -1      
    mov [ballSpeedx], ax 
    ret                         

; Provides a small delay using the PC timer for timing game loops and effects.
DelayProc: 
    mov cx,1 
    mov dx,3dah
loop11:
    push cx
l1:
    in al,dx
    and al,08h
    jnz l1
l2:
    in al,dx
    and al,08h
    jz l2
    pop cx
    loop loop11
    ret

brickhit:
    cmp word [wallbol], 1 
    jae dontcheck
    cmp word [brickbol], 1 
    jae dontbrick  
    xor bx, bx 
    mov ah, 0dh 
    mov dx, 90 
    mov cx, [ballmiddlex]
    cmp word [balltopy] , 14
    jbe lowercheck
checkbrokenbricks: 
    int 10h 
    cmp al, 0 
    jne nextcheck
    sub dx, 10 
    cmp dx, 0 
    jz bricksof 
    jmp checkbrokenbricks

dontcheck:
    dec word [wallbol] 
    ret 

dontbrick: 
    dec word [brickbol] 
    ret 

bricksof: 
    ret 

nextcheck: 
    add dx, 5   
    cmp [balltopy], dx ;dangerzone 
    jbe posshit 
    ret 
posshit: 
    cmp word [ballSpeedy], 0 
    jl lowercheck   

uppercheck: 
    mov dx, [balldowny]
    add dx, [ballSpeedy]
    jmp nextcheck101 

lowercheck: 
    mov dx, [balltopy]
    add dx, [ballSpeedy]

nextcheck101: 
    cmp word [ballSpeedx], 0 
    jge rightercheck

leftercheck: 
    mov cx, [ballrightx] 
    cmp cx, 8 
    jbe finalcheck2 
    mov cx, [ballleftx]
    cmp cx, 8 
    jbe finalcheck2
    add cx, [ballSpeedx] 
    jmp finalcheck2 

rightercheck:
    mov cx, [ballleftx]
    cmp cx, 312 
    jae finalcheck2
    mov cx, [ballrightx]
    cmp cx, 312 
    jae finalcheck2
    add cx, [ballSpeedx]   

finalcheck2:
    int 10h 
    cmp al, 0 
    jne hit 
    ret 

hit:
    mov [savedcolor], al

xsub:
    int 10h 
    dec cx 
    cmp [savedcolor], al 
    je xsub  

    add cx, 2 
    jmp ysub 

firstbrick: 
    mov cx, 279 
    jmp ysub 

lastbrick:
    mov cx, -1 

ysub:
    int 10h 
    dec dx  
    cmp [savedcolor], al 
    je ysub 

    add dx, 2 
    dec cx 
    mov [x], cx 
    mov [y], dx

    mov al, 0 
    call cube

    cmp word [balltopy], 10 
    jbe check0 

    mov word [note], 0fdah
    call Beep

    neg word [ballSpeedx]
    neg word [ballSpeedy] 

    ret 

check0: 
    cmp word [ballSpeedy], 0 
    jl negate 
    ret 

negate: 
    neg word [ballSpeedx] 
    neg word [ballSpeedy]  

    mov word [note], 0fdah
    call Beep

    ret 

vichecker:
    mov bx, 0 
    mov [x], bx 
    mov cx, 320  
xchecker:
    push cx 
    
    mov ax, [linecounter]
    mov bx, 10 
    mul bx 
    add ax, 10 
    mov cx, ax 
      
    mov dx, 0 
    mov ah, 0ch 
    mov al, 9
    mov bx, 0 
    mov ah, 0dh
     
ychecker: 
    push cx

    mov cx, [x]
     
    int 10h 
    cmp al, 0 
    je goodtogo

    pop cx 
    pop cx  
    ret 

goodtogo:
    inc dx  
    pop cx
    loop ychecker 

    inc word [x] 
    pop cx
    loop xchecker  

    mov word [gamewinbol], 1 
    mov word [brickbol], 2 
    ret 

keys:  
    cmp al, 1Fh ; press s for slowing 
    je slow 

    cmp al, 21h ; press f for faster
    je fast 

    cmp al, 2ch ; press z for cheating  
    jne notcheat
    jmp cheat 

notcheat: 
    cmp al, 50h ; press down for fastest ball alive 
    je youaskedforit 

    mov word [keybol], 0 
    cmp word [secounter], 10     
    je highballSpeed 
    ret 

youaskedforit:
    cmp word [timerballSpeed], 2 
    jne n0p 
    mov word [fastestball], 1  
    inc word [lifecounter]

    mov cx, 10 
delayed99:
    push cx 
    call DelayProc
    pop cx 
    loop delayed99  
    ret 

n0p:
    mov word [timerballSpeed], 3
    mov word [fastestball], 2 
    ret 

slow:
    cmp word [slowbol], 1 
    jae decslow 
    inc word [timerballSpeed]
    mov word [slowbol], 2 
    ret  
decslow:
    dec word [slowbol] 
    ret 

fast: 
    cmp word [fasterbol], 1 
    jae decfast
    mov ax, [fastestball]     
    cmp [timerballSpeed], ax     
    jbe nothighh
    mov word [ballSpeedbol], 1 
    dec word [timerballSpeed]
    mov word [fasterbol], 2 
nothighh: 
    ret  
decfast:
    dec word [fasterbol] 
    ret  

highballSpeed:
    mov word [secounter], 0
    cmp word [ballSpeedbol], 3  
    je nothigh
    cmp word [timerballSpeed], 3    
    jbe nothigh
    dec word [timerballSpeed] 
nothigh: 
    ret 

cheat: 
    mov ax, [cheatx] 
    mov [x], ax 
    mov ax, [cheaty]
    mov [y], ax  
    mov al, 0 
    call cube 

    mov ax, [cheatx] 
    cmp ax, 319 
    je resetto0
    add ax, 40 
    mov [cheatx], ax 
    ret 
resetto0:
    mov ax, [cheaty] 
    add ax, 10 
    mov [cheaty], ax 
    mov ax, -1 
    mov [cheatx], ax 
    ret 

; Displays the current ball ballSpeed on screen.
ballSpeedprinter:
    ; set cursor postion
    mov ah, 2 
    mov bh, 0 
    mov dl, 69      
    mov dh, 24    
    int 10h 

    mov ax, [timerballSpeed] 
    cmp al, 10 
    jbe notneeded 

    mov bl, 10 
    div bl 
    add al, 48 
    add ah, 47 
    mov [dollar], al 
    mov [dollar+1], ah 
    mov dx, dollar  
    mov ah, 9   
    int 21h 
    ret 

notneeded:  
    mov dx, [timerballSpeed]
    add dl, 47 
    mov [dollar], dl
    mov byte [dollar+1], ' '
    mov dx, dollar  
    mov ah, 9   
    int 21h 
    ret
; REVISED realtimefinal_score - Fixed to display on row 24 (bottom row)
realtimefinal_score:
    push ax
    push bx
    push cx
    push dx
    push si

    ; Convert final_score to 3 digits
    mov ax, [final_score_accumulator]
    mov bl, 10

    ; Calculate Units digit
    xor ah, ah
    div bl
    add ah, '0'                    ; Convert to ASCII
    mov byte [final_score_buffer+2], ah  ; Store units

    ; Calculate Tens digit
    mov ah, 0
    div bl
    add ah, '0'                    ; Convert to ASCII
    mov byte [final_score_buffer+1], ah  ; Store tens

    ; Calculate Hundreds digit
    add al, '0'                    ; Convert to ASCII
    mov byte [final_score_buffer+0], al  ; Store hundreds

    ; Draw a black background rectangle for the final_score display
    mov ah, 0ch
    mov al, 0      ; Black color
    mov bx, 0
    mov cx, 240    ; Start X (right side)
    mov dx, 192    ; Start Y (row 24 * 8 = 192)
    
    ; Draw 80 pixels wide, 8 pixels high black rectangle
    mov si, 80     ; Width
.clearloop_x:
    push si
    mov si, 8      ; Height
.clearloop_y:
    int 10h
    inc dx
    dec si
    jnz .clearloop_y
    pop si
    sub dx, 8      ; Reset Y position
    inc cx         ; Next X
    dec si
    jnz .clearloop_x

    ; Position cursor at BOTTOM RIGHT - ROW 24 (not 23)
    mov ah, 02h
    mov bh, 0
    mov dh, 24     ; Row 24 (bottom row) - CHANGED FROM 23 to 24
    mov dl, 60     ; Column 60 (right side)
    int 10h

    ; Print "final_score: "
    mov si, final_score_label
.print_label:
    lodsb                   ; Load byte from SI into AL
    cmp al, '$'             ; Check for end marker ($ symbol)
    je .print_digits
    mov ah, 0Eh             ; Teletype output
    mov bx, 0007h           ; Page 0, white color
    int 10h
    jmp .print_label

.print_digits:
    ; Print the three final_score digits
    mov al, [final_score_buffer+0]  ; Hundreds
    mov ah, 0Eh
    mov bx, 0007h
    int 10h

    mov al, [final_score_buffer+1]  ; Tens
    mov ah, 0Eh
    mov bx, 0007h
    int 10h

    mov al, [final_score_buffer+2]  ; Units
    mov ah, 0Eh
    mov bx, 0007h
    int 10h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Shows rules and instructions before starting the game.
start:
    mov dx, rules_msg
    call DisplayMessage
    mov dx, rules_msg
    call DisplayMessage

; Clears the screen and redraws bricks, paddle, and lives at the beginning of each round.
printagain: 
    call cls                                     
    call bricks 

    ; Initialize final_score to 0 at game start
    mov word [final_score_accumulator], 0    ; <--- ADD THIS LINE
    mov word [destroyedbricks], 0      ; <--- ADD THIS LINE 

    mov dx, life3 
    mov ah, 9 
    int 21h  

    ; mov dx, ballSpeed  
    ; int 21h 

    mov cx, 138 
    mov [x], cx 
    mov cx, [pady] 
    mov [y], cx
    call printboard 

    mov word [lifecounter], 3 
    mov word [timerballSpeed], 5   

; Initializes game variables and starts the main game loop.
startgame:
    mov word [ballSpeedbol], 0 
    mov word [gameoverbol] , 0 
    mov word [gamewinbol], 0 

    mov cx, 160              
    mov [ballx], cx
    mov cx, 100              
    mov [bally], cx
    mov al, 10   
    call ball 

    mov ah, 0ch
    mov al, 7h
    int 21h 
    cmp al, 20h 
    je printagain 

    mov ax, 2        
    mov [ballSpeedy], ax
    mov ax, 0        
    mov [ballSpeedx], ax 

    mov ax, [timerballSpeed] 
    add ax, 2 
    mov [timerballSpeed], ax 

; Main game loop that updates ball, paddle, checks collisions, handles user input, and victory/gameover conditions.
game: ; 3,2,1 Action!!
    mov ah, 0ch 
    mov al, 0 
    int 21h 

    ; call ballSpeedprinter 
    call realtimefinal_score    ; <--- ADD THIS LINE to display real-time final_score

notneeded2:
    cmp word [gameoverbol], 1 
    jne gamenotover  
    jmp gameover
gamenotover:
    cmp word [gamewinbol], 1 
    je victory
    call delball
    call addtoball

    call vichecker

    call finalcheck

    mov al, 10 
    call ball 

    call checkhit

    call brickhit 

    call timeiskey

    cmp al, 39h ; press space for reset 
    jne next999 
    jmp printagain

next999:
    cmp al, 1 ; press exit for pause  
    je paus2  
    call keys 
     
    jmp game  

; Handles victory screen and waits for user input to continue or exit.
victory:
    
    mov dx, victory_msg
    call DisplayFinalScreenMsg  ; Displays message and final_score, waits for key
                                ; Key pressed is saved in [savekey]

    mov al, [savekey]           ; Load the key pressed back into AL
    cmp al, 20h ; Check if key was Space (20h) to restart
    jne exit2 

    jmp printagain

; Delayed/Key check blocks removed as DisplayFinalScreenMsg handles the wait
exit2: 
    jmp exit

; Pause routine, waits for key input, and allows resuming or exiting.
paus2: 
    ; call ballSpeedprinter
    mov cx, 10 
delayed5:
    push cx 
    call DelayProc
    pop cx 
    loop delayed5  

; Pause routine, waits for key input, and allows resuming or exiting.
paus: 
    mov ah, 0ch 
    mov al, 0 
    int 21h

    ; check if a key was entered 
    in al, 64h
    cmp al, 10b 
    je paus 
    in al, 60h

    cmp al, 1ch 
    je exit2 

    mov word [keybol], 1 

    call keys 

    cmp word [keybol], 1 
    je paus2 

    cmp al, 1 
    jne paus2 

    mov cx, 10 
delayed4:
    push cx 
    call DelayProc
    pop cx 
    loop delayed4 
    jmp game 

; Handles life decrement, displays remaining lives, and ends the game when lives reach zero.
gameover: 
    call delball 
    cmp word [lifecounter] , 3 
    je two2go 
    cmp word [lifecounter], 2 
    je one2go 
    cmp word [lifecounter], 1  
    je go
two2go:
    mov ah, 2 
    mov bh, 0 
    mov dh, 0 
    mov dl, 0 
    int 10h

    mov dx, life2 
    mov ah, 9 
    int 21h 

    ; mov dx, ballSpeed   
    ; int 21h
     
    dec word [lifecounter]
    jmp startgame
 
one2go:
    mov ah, 2 
    mov bh, 0 
    mov dh, 0 
    mov dl, 0 
    int 10h

    mov dx, life1 
    mov ah, 9 
    int 21h

    ; mov dx, ballSpeed   
    ; int 21h
     
    dec word [lifecounter]
    jmp startgame
; -------------------------------------------------------------
; NEW ROUTINE: DisplayFinalScreenMsg
; Switches to Text Mode, displays message, calls ShowFinalfinal_score, 
; waits for key, saves key, and switches back to Graphics Mode.
; -------------------------------------------------------------
DisplayFinalScreenMsg:
    push ax
    push dx
    push cx
    push si

    ; 1. Switch to Text Mode 3 (80x25 color text)
    mov ax, 0003h
    int 10h

    ; 2. Print the message string (DX is pre-loaded with message address)
    mov ah, 09h  ; DOS function 09h - Print String
    int 21h

    ; 3. Display the final_score
    call ShowFinalfinal_score

    ; 4. Wait for a key press (AH=00h, INT 16h waits, returns key in AL/AH)
    mov ah, 00h
    int 16h
    
    ; AL now holds the ASCII key pressed. Save it for comparison.
    mov [savekey], al 

    ; 5. Switch back to Graphics Mode 13h
    mov ax, 0013h
    int 10h

    pop si
    pop cx
    pop dx
    pop ax
    ret


go: 
    mov dx, gameover_msg
    call DisplayFinalScreenMsg  ; Displays message and final_score, waits for key
                                ; Key pressed is saved in [savekey]

    mov al, [savekey]           ; Load the key pressed back into AL
    cmp al, 20h ; Check if key was Space (20h) to restart
    jne exit 
    jmp printagain

; Delayed/Key check blocks removed as DisplayFinalScreenMsg handles the wait
    
exit:
    mov ah, 0 
    mov al, 2 
    int 10h
    mov ax, 4c00h
    int 21h




; displays a message string, waits for key press
DisplayMessage:
    push ax
    push dx

    ; 1. Switch to Text Mode 3 (80x25 color text)
    mov ax, 0003h
    int 10h

    ; 2. Print the message string (DX is pre-loaded with message address)
    mov ah, 09h  ; DOS function 09h - Print String
    int 21h

    ; 3. Wait for a key press
    mov ah, 0ch  ; BIOS wait for input (similar to original code's wait)
    mov al, 07h
    int 21h

    ; 4. Switch back to Graphics Mode 13h
    mov ax, 0013h
    int 10h

    pop dx
    pop ax
    ret

