org 100h            ; DOS .COM programlarý her zaman bellek adresi 100h'den baþlar.

jmp start           ; Program baþladýðýnda veri tanýmlamalarýný atlayýp 'start' etiketine zýplar.

; --- DEÐÝÞKENLER (VERÝ ALANI) ---
p_x        db 35    ; Oyuncunun baþlangýç yatay (X) konumu (ekranýn ortasý).
p_y        db 22    ; Oyuncunun dikey (Y) konumu (ekranýn alt kýsmý).
has_shield db 0     ; Kalkan durumu: 0 ise kalkan yok, 1 ise kalkan var.
ast_index  db 0     ; Döngüde hangi asteroidi iþlediðimizi tutan sayaç (0,1,2,3,4).

; --- ASTEROID DÝZÝLERÝ (Her özellik için 5 elemanlý liste) ---
ast_x      db 10, 30, 50, 20, 60    ; 5 farklý asteroidin baþlangýç X (sütun) konumlarý.
ast_y      db 0, 246, 236, 226, 216 ; Asteroidlerin Y konumlarý. Negatif/büyük deðerler ekrana geç girmeleri içindir (-10=246 vb.)
ast_v      db 1, 1, 1, 1, 1         ; Her asteroidin düþme hýzý.
ast_char   db '*', '*', '*', '*', '*' ; Asteroidlerin ekranda nasýl görüneceði.
ast_color  db 0Ch, 0Ch, 0Ch, 0Ch, 0Ch ; Asteroidlerin renkleri (0Ch = Açýk Kýrmýzý).

; --- EKRAN MESAJLARI ---
msg_line   db "*********************", "$" ; Oyun sonu ekraný süslemesi ('$' metin sonu iþaretidir).
msg_text   db "   G A M E   O V E R ", "$" ; Oyun sonu yazýsý.
msg_opts   db "Yeniden: 'r' - Cikis: 'q'", "$" ; Seçenekler yazýsý.

; --- PROGRAMIN BAÞLANGICI ---
start:
    mov ax, 0003h       ; BIOS video kesmesi için 03h (80x25 renkli metin) modunu seç.
    int 10h             ; Video ayarlarýný uygula (ekraný sýfýrlar).
    
    mov ah, 01h         ; Kursörü (yanýp sönen imleç) gizlemek için alt fonksiyon.
    mov cx, 2607h       ; Görünmez yapacak kursör boyut deðerleri.
    int 10h             ; Kursörü gizleme iþlemini uygula.

; --- ANA OYUN DÖNGÜSÜ ---
game_loop:
    mov ax, 0600h       ; Ekraný yukarý kaydýrma fonksiyonu (Tüm ekraný temizlemek için kullanýyoruz).
    mov bh, 07h         ; Boþluklarýn rengi: Siyah arka plan, açýk gri yazý (07h).
    mov cx, 0000h       ; Ekranýn sol üst köþesi (X=0, Y=0).
    mov dx, 184Fh       ; Ekranýn sað alt köþesi (Y=24, X=79).
    int 10h             ; Ekraný temizle.

    mov ast_index, 0    ; Asteroid döngüsü için sayacý (index) 0'dan baþlat.

; --- ASTEROÝDLERÝ HAREKET ETTÝRME VE KONTROL DÖNGÜSÜ ---
ast_loop_start:
    mov bl, ast_index   ; Hangi asteroidde olduðumuzu BL yazmacýna al.
    mov bh, 0           ; BH'yi sýfýrla (BX = ast_index olsun diye).
    mov si, bx          ; BX'teki deðeri SI (Source Index) yazmacýna kopyala. SI dizilerde gezinmek için kullanýlýr.

    ; 1. Asteroidin Yönü ve Hareketi
    mov al, ast_v[si]   ; O anki asteroidin hýzýný AL'ye al.
    add ast_y[si], al   ; Hýzý asteroidin Y (dikey) konumuna ekle (aþaðý düþür).
    
    cmp ast_y[si], 23   ; Asteroid ekranýn en altýna (23. satýr) ulaþtý mý?
    jl check_collision  ; Eðer 23'ten küçükse (daha düþmediyse), çarpýþma kontrolüne atla.
    
    ; 2. Asteroid Ekrandan Çýktýysa Yeniden Oluþtur (Rastgeleleþtir)
    mov ast_y[si], 0    ; Asteroidi tekrar ekranýn en üstüne (Y=0) taþý.
    mov ah, 00h         ; Sistem saatini (timer) okumak için BIOS fonksiyonu.
    int 1Ah             ; Zamaný oku (DX yazmacýna rastgele gibi davranan sayýlar dolar).
    
    mov bl, dl          ; Saat deðerinin alt kýsmýný (DL) BL'ye kopyala.
    and bl, 03h         ; Sayýyý 0, 1, 2 veya 3 olacak þekilde kýsýtla (maskeleme).
    
    cmp bl, 0           ; Gelen rastgele sayý 0 mý?
    je type_fast        ; Evetse 'hýzlý asteroid' türüne zýpla.
    cmp bl, 1           ; Sayý 1 mi?
    je type_shield      ; Evetse 'kalkan' türüne zýpla.
    
