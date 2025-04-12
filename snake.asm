.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD
INCLUDE Irvine32.inc

.data
; Renk sabitleri
SNAKE_COLOR = lightGreen
WALL_COLOR = white
FOOD_COLOR = red
TEXT_COLOR = yellow

; Yem türleri
FOOD_TYPE_NORMAL = 0
FOOD_TYPE_FAST = 1
FOOD_TYPE_SLOW = 2
FOOD_TYPE_BONUS = 3

; Yem sembolleri
normalFood BYTE "O"
fastFood BYTE "F"
slowFood BYTE "S"
bonusFood BYTE "B"

; Yem türü ve süresi
currentFoodType BYTE ?
foodTimer DWORD 0

xWall BYTE 52 DUP("#"), 0
strScore BYTE "Skor: ", 0
score BYTE 0
strTryAgain BYTE "Tekrar Dene?  1=evet, 0=hayir", 0
invalidInput BYTE "Geçersiz giriş", 0
strYouDied BYTE "Geberdin kanka ", 0
strPoints BYTE " puan", 0
blank BYTE "                                     ", 0

snake BYTE "X", 104 DUP("x")

xPos BYTE 45,44,43,42,41, 100 DUP(?)
yPos BYTE 15,15,15,15,15, 100 DUP(?)

xPosWall BYTE 34,34,85,85
yPosWall BYTE 5,24,5,24

xCoinPos BYTE ?
yCoinPos BYTE ?

inputChar BYTE "+" 
lastInputChar BYTE ?

strSpeed BYTE "Hız (1-hızlı, 2-orta, 3-yavaş): ", 0
speed DWORD 0

strGameOver BYTE "OYUN BİTTİ!", 0
strFinalScore BYTE "Toplam Puan: ", 0
strHighScore BYTE "En Yüksek Puan: ", 0
strNewHighScore BYTE "Yeni Rekor!", 0
highScore BYTE 0

.code
main PROC
    call DrawWall
    call DrawScoreboard
    call ChooseSpeed

    mov esi, 0
    mov ecx, 5

drawSnake:
    call DrawPlayer
    inc esi
loop drawSnake

    call Randomize
    call CreateRandomCoin
    call DrawCoin

gameLoop::
    mov dl, 106
    mov dh, 1
    call Gotoxy
    call ReadKey
    jz noKey

    mov bl, inputChar
    mov lastInputChar, bl
    mov inputChar, al

noKey:
    cmp inputChar, "x"
    je exitgame

    cmp inputChar, "w"
    je checkTop

    cmp inputChar, "s"
    je checkBottom

    cmp inputChar, "a"
    je checkLeft

    cmp inputChar, "d"
    je checkRight
    jne gameLoop

    ; Hareket kontrolleri ve ölü kontrolü
checkBottom: 
    cmp lastInputChar, "w"
    je dontChgDirection
    mov cl, yPosWall[1]
    dec cl
    cmp yPos[0], cl
    jl moveDown
    je died

checkLeft: 
    cmp lastInputChar, "+"
    je dontGoLeft
    cmp lastInputChar, "d"
    je dontChgDirection
    mov cl, xPosWall[0]
    inc cl
    cmp xPos[0], cl
    jg moveLeft
    je died

checkRight: 
    cmp lastInputChar, "a"
    je dontChgDirection
    mov cl, xPosWall[2]
    dec cl
    cmp xPos[0], cl
    jl moveRight
    je died

checkTop: 
    cmp lastInputChar, "s"
    je dontChgDirection
    mov cl, yPosWall[0]
    inc cl
    cmp yPos, cl
    jg moveUp
    je died

; Yukarı hareket
moveUp:
    mov eax, speed
    add eax, speed
    call delay
    mov esi, 0
    call UpdatePlayer
    dec yPos[esi]
    call DrawPlayer
    call DrawBody
    call CheckSnake
    jmp gameLoop

; Aşağı hareket
moveDown: 
    mov eax, speed
    add eax, speed
    call delay
    mov esi, 0
    call UpdatePlayer
    inc yPos[esi]
    call DrawPlayer
    call DrawBody
    call CheckSnake
    jmp gameLoop

