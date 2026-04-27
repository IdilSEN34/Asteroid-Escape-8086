org 100h

jmp start

; --- DEÐÝÞKENLER ---
p_x        db 35                 ; Oyuncu baþlangýç X (ekran ortasý)
p_y        db 22                 
has_shield db 0                  ; 0: Yok, 1: Var

ast_index  db 0                  ; Döngü sayacý

; --- ASTEROID DÝZÝLERÝ (5 Adet Asteroid Ýçin) ---
; Y eksenini negatif baþlatýyoruz (246=-10, 236=-20 vb.) ki hepsi ayný anda düþmesin
ast_x      db 10, 30, 50, 20, 60 
ast_y      db 0, 246, 236, 226, 216 
ast_v      db 1, 1, 1, 1, 1      
ast_char   db '*', '*', '*', '*', '*'
ast_color  db 0Ch, 0Ch, 0Ch, 0Ch, 0Ch

msg_line   db "*********************", "$"
msg_text   db "   G A M E   O V E R ", "$"
msg_opts   db "Yeniden: 'r' - Cikis: 'q'", "$"

; --- YENÝ EKLENEN SKOR DEÐÝÞKENLERÝ ---
score       dw 0                 ; Anlýk Skor (16-bit)
high_score  dw 0                 ; En Yüksek Skor (16-bit)
msg_score   db "Score: $"
msg_hiscore db "High Score: $"

start:
    mov ax, 0003h       ; Video modunu bir kez ayarla
    int 10h
    
    ; Kursörü tamamen gizle
    mov ah, 01h
    mov cx, 2607h
    int 10h

game_loop:
    ; --- EKRANI TEMÝZLE ---
    mov ax, 0600h       
    mov bh, 07h         
    mov cx, 0000h       
    mov dx, 184Fh       
    int 10h

    ; --- YENÝ: SKORU GÜNCELLE VE EKRANA YAZDIR ---
    call update_and_draw_scores

    ; --- ASTEROID DÖNGÜSÜ BAÞLANGICI ---
    mov ast_index, 0

ast_loop_start:
    mov bl, ast_index
    mov bh, 0
    mov si, bx          ; SI yazmacýný index olarak kullanýyoruz

    ; 1. Asteroid Hareketi
    mov al, ast_v[si]
    add ast_y[si], al
    
    ; Ekran sýnýrýný geçti mi?
    cmp ast_y[si], 23        
    jl check_collision
    
    ; --- ASTEROÝDÝ SIFIRLA ---
    mov ast_y[si], 0
    mov ah, 00h
    int 1Ah             ; Zamaný CX:DX'e al (Rastgelelik için)
    
    mov bl, dl
    and bl, 03h         
    
    cmp bl, 0
    je type_fast        
    cmp bl, 1
    je type_shield      
    
type_normal:
    mov ast_char[si], '*'
    mov ast_v[si], 1
    mov ast_color[si], 0Ch
    jmp set_random_x

type_fast:
    mov ast_char[si], '!'
    mov ast_v[si], 2
    mov ast_color[si], 0Ch
    jmp set_random_x

type_shield:
    mov ast_char[si], '+'
    mov ast_v[si], 1
    mov ast_color[si], 09h  

set_random_x:
    mov ax, dx          
    add al, ast_index   ; Her asteroidin farklý X almasý için indexi ekle
    and al, 3Fh         ; 0-63 arasý bir deðere sýnýrla
    mov ast_x[si], al

check_collision:
    ; Eðer Y deðeri 0'dan küçükse (staggering), henüz ekrana girmemiþtir, atla
    cmp ast_y[si], 0
    jl draw_ast_skip

    ; Oyuncu ile ayný Y hizasýnda mý?
    mov al, ast_y[si]
    cmp al, p_y
    jne draw_this_ast    
    
    ; X hizasý kontrolü
    mov al, ast_x[si]
    cmp al, p_x
    jb draw_this_ast    
    mov bl, p_x
    add bl, 5           ; Oyuncu geniþliði
    cmp al, bl
    ja draw_this_ast    

    ; --- ÇARPIÞMA GERÇEKLEÞTÝ ---
    cmp ast_color[si], 09h   
    je get_shield        
    
    cmp has_shield, 1    
    je lose_shield       
    
    jmp game_over_screen 

get_shield:
    mov has_shield, 1
    mov ast_y[si], 250  ; Ekrana girmemesi için yukarý gönder (-6)
    jmp draw_ast_skip

lose_shield:
    mov has_shield, 0
    mov ast_y[si], 250  ; Ekrana girmemesi için yukarý gönder
    jmp draw_ast_skip

draw_this_ast:
    mov dh, ast_y[si]
    mov dl, ast_x[si]
    call move_cursor
    mov al, ast_char[si]
    mov bl, ast_color[si]
    mov cx, 1           
    mov ah, 09h         
    int 10h