type_normal:            ; Geri kalan sayýlar için normal asteroid.
    mov ast_char[si], '*' ; Karakteri yýldýz yap.
    mov ast_v[si], 1    ; Hýzýný 1 yap (normal hýz).
    mov ast_color[si], 0Ch ; Rengini kýrmýzý yap.
    jmp set_random_x    ; Özellikleri belirledik, X konumunu seçmeye git.

type_fast:
    mov ast_char[si], '!' ; Karakteri ünlem yap.
    mov ast_v[si], 2    ; Hýzýný 2 yap (iki kat hýzlý düþer).
    mov ast_color[si], 0Ch ; Rengini kýrmýzý yap.
    jmp set_random_x

type_shield:
    mov ast_char[si], '+' ; Karakteri artý (+) yap (kalkan eþyasý).
    mov ast_v[si], 1    ; Hýzýný 1 yap.
    mov ast_color[si], 09h ; Rengini mavi (09h) yap.

set_random_x:
    mov ax, dx          ; Rastgele zaman deðerini AX'e al.
    add al, ast_index   ; Üst üste binmemeleri için asteroidin sýrasýný ekle.
    and al, 3Fh         ; 0 ile 63 arasýnda rastgele bir X sütun deðeri elde et.
    mov ast_x[si], al   ; Çýkan rastgele sayýyý asteroidin X konumuna kaydet.

; 3. Çarpýþma (Collision) Kontrolü
check_collision:
    cmp ast_y[si], 0    ; Asteroidin Y'si 0'dan küçük mü? (Henüz ekrana girmedi mi?)
    jl draw_ast_skip    ; Öyleyse ekrana çizme, sonrakine geç.

    mov al, ast_y[si]   ; Asteroidin Y konumunu AL'ye al.
    cmp al, p_y         ; Oyuncunun Y konumuyla ayný hizada mý?
    jne draw_this_ast   ; Hayýrsa (ayný hizada deðilse) çarpýþma yok, ekrana çizmeye git.
    
    mov al, ast_x[si]   ; Asteroidin X konumunu AL'ye al.
    cmp al, p_x         ; Oyuncunun baþlangýç (sol) X konumuyla karþýlaþtýr.
    jb draw_this_ast    ; Asteroid oyuncunun daha solundaysa çarpýþma yok.
    mov bl, p_x         ; Oyuncunun konumunu BL'ye al.
    add bl, 5           ; Oyuncu 5 karakter geniþliðinde ('====='), geniþliði ekle.
    cmp al, bl          ; Asteroid oyuncunun en saðýndan daha mý ileride?
    ja draw_this_ast    ; Evetse çarpýþma yok.

    ; --- ÇARPIÞMA GERÇEKLEÞTÝ ---
    cmp ast_color[si], 09h ; Çarpan obje mavi (kalkan) mi?
    je get_shield       ; Evetse kalkan alma etiketine zýpla.
    
    cmp has_shield, 1   ; Çarpan düþman! Peki oyuncunun kalkaný var mý (1 mi)?
    je lose_shield      ; Evetse sadece kalkaný kýrma etiketine zýpla.
    
    jmp game_over_screen; Kalkan yoksa ve düþman çarptýysa, oyunu kaybettin!

