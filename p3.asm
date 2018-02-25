dane segment
	endmsg		db	"Koniec gry",10,13,"$"
	paddle		dw	?	;polozenie paletki
	ball_x		dw	? 	;polozenie pilki
	ball_y		dw	?	
	speed_x		dw	?	;predkosc pilki
	speed_y	dw	?	
	temp		dw 	? 
	kolor		db	? 	;kolor rysowania
dane ends

kod segment
	start:
		;inicjalizacja stosu
		mov ax,seg top1
		mov ss,ax
		mov sp,offset top1
		;ustawienie segmentu danych
		mov ax,seg dane
		mov ds,ax
		;nadanie zmiennym poczatkowych wartosci - pilka zaczyna w lewym gornym rogu i leci w dol i w prawo
		mov word ptr ds:[paddle],150
		mov word ptr ds:[ball_x],1
		mov word ptr ds:[ball_y],1
		mov word ptr ds:[speed_x],1
		mov word ptr ds:[speed_y],1
		mov byte ptr ds:[kolor],12
		
		mov	ax,13h ;uruchomienie trybu graficznego 256 kolorow 320x200
		int 10h
		mov ax,0a000h ;wskazuje na video memory
		mov es,ax
			
		game: ;glowna petla gry
			xor cx,cx ;odpowiednik funkcji sleep(), ogranicza predkosc dzialania gry, delay wynosi 6000 ms
			mov ah,86h
			mov dx,6000
			int 15h
			
			xor ax,ax ;sprawdzenie nacisnietego klawisza
			mov ah,01h
			int 16h ;sprawdza stan bufora klawiatury
			jz moveBall ;0 = bufor pusty, 1 = bufor niepusty
			xor ax,ax
			int 16h ;pobranie znaku z bufora i sprawdzenie go
			cmp ah,01h ;escape
			je endGame ;jesli tak to zakonczenie gry
			cmp ah,4bh;strzalka w lewo
			je moveLeft ;jesli tak to przesuniecie paletki w lewo
			cmp ah,4dh ;strzalka w prawo
			je moveRight ;jesli tak to przesuniecie paletki w prawo
			jmp moveBall
			jmp game
		jmp endGame
		
		moveRight:
			mov ax,word ptr ds:[paddle] ;pobranie aktualnej pozycji paletki ze zmiennej paddle
			add ax,6 ;proba przesuniecia w prawo
			cmp ax,320 ;sprawdzam, czy paletka dotarla do konca ekranu
			jae rightBorder
			mov word ptr ds:[paddle],ax ; jesli nie, zapisujemy nowe polozenie
			jmp moveBall
			rightBorder:
				mov word ptr ds:[paddle],320 ;zapisujemy polozenie przy prawej krawedzi ekranu
				jmp moveBall
	
		moveLeft:
			mov ax,word ptr ds:[paddle] ;pobranie aktualnej pozycji paletki ze zmiennej paddle
			sub ax,6 ;proba przesuniecia w lewo
			cmp ax,30 ;sprawdzam, czy paletka dotarla do konca ekranu
			jbe leftBorder
			mov word ptr ds:[paddle],ax ;jesli nie, zapisujemy nowe polozenie
			jmp moveBall
			leftBorder:
				mov word ptr ds:[paddle],30 ;zapisujemy polozenie przy prawej krawedzi ekranu
				jmp moveBall
				
		moveBall: ;zmiana polozenia pilki i detekcja kolizji
			mov ax,word ptr ds:[ball_x]	;aktualizacja polozenia w pionie
			add ax,word ptr ds:[speed_x]
			mov word ptr ds:[ball_x],ax
			cmp ax,0 ;sprawdzenie odbicia od gornej krawedzi
			ja checkBotX
			mov word ptr ds:[speed_x],1 ;jesli tak to zmiana pionowego kierunku predkosci
			checkBotX:
			cmp ax,198 ;sprawdzenie przekroczenia dolnej krawedzi ekranu
			jae endGame ;jesli tak to koniec gry
			cmp ax,190 ;sprawdzenie odbicia od paletki
			jb noBounce ;na pewno nie ma odbicia
			;mozliwe odbicie, trzeba dokladnie sprawdzic czy ball_y miesci sie w zakresie dlugosci paletki
			mov ax,word ptr ds:[ball_y]
			add ax,2
			cmp ax,word ptr ds:[paddle]
			ja noBounce ;nie ma odbicia
			mov ax,word ptr ds:[paddle]
			sub ax,29
			cmp ax,word ptr ds:[ball_y]
			ja noBounce ;nie ma odbicia
			mov word ptr ds:[speed_x],-1 ;jest odbicie, zmiana pionowego kierunku predkosci					
				noBounce: ;brak odbicia w pionie, sprawdzenie odbicia w poziomie
					mov ax,word ptr ds:[ball_y] ;aktualizacja predkosci w poziomie
					add ax,word ptr ds:[speed_y]
					mov word ptr ds:[ball_y],ax
					cmp ax,0 ;sprawdzenie odbicia od lewej krawedzi
					ja rightBounce ;nie ma odbicia
					mov word ptr ds:[speed_y],1 ;jest odbicie, zmiana poziomego kierunku predkosci
					rightBounce:
						cmp ax,318 ;sprawdzenie odbicia od prawej krawedzi
						jb done ;nie ma odbicia
						mov word ptr ds:[speed_y],-1 ;jest odbicie, zmiana poziomego kierunku predkosci
				done: ;koniec obslugi zmiany polozenia pilki i detekcji kolizji
					jmp clearScreen 
					
		clearScreen:
			xor cx,cx ;koordynaty lewego gornego rogu
			xor bx,bx ;kolor
			mov dx,63999 ;koordynaty prawego gornego rogu
			mov ah,06h	; przewijanie
			mov al,0	; czyszczenie
			int 10h
			jmp drawPaddle
			
		drawPaddle:
			mov ax,191 ;ustalenie pozycji paletki
			mov byte ptr ds:[kolor],108
			call setReg
			add di,word ptr ds:[paddle]
			
			mov cx,8 ;grubosc paletki
			draw1:
				add di,290
				push cx ;zachowujemy wartosc cx na stosie
				mov cx,30 ;szerokosc paletki
				call drawLine
				pop cx
				loop draw1
			jmp drawBall
		
		drawBall:
			mov ax,word ptr ds:[ball_x] ;ustalenie pozycji pileczki
			mov byte ptr ds:[kolor],12
			call setReg
			add di,word ptr ds:[ball_y]
			mov cx,3
			call drawLine
			mov cx,3
			add di,317
			call drawLine
			mov cx,3
			add di,317
			call drawLine
			jmp game
		
		;procedura rysujaca pozioma linie o dlugosci cx
		drawLine:
			mov byte ptr es:[di],al
			inc di
			loop drawLine
			ret
		
		; procedura ustawia rejestry
		setReg:
			mov word ptr ds:[temp],ax
			mov ax,word ptr ds:[temp]
			mov cx,320
			mul cx
			mov di,ax
			mov al,byte ptr ds:[kolor]	;kolor
			ret

		endGame: ;powrot do trybu tekstowego, wyswietlenie komunikatu o koncu gry i powrot do DOS
			mov ax,03h
			int 10h
			mov dx,offset endmsg
			mov ah,9
			int 21h
			mov ax,04c00h
			int 21h

kod ends

stos1 segment STACK
	db 200 dup(?)
	top1	db ? 
stos1 ends

end start
		
		