; Sol hareket
moveLeft: 
    mov eax, speed
    call delay
    mov esi, 0
    call UpdatePlayer
    dec xPos[esi]
    call DrawPlayer
    call DrawBody
    call CheckSnake
    jmp gameLoop

; Sağ hareket
moveRight: 
    mov eax, speed
    call delay
    mov esi, 0
    call UpdatePlayer
    inc xPos[esi]
    call DrawPlayer
    call DrawBody
    call CheckSnake
    jmp gameLoop

checkcoin::
    mov esi, 0
    mov bl, xPos[0]
    cmp bl, xCoinPos
    jne gameLoop
    mov bl, yPos[0]
    cmp bl, yCoinPos
    jne gameLoop

    call EatingCoin
    jmp gameLoop

dontChgDirection: 
    mov inputChar, bl
    jmp noKey

dontGoLeft: 
    mov inputChar, "+"
    jmp gameLoop

; Oyun bittiğinde
died:: 
    call YouDied
    call ReinitializeGame
    jmp main

exitgame::
    INVOKE ExitProcess, 0
main ENDP

; Renk ayarlama fonksiyonu
SetColor PROC
    push eax
    mov eax, SNAKE_COLOR
    call SetTextColor
    pop eax
    ret
SetColor ENDP

; Duvar rengini ayarlama
SetWallColor PROC
    push eax
    mov eax, WALL_COLOR
    call SetTextColor
    pop eax
    ret
SetWallColor ENDP

; Yem rengini ayarlama
SetFoodColor PROC
    push eax
    mov eax, FOOD_COLOR
    call SetTextColor
    pop eax
    ret
SetFoodColor ENDP

; Metin rengini ayarlama
SetTextColor PROC
    push eax
    mov eax, TEXT_COLOR
    call SetTextColor
    pop eax
    ret
SetTextColor ENDP

CreateRandomCoin PROC
    call Randomize
    mov eax, 4
    call RandomRange
    mov currentFoodType, al
    
    cmp al, FOOD_TYPE_NORMAL
    je normal
    cmp al, FOOD_TYPE_FAST
    je fast
    cmp al, FOOD_TYPE_SLOW
    je slow
    cmp al, FOOD_TYPE_BONUS
    je bonus
    
normal:
    mov al, normalFood
    jmp done
fast:
    mov al, fastFood
    jmp done
slow:
    mov al, slowFood
    jmp done
bonus:
    mov al, bonusFood
done:
    ret
CreateRandomCoin ENDP

EatingCoin PROC
    mov al, currentFoodType
    cmp al, FOOD_TYPE_NORMAL
    je normalFoodEaten
    cmp al, FOOD_TYPE_FAST
    je fastFoodEaten
    cmp al, FOOD_TYPE_SLOW
    je slowFoodEaten
    cmp al, FOOD_TYPE_BONUS
    je bonusFoodEaten
    
normalFoodEaten:
    inc score
    jmp done
fastFoodEaten:
    mov eax, speed
    sub eax, 50
    mov speed, eax
    jmp done
slowFoodEaten:
    mov eax, speed
    add eax, 50
    mov speed, eax
    jmp done
bonusFoodEaten:
    add score, 5
done:
    ret
EatingCoin ENDP

YouDied PROC
    call Clrscr
    call SetTextColor
    
    mov dl, 40
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET strGameOver
    call WriteString
    
    mov dl, 40
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strFinalScore
    call WriteString
    mov al, score
    call WriteDec
    
    mov al, score
    cmp al, highScore
    jle noNewHighScore
    
    mov highScore, al
    mov dl, 40
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET strNewHighScore
    call WriteString
    
noNewHighScore:
    mov dl, 40
    mov dh, 16
    call Gotoxy
    mov edx, OFFSET strHighScore
    call WriteString
    mov al, highScore
    call WriteDec
    
    mov dl, 40
    mov dh, 18
    call Gotoxy
    mov edx, OFFSET strTryAgain
    call WriteString
    
    call ReadChar
    cmp al, "1"
    je continue
    cmp al, "0"
    je exit
    
continue:
    ret
    
exit:
    INVOKE ExitProcess, 0
YouDied ENDP

; Diğer fonksiyonlar burada