get_shield:
    mov has_shield, 1   ; Kalkaný aktif et (1 yap).
    mov ast_y[si], 250  ; Kalkan ikonunu ekrandan uzaklaþtýr (-6 gibi bir deðer olur).
    jmp draw_ast_skip   ; Sonraki asteroide geç.

lose_shield:
    mov has_shield, 0   ; Kalkaný iptal et (kýrýldý).
    mov ast_y[si], 250  ; Çarpan asteroidi ekrandan yok et.
    jmp draw_ast_skip   ; Sonraki asteroide geç.

; 4. Asteroidi Ekrana Çizme
draw_this_ast:
    mov dh, ast_y[si]   ; Kursörün gideceði satýr (Y).
    mov dl, ast_x[si]   ; Kursörün gideceði sütun (X).
    call move_cursor    ; Kursörü bu koordinatlara taþý (aþaðýdaki fonksiyona gider).
    mov al, ast_char[si]; Ekrana yazýlacak karakter.
    mov bl, ast_color[si]; Karakterin rengi.
    mov cx, 1           ; Karakterden 1 tane yazdýr.
    mov ah, 09h         ; BIOS karakter ve renk yazdýrma alt fonksiyonu.
    int 10h             ; Ýþlemi uygula (Asteroidi çiz).

draw_ast_skip:
    inc ast_index       ; Sayacý 1 artýr (Bir sonraki asteroide geçmek için).
    cmp ast_index, 5    ; Toplam 5 asteroidi iþledik mi?
    jge end_ast_loop    ; Evetse döngüyü bitir.
    jmp ast_loop_start  ; Hayýrsa baþa dön ve sýradaki asteroidi iþle.
end_ast_loop:

    ; --- OYUNCUYU ÇÝZME ---
    mov dh, p_y         ; Oyuncunun satýrý (Y).
    mov dl, p_x         ; Oyuncunun sütunu (X).
    call move_cursor    ; Kursörü oraya taþý.
    mov al, '='         ; Oyuncu karakteri (Gemi/Platform).
    mov bl, 0Fh         ; Standart oyuncu rengi (Parlak Beyaz).
    cmp has_shield, 1   ; Kalkaný var mý?
    jne skip_blue       ; Yoksa rengi deðiþtirme.
    mov bl, 09h         ; Kalkaný varsa geminin rengini mavi (09h) yap.
skip_blue:
    mov cx, 5           ; Oyuncu gemisi yan yana 5 tane '=' karakterinden oluþur.
    mov ah, 09h         ; Karakter/renk yazdýrma.
    int 10h             ; Ekrana yaz.

    ; --- KLAVYE (INPUT) KONTROLÜ ---
    mov ah, 01h         ; Klavyede basýlmýþ bir tuþ var mý kontrol et.
    int 16h             ; Klavye kesmesi.
    jz delay_frame      ; Zero Flag (ZF) 1 ise tuþa basýlmamýþtýr, gecikmeye atla.
    mov ah, 00h         ; Eðer tuþa basýldýysa, tuþu okuyup bellekten temizle.
    int 16h             ; AL yazmacýna basýlan tuþun ASCII kodu gelir.
    cmp al, 'a'         ; Basýlan tuþ 'a' mý?
    je move_left        ; Sola gitme bölümüne atla.
    cmp al, 'd'         ; Basýlan tuþ 'd' mi?
    je move_right       ; Saða gitme bölümüne atla.
    cmp al, 'q'         ; Basýlan tuþ 'q' mu?
    je exit_program     ; Çýkýþa atla.

move_left:
    cmp p_x, 0          ; Oyuncu en solda mý (0. sütun)?
    jle delay_frame     ; Ekrandan çýkmasýný engelle.
    dec p_x             ; X konumunu 1 azalt (sola kay).
    jmp delay_frame
move_right:
    cmp p_x, 74         ; Oyuncu en saðda mý? (80 sütun - 5 boyut = 75 sýnýr).
    jge delay_frame     ; Ekrandan çýkmasýný engelle.
    inc p_x             ; X konumunu 1 artýr (saða kay).

    ; --- OYUN HIZI (GECÝKME/DELAY) ---
