;
; Each palette entry:
; 7      0
; 00vvhhhh
; v is the value, 0-3 where 3 is the brightest
; h is hue:
;   0 light gray
;   1-2 blue
;   3 purple
;   4 magenta
;   5-6 red
;   7-8 brown/orange
;   9-b green
;   c cyan
;   d dark gray
;   e-f black

; The 0-th entry in each palette maps to the same register, the 'universal background'
; both on reading and writing.

BGCOLOR equ $f

palette             ; background palette 0
                    dc.b BGCOLOR, $1, $6, $b

                    ; background palette 1
                    dc.b BGCOLOR, $1, $6, $b

                    ; background palette 2
                    dc.b BGCOLOR, $1, $6, $b

                    ; background palette 3
                    dc.b BGCOLOR, $1, $6, $b

                    ; foreground palette 0
                    dc.b BGCOLOR, $0d, $06, $15

                    ; foreground palette 1
                    dc.b BGCOLOR, $21, $22, $23

                    ; foreground palette 2
                    dc.b BGCOLOR, $21, $22, $23

                    ; foreground palette 3
                    dc.b BGCOLOR, $21, $22, $23
