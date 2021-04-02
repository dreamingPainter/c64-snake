;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; print16 从内存打印16位int(十进制5位),空位补0
; 以BE方式存储以便打印
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print16:
.scope
.data zp
.space _num 4
.space _num_dec 6
.text
	pha
	txa
	pha
	
    lda #0
    ldx #10
*   dex
    sta _num - 1, x
    bne -

	`splitbyte s, 3
	`splitbyte s + 1, 1
    `carry
	`print _num_dec

	pla
	tax
	pla
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mod函数处理的数据为打印方便均使用大端序存储
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mod_4:      ; 高字节低4位若大于10，则向高位进1
    lda _num + 3
    cmp #10
    bcc +
    sbc #10             ; 此时c为1
    tax
    lda #1
    sta _num_dec + 3    ; 进位
    txa
*   sta _num_dec + 4
    rts

mod_3:      ; 高字节高4位的值相当于个位加6，十位加1
    ldx _num + 2
    bne +   ; 如果为0直接返回
    rts
*   lda #6
    `carry10 4
    lda #1
    `carry10 3
    dex
    bne -
    rts

mod_2:      ; 低字节低4位的值相当于个位加6，十位加5，百位加2
    ldx _num + 1
    bne +   ; 如果为0直接返回
    rts
*   lda #6
    `carry10 4
    lda #5
    `carry10 3
    lda #2
    `carry10 2
    dex
    bne -
    rts

mod_1:      ; 低字节低4位的值相当于个位加6，十位加9，百位加0，千位加4
    ldx _num
    bne +   ; 如果为0直接返回
    rts
*   lda #6
    `carry10 4
    lda #9
    `carry10 3
    lda #4
    `carry10 1
    dex
    bne -
    rts

.scend

.macro carry10
    clc
    adc _num_dec + _1
    bcc _skip
    pha
    adc _num_dec + _1 - 1
    sta _num_dec + _1 - 1
    pla
_skip:
    sta _num_dec + _1
    ;jsr printbyte
.macend

.macro splitbyte
	lda _1
	sta _num + _2
    ;jsr printbyte
	lsr
	lsr
	lsr
	lsr
	sta _num + _2 - 1
    ;jsr printbyte
	lda #$0f
	and _num + _2
	sta _num + _2
    ;jsr printbyte
.macend

.macro carry
    tya
    pha

    sed         ; 设置为bcd加减法
    jsr mod_4
    jsr mod_3
    jsr mod_2
    jsr mod_1   ; 此时结果中有些位可能大于10，需要进行进位处理
    ldx #4
_loop:
    lda _num_dec, x
    ldy #0      ; y记录进位数
    cmp #10
    bcc _skip   ; 小于10不进位
    pha
    ora #$f0
    ror
    ror
    ror
    ror
    tay
    pla
    ora #$0f
    sta _num_dec, x
    tya
    dex
    adc _num_dec, x
    sta _num_dec, x
    inx
_skip:
    dex
    bne _loop

    cld         ; 退出bcd模式
    lda #$30    ; 转化为可显示字符
    ldx #5
_up:
    adc _num_dec - 1, x
    sta _num_dec - 1, x
    dex
    bne _up

    pla
    tay
.macend

 .require "printbyte.asm"