delay_frame:
    mov cx, 00h         ; Bekleme süresinin üst limit kýsmý (Mikrosaniye cinsi).
    mov dx, 0A000h      ; Bekleme süresinin alt kýsmý (~40 milisaniye bekleme).
    mov ah, 86h         ; BIOS Bekleme (Wait) fonksiyonu.
    int 15h             ; Sistemi belirtilen süre kadar duraklat (oyun çok hýzlý akmasýn diye).
    jmp game_loop       ; Her þey bitti, bir sonraki kare(frame) için döngünün en baþýna dön!

; --- OYUN SONU EKRANI ---
game_over_screen:
    mov ax, 0003h       ; Ekraný tamamen temizle.
    int 10h
    mov dh, 10          ; Satýr 10.
    mov dl, 28          ; Sütun 28 (Ekranýn ortalarý).
    call move_cursor
    mov dx, offset msg_line ; "***************" yazýsýnýn bellekteki adresi.
    call print_red      ; Metni kýrmýzý basan fonksiyonu çaðýr.
    mov dh, 11
    mov dl, 28
    call move_cursor
    mov dx, offset msg_text ; "GAME OVER" yazýsý.
    call print_red
    mov dh, 12
    mov dl, 28
    call move_cursor
    mov dx, offset msg_line
    call print_red
    mov dh, 14
    mov dl, 26
    call move_cursor
    mov dx, offset msg_opts ; "Yeniden: r - Cikis: q" yazýsý.
    mov ah, 09h         ; DOS string yazdýrma fonksiyonu.
    int 21h             ; (Bu fonksiyon rengi ayarlamaz, standart DOS yazýsý basar).

wait_for_input:
    mov ah, 00h         ; Oyuncunun tuþa basmasýný bekle.
    int 16h
    cmp al, 'r'         ; 'r' tuþuna bastýysa...
    je start_reset      ; Oyunu sýfýrlayýp baþtan baþlatan yere zýpla.
    cmp al, 'q'         ; 'q' tuþuna bastýysa...
    je exit_program     ; Programdan çýk.
    jmp wait_for_input  ; Baþka tuþa basarsa tekrar bekle.

start_reset:
    ; Oyunu yeniden baþlatmak için gerekli deðiþkenleri ilk haline getiriyoruz.
    mov p_x, 35
    mov has_shield, 0
    mov ast_y[0], 0
    mov ast_y[1], 246
    mov ast_y[2], 236
    mov ast_y[3], 226
    mov ast_y[4], 216
    jmp start           ; Oyuna sýfýrdan baþla.

; --- YARDIMCI FONKSÝYONLAR ---

; Kursörü DH (Satýr) ve DL (Sütun) noktalarýna taþýr.
move_cursor:
    mov ah, 02h         ; BIOS imleç taþýma fonksiyonu.
    mov bh, 0           ; Sayfa numarasý 0.
    int 10h
    ret                 ; Fonksiyonun çaðrýldýðý yere (call komutunun ardýna) geri dön.

; DX yazmacýndaki metni karakter karakter okuyup kýrmýzý renkte yazdýrýr.
print_red:
    mov si, dx          ; Metnin adresini SI'ye al.
red_loop:
    mov al, [si]        ; Adresteki harfi AL'ye al.
    cmp al, '$'         ; Harf DOS bitiþ karakteri '$' mi?
    je red_done         ; Evetse yazdýrmayý bitir.
    mov ah, 09h         ; BIOS harf/renk yazdýrma.
    mov bl, 0Ch         ; Açýk kýrmýzý renk.
    mov cx, 1           ; 1 tane yaz.
    int 10h
    inc dl              ; Kursörün sütun (X) deðerini 1 artýr.
    mov ah, 02h         ; Kursörü o yeni pozisyona taþý.
    int 10h
    inc si              ; Metindeki bir sonraki harfe geç.
    jmp red_loop        ; Döngüye baþa dön.
red_done:
    ret                 ; Yazdýrma bitti, geri dön.

; Programý sonlandýrýr ve DOS (veya emülatör) ekranýna döner.
exit_program:
    mov ax, 4c00h       ; DOS programdan düzgün çýkýþ kodu (Return 0).
    int 21h             ; Çýkýþý tetikle.