.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD
INCLUDE Irvine32.inc

.data

xWall BYTE 52 DUP("#"),0

strScore BYTE "Skor: ",0
score BYTE 0

strTryAgain BYTE "Tekrar Dene?  1=evet, 0=hayir",0
invalidInput BYTE "gecersiz giris",0
strYouDied BYTE "geberdin knk ",0
strPoints BYTE " puan",0
blank BYTE "                                     ",0

snake BYTE "X", 104 DUP("x")

xPos BYTE 45,44,43,42,41, 100 DUP(?)
yPos BYTE 15,15,15,15,15, 100 DUP(?)

xPosWall BYTE 34,34,85,85			
yPosWall BYTE 5,24,5,24

xCoinPos BYTE ?
yCoinPos BYTE ?

inputChar BYTE "+"					
lastInputChar BYTE ?				

strSpeed BYTE "Hiz (1-hizli, 2-orta, 3-yavas): ",0
speed	DWORD 0

.code
main PROC
	call DrawWall			
	call DrawScoreboard		
	call ChooseSpeed		

	mov esi,0
	mov ecx,5
drawSnake:
	call DrawPlayer			
	inc esi
loop drawSnake

	call Randomize
	call CreateRandomCoin
	call DrawCoin			

	gameLoop::
		mov dl,106						
		mov dh,1
		call Gotoxy
		call ReadKey
        jz noKey						
		processInput:
		mov bl, inputChar
		mov lastInputChar, bl
		mov inputChar,al				

		noKey:
		cmp inputChar,"x"	
		je exitgame						

		cmp inputChar,"w"
		je checkTop

		cmp inputChar,"s"
		je checkBottom

		cmp inputChar,"a"
		je checkLeft

		cmp inputChar,"d"
		je checkRight
		jne gameLoop					


		
		checkBottom:	
		cmp lastInputChar, "w"
		je dontChgDirection		
		mov cl, yPosWall[1]
		dec cl					
		cmp yPos[0],cl
		jl moveDown
		je died					

		checkLeft:		
		cmp lastInputChar, "+"	
		je dontGoLeft
		cmp lastInputChar, "d"
		je dontChgDirection
		mov cl, xPosWall[0]
		inc cl
		cmp xPos[0],cl
		jg moveLeft
		je died					

		checkRight:		
		cmp lastInputChar, "a"
		je dontChgDirection
		mov cl, xPosWall[2]
		dec cl
		cmp xPos[0],cl
		jl moveRight
		je died					

		checkTop:		
		cmp lastInputChar, "s"
		je dontChgDirection
		mov cl, yPosWall[0]
		inc cl
		cmp yPos,cl
		jg moveUp
		je died				
		
		moveUp:		
		mov eax, speed		
		add eax, speed
		call delay
		mov esi, 0			
		call UpdatePlayer	
		mov ah, yPos[esi]	
		mov al, xPos[esi]	
		dec yPos[esi]		
		call DrawPlayer		
		call DrawBody
		call CheckSnake

		
		moveDown:			
		mov eax, speed
		add eax, speed
		call delay
		mov esi, 0
		call UpdatePlayer
		mov ah, yPos[esi]
		mov al, xPos[esi]
		inc yPos[esi]
		call DrawPlayer
		call DrawBody
		call CheckSnake


		moveLeft:			
		mov eax, speed
		call delay
		mov esi, 0
		call UpdatePlayer
		mov ah, yPos[esi]
		mov al, xPos[esi]
		dec xPos[esi]
		call DrawPlayer
		call DrawBody
		call CheckSnake


		moveRight:			
		mov eax, speed
		call delay
		mov esi, 0
		call UpdatePlayer
		mov ah, yPos[esi]
		mov al, xPos[esi]
		inc xPos[esi]
		call DrawPlayer
		call DrawBody
		call CheckSnake
		checkcoin::
		mov esi,0
		mov bl,xPos[0]
		cmp bl,xCoinPos
		jne gameloop			
		mov bl,yPos[0]
		cmp bl,yCoinPos
		jne gameloop			

		call EatingCoin			

jmp gameLoop					


	dontChgDirection:		
	mov inputChar, bl		
	jmp noKey				 

	dontGoLeft:				
	mov	inputChar, "+"		
	jmp gameLoop			

	died::
	call YouDied
	 
	playagn::			
	call ReinitializeGame			
	
	exitgame::
	exit
INVOKE ExitProcess,0
main ENDP


DrawWall PROC					
	mov dl,xPosWall[0]
	mov dh,yPosWall[0]
	call Gotoxy	
	mov edx,OFFSET xWall
	call WriteString			

	mov dl,xPosWall[1]
	mov dh,yPosWall[1]
	call Gotoxy	
	mov edx,OFFSET xWall		
	call WriteString			

	mov dl, xPosWall[2]
	mov dh, yPosWall[2]
	mov eax,"#"	
	inc yPosWall[3]
	L11: 
	call Gotoxy	
	call WriteChar	
	inc dh
	cmp dh, yPosWall[3]				
	jl L11

	mov dl, xPosWall[0]
	mov dh, yPosWall[0]
	mov eax,"#"	
	L12: 
	call Gotoxy	
	call WriteChar	
	inc dh
	cmp dh, yPosWall[3]			
	jl L12
	ret
DrawWall ENDP


DrawScoreboard PROC				
	mov dl,2
	mov dh,1
	call Gotoxy
	mov edx,OFFSET strScore		
	call WriteString
	mov eax,"0"
	call WriteChar				
	ret
DrawScoreboard ENDP


