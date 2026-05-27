;Print a prompt to get a number 0-9
;Echo the number
;Double the number

putchar_ptr = $346      ; CONSTANT: putchar_ptr = $346 (OS character output vector address)
csrhinh     = $2F0      ; CONSTANT: csrhinh = $2F0 (OS cursor visible/hidden control address)
rowcrs      = $54       ; CONSTANT: rowcrs = $54 (OS zero page address that controls cursor row)
colcrs      = $55       ; CONSTANT: colcrs = $55 (OS zero page address that controls cursor column)
space       = $20       ; ATASCII space is at hex 20 or $20
offset_to_char = $30    ; Offset from integer literal to ATASCII character equivalent of the number
ch          = $2FC      ; CONSTANT: ch = $2FC (OS last key pressed register)
atachr      = $2FB      ; CONSTANT: atachr = $2FB (OS ATASCII value of last key pressed)
no_key      = $FF       ; value in ch when no key is pressed

character   = $80       ; CONSTANT: character = $80 (zero page address we use as loop index)
doubled     = $81       ; CONSTANT: temporary storage for doubling
value       = $82       ; CONSTANT: temporary storage for the selected number to be doubled

        org $2000                       ; place the following code at memory address $2000


        .proc main                      ; declare procedure named "main", begin its scope

        mva #1 csrhinh                  ; memory[752] = 1             (hide the cursor)
        mva #6 rowcrs                   ; memory[$54] = 6             (position cursor at row 6)
        mva #10 colcrs                  ; memory[$55] = 10            (position cursor at column 10)
        mva #0 character                ; memory[$80] = 0    (initialize loop index to 0)

; Print out the prompt
next_character:                         ; next_character:              (loop entry point)
        ldx character                   ; X = memory[$80]             (load current loop index into X)
        cpx #.len text                  ; compare X to length of text (are we done yet?)
        beq wait_for_keypress           ; if X == length then GOTO wait_for_keypress to get keyboard input
        lda text,x                      ; A = memory[text + X]        (load character at position X from text)
        jsr putchar                     ; CALL putchar                (putchar expects character value in A)
        inc character                   ; memory[$80] = memory[$80]+1 (advance loop index to next character)
        jmp next_character              ; GOTO next_character      (go back and print next character)

; Wait for a key to be pressed          
wait_for_keypress:
        lda ch                          ; a = $2FC
        cmp #no_key                     ; test if a == $ff.  NOTE the # symbol denotes the following is a literal not an address
        beq wait_for_keypress           ; if not, loop back and try again
        
; Loop through keytable data and try to find a match on the keyboard scancode
        ldx #0                          ; init x=0
find_key:
        cmp keytable,x                  ; compare what is in a to keytable[x], does a = keytable[x]
        beq found                       ; if equal, GOTO found
        inx                             ; increment x:  x = x + 1
        cpx #10                         ; compare if x = 10
        bne find_key                    ; if it does not, loop again
        jmp stop                        ; we didn't find a match after looping through all of the values.  stop

; echo the number pressed back to the screen
found:
        txa                             ; a = x
        sta value                       ; memory[value] = a
        clc                             ; clear carry                                       
        adc #offset_to_char             ; convert to ATASCII by adding $30
        jsr putchar                     ; print the number pressed
        mva #7 rowcrs                   ; memory[$54] = 6             (position cursor at row 6)
        mva #10 colcrs                  ; memory[$55] = 11            (position cursor at column 11)

; write the text label for the doubled value
        mva #0 character                ; reset our loop counter
next_label_ch:
        ldx character                   ; X = memory[$80]             (load current loop index into X)
        cpx #.len outputlabel           ; compare X to length of outputlabel (are we done yet?)
        beq double_the_value            ; if X == length then GOTO wait_for_keypress to get keyboard input
        lda outputlabel,x               ; A = memory[outputlabel + X]        (load character at position X from text)
        jsr putchar                     ; CALL putchar                (putchar expects character value in A)
        inc character                   ; memory[$80] = memory[$80]+1 (advance loop index to next character)
        jmp next_label_ch               ; GOTO next_label_ch      (go back and print next character)

double_the_value:
        lda value
        sta doubled                     ; STORE a in memory location 'doubled': memory[doubled] = a
        clc                             ; clear the carry flag
        adc doubled                     ; add the value in memory location 'doubled' to a: a = a + memory[doubled]
                                        ; (no # = read from memory address)
        adc #offset_to_char             ; a = a + $30
                                        ; (# so we use the literal value)
        jsr putchar                     ; print a

stop:
        jmp stop        ; GOTO stop                   (infinite loop = program halts here)

; =====================================================================
; PUTCHAR SUBROUTINE
; prints the character whose ATASCII value is in the A register
; by jumping to the OS print routine via stack manipulation
; ON ENTRY: A must contain the ATASCII value of the character to print
; ON EXIT:  A is preserved, character has been printed to screen
; =====================================================================

        .proc putchar
        tax             ; X = A                       (save character from A into X because A is about to be clobbered)
        lda putchar_ptr+1 ; A = memory[$347]          (load high byte of OS print routine address)
        pha             ; push A onto stack            (high byte on stack, will be popped second by rts)
        lda putchar_ptr ; A = memory[$346]            (load low byte of OS print routine address)
        pha             ; push A onto stack            (low byte on stack, will be popped first by rts)
        txa             ; A = X                       (restore original character back into A because OS print routine expects character value in A)
        rts             ; RETURN                      (pops OS address from stack and jumps there, OS prints character in A, then returns to main)
        .endp           ; end of putchar procedure

        .local text     ; declare local data block named "text"
        .byte 'ENTER A NUMBER: ' ; raw ATASCII bytes for each character in the string
        .endl           ; end of text data block

        .local keytable
        .byte $32,$1F,$1E,$1A,$18,$1D,$1B,$33,$35,$30
        .endl

        .local outputlabel
        .byte 'DOUBLED VALUE: '
        .endl

        .endp           ; end of main procedure

; =====================================================================
; ENTRY POINT
; =====================================================================

        run main        ; set Atari run address to main (auto-execute when program loads)