draw_ast_skip:
    inc ast_index
    cmp ast_index, 5    ; Toplam 5 asteroid var
    jge end_ast_loop    ; Jump limits (rel out of range) hatasýný önlemek için
    jmp ast_loop_start
end_ast_loop:

    ; --- OYUNCUYU ÇÝZ ---
    mov dh, p_y
    mov dl, p_x
    call move_cursor
    mov al, '='         
    mov bl, 0Fh          
    cmp has_shield, 1
    jne skip_blue
    mov bl, 09h          
skip_blue:
    mov cx, 5           
    mov ah, 09h
    int 10h

    ; --- KLAVYE KONTROLÜ ---
    mov ah, 01h
    int 16h
    jz delay_frame      
    mov ah, 00h
    int 16h
    cmp al, 'a'
    je move_left
    cmp al, 'd'
    je move_right
    cmp al, 'q'
    je exit_program

move_left:
    cmp p_x, 0
    jle delay_frame
    dec p_x
    jmp delay_frame
move_right:
    cmp p_x, 74         ; Ekran sað sýnýrý 74 olarak geniþletildi
    jge delay_frame
    inc p_x

delay_frame:
    mov cx, 00h
    mov dx, 0A000h      
    mov ah, 86h
    int 15h
    jmp game_loop


; --- YARDIMCI FONKSÝYONLAR VE EKRANLAR ---

; YENÝ EKLENEN FONKSÝYON: Skor Güncelleme ve Çizimi
update_and_draw_scores:
    inc score           ; Hayatta kalýnan her frame için skor artýr

    ; Score yazýsý
    mov dh, 0
    mov dl, 2
    call move_cursor
    mov dx, offset msg_score
    mov ah, 09h
    int 21h
    mov ax, score
    call print_number

    ; High Score yazýsý
    mov dh, 0
    mov dl, 55
    call move_cursor
    mov dx, offset msg_hiscore
    mov ah, 09h
    int 21h
    mov ax, high_score
    call print_number
    ret

; YENÝ EKLENEN FONKSÝYON: Ekrana Sayý Yazdýrma
print_number:
    push ax
    push bx
    push cx
    push dx
    mov cx, 0
    mov bx, 10
divide_loop:
    mov dx, 0
    div bx
    push dx             ; Kalaný (haneyi) yýðýna at
    inc cx              ; Hane sayacýný artýr
    cmp ax, 0
    jne divide_loop
print_digits:
    pop dx              ; Yýðýndan en anlamlý haneyi çek
    add dl, '0'         ; ASCII karaktere çevir
    mov ah, 02h
    int 21h
    loop print_digits
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game_over_screen:
    ; YENÝ: High Score Kontrolü
    mov ax, score
    cmp ax, high_score
    jle skip_highscore_update
    mov high_score, ax   ; Eðer yeni skor daha yüksekse, High Score'u güncelle
skip_highscore_update:

    mov ax, 0003h
    int 10h
    
    ; Klasik metinler
    mov dh, 10
    mov dl, 28
    call move_cursor
    mov dx, offset msg_line
    call print_red
    mov dh, 11
    mov dl, 28
    call move_cursor
    mov dx, offset msg_text
    call print_red
    mov dh, 12
    mov dl, 28
    call move_cursor
    mov dx, offset msg_line
    call print_red
    mov dh, 14
    mov dl, 26
    call move_cursor
    mov dx, offset msg_opts
    mov ah, 09h
    int 21h

    ; YENÝ: Bitiþ Ekranýnda Skorlarý Göster
    mov dh, 16
    mov dl, 28
    call move_cursor
    mov dx, offset msg_score
    mov ah, 09h
    int 21h
    mov ax, score
    call print_number

    mov dh, 17
    mov dl, 28
    call move_cursor
    mov dx, offset msg_hiscore
    mov ah, 09h
    int 21h
    mov ax, high_score
    call print_number

wait_for_input:
    mov ah, 00h         
    int 16h
    cmp al, 'r'
    je start_reset      ; Deðiþkenleri sýfýrlayarak baþlatmak için 
    cmp al, 'q'
    je exit_program
    jmp wait_for_input

start_reset:
    ; Yeniden baþlatýldýðýnda deðiþkenleri orijinal haline döndür
    mov p_x, 35
    mov has_shield, 0
    mov score, 0        ; YENÝ: Oyun yeniden baþladýðýnda skoru sýfýrla (High score sýfýrlanmaz)
    mov ast_y[0], 0
    mov ast_y[1], 246
    mov ast_y[2], 236
    mov ast_y[3], 226
    mov ast_y[4], 216
    jmp start

move_cursor:
    mov ah, 02h
    mov bh, 0
    int 10h
    ret

print_red:
    mov si, dx
red_loop:
    mov al, [si]
    cmp al, '$'
    je red_done
    mov ah, 09h
    mov bl, 0Ch         
    mov cx, 1
    int 10h
    inc dl              
    mov ah, 02h
    int 10h
    inc si
    jmp red_loop
red_done:
    ret

exit_program:
    mov ax, 4c00h
    int 21h