ChooseSpeed PROC			
	mov edx,0
	mov dl,71				
	mov dh,1
	call Gotoxy	
	mov edx,OFFSET strSpeed	
	call WriteString
	mov esi, 40				
	mov eax,0
	call readInt			
	cmp ax,1				
	jl invalidspeed
	cmp ax, 3
	jg invalidspeed
	mul esi	
	mov speed, eax			
	ret

	invalidspeed:			
	mov dl,105				
	mov dh,1
	call Gotoxy	
	mov edx, OFFSET invalidInput				
	call WriteString
	mov ax, 1500
	call delay
	mov dl,105				
	mov dh,1
	call Gotoxy	
	mov edx, OFFSET blank				
	call writeString
	call ChooseSpeed					
	ret
ChooseSpeed ENDP

DrawPlayer PROC			
	mov dl,xPos[esi]
	mov dh,yPos[esi]
	call Gotoxy
	mov dl, al			
	mov al, snake[esi]		
	call WriteChar
	mov al, dl			
	ret
DrawPlayer ENDP

UpdatePlayer PROC		
	mov dl, xPos[esi]
	mov dh,yPos[esi]
	call Gotoxy
	mov dl, al			
	mov al, " "
	call WriteChar
	mov al, dl
	ret
UpdatePlayer ENDP

DrawCoin PROC						
	mov eax,yellow (yellow * 16)
	call SetTextColor				
	mov dl,xCoinPos
	mov dh,yCoinPos
	call Gotoxy
	mov al,"X"
	call WriteChar
	mov eax,white (black * 16)		
	call SetTextColor
	ret
DrawCoin ENDP

CreateRandomCoin PROC				
	mov eax,49
	call RandomRange	
	add eax, 35			
	mov xCoinPos,al
	mov eax,17
	call RandomRange	
	add eax, 6			
	mov yCoinPos,al

	mov ecx, 5
	add cl, score				
	mov esi, 0
checkCoinXPos:
	movzx eax,  xCoinPos
	cmp al, xPos[esi]		
	je checkCoinYPos			
	continueloop:
	inc esi
loop checkCoinXPos
	ret							
	checkCoinYPos:
	movzx eax, yCoinPos			
	cmp al, yPos[esi]
	jne continueloop			
	call CreateRandomCoin		
CreateRandomCoin ENDP

CheckSnake PROC				
	mov al, xPos[0] 
	mov ah, yPos[0] 
	mov esi,4				
	mov ecx,1
	add cl,score
checkXposition:
	cmp xPos[esi], al		
	je XposSame
	contloop:
	inc esi
loop checkXposition
	jmp checkcoin
	XposSame:				
	cmp yPos[esi], ah
	je died					
	jmp contloop

CheckSnake ENDP

DrawBody PROC				
		mov ecx, 4
		add cl, score	
		printbodyloop:	
		inc esi				
		call UpdatePlayer
		mov dl, xPos[esi]
		mov dh, yPos[esi]	
		mov yPos[esi], ah
		mov xPos[esi], al	
		mov al, dl
		mov ah,dh		
		call DrawPlayer
		cmp esi, ecx
		jl printbodyloop
	ret
DrawBody ENDP

EatingCoin PROC
	inc score
	mov ebx,4
	add bl, score
	mov esi, ebx
	mov ah, yPos[esi-1]
	mov al, xPos[esi-1]	
	mov xPos[esi], al		
	mov yPos[esi], ah		

	cmp xPos[esi-2], al		
	jne checky				

	cmp yPos[esi-2], ah		
	jl incy			
	jg decy
	incy:					
	inc yPos[esi]
	jmp continue
	decy:					
	dec yPos[esi]
	jmp continue

	checky:					
	cmp yPos[esi-2], ah		
	jl incx
	jg decx
	incx:					
	inc xPos[esi]			
	jmp continue
	decx:					
	dec xPos[esi]

	continue:				
	call DrawPlayer		
	call CreateRandomCoin
	call DrawCoin			

	mov dl,17				
	mov dh,1
	call Gotoxy
	mov al,score
	call WriteInt
	ret
EatingCoin ENDP


YouDied PROC
	mov eax, 1000
	call delay
	Call ClrScr	
	
	mov dl,	57
	mov dh, 12
	call Gotoxy
	mov edx, OFFSET strYouDied	
	call WriteString

	mov dl,	56
	mov dh, 14
	call Gotoxy
	movzx eax, score
	call WriteInt
	mov edx, OFFSET strPoints	
	call WriteString

	mov dl,	50
	mov dh, 18
	call Gotoxy
	mov edx, OFFSET strTryAgain
	call WriteString		

	retry:
	mov dh, 19
	mov dl,	56
	call Gotoxy
	call ReadInt			
	cmp al, 1
	je playagn				
	cmp al, 0
	je exitgame				

	mov dh,	17
	call Gotoxy
	mov edx, OFFSET invalidInput	
	call WriteString		
	mov dl,	56
	mov dh, 19
	call Gotoxy
	mov edx, OFFSET blank			
	call WriteString
	jmp retry					
YouDied ENDP

ReinitializeGame PROC		
	mov xPos[0], 45
	mov xPos[1], 44
	mov xPos[2], 43
	mov xPos[3], 42
	mov xPos[4], 41
	mov yPos[0], 15
	mov yPos[1], 15
	mov yPos[2], 15
	mov yPos[3], 15
	mov yPos[4], 15			
	mov score,0				
	mov lastInputChar, 0
	mov	inputChar, "+"			
	dec yPosWall[3]			
	Call ClrScr
	jmp main				
ReinitializeGame ENDP
END main