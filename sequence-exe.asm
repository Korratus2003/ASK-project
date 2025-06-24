[bits 32]
extern   _printf
extern   _scanf
extern   _getchar
extern   _exit
section  .data
format_name  db "sequence.asm", 0xA, 0xA, 0
format       db "Podaj n = ", 0
format_n     db "%d", 0
format3      db "seq2(%d) = %.2f", 0xA, 0
format4      db "seq3(%d) = %.2f", 0xA, 0
addr_a       dq 3.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; define quad word    
addr_05      dq 0.5  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_05 = addr_a + 8
addr_b       dq 4.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_b = addr_a + 16
addr_2       dq 2.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_2 = addr_a + 24	
addr_a1      dq 3.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; define quad word
addr_b1	     dq 4.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_b1 = addr_a1 + 8  
addr_05_1    dq 0.5  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_05 = addr_a1 + 16
addr_c1	     dq 8.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_c1 = addr_a1 + 24
addr_2_1     dq 2.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_2 = addr_a1 + 32	

section  .text
global   _main
_main:
;        esp -> [ret]  ; ret - adres powrotu do asmloader

         push format_name
;        esp -> [format_name][ret]
         call _printf  ; printf(format_name)
         add esp, 4      ; esp = esp + 4

get_n:
         push format
;        esp -> [format][ret]
         call _printf  ; printf(format)
         add esp, 4    ; esp = esp + 4
         
;        esp -> [ret] 

         push esp  ; esp -> stack = addr_n
         
;        esp -> [addr_n][ret]

         push format_n
;        esp -> [format_n][addr_n][ret]
         call _scanf  ; scanf(format_n, addr_n)
         add esp, 2*4    ; esp = esp + 8

;        esp -> [n][ret]
         
		 cmp eax, 1           ; eax - 1 	; OF SF ZF AF PF CF affected
		 
		 je check_newline	  ; jump if equal
		 
clear_fail:
		 call _getchar  ; getchar()
		 
		 cmp al, 0x0A      ; al - 0x0A		; OF SF ZF AF PF CF affected
		 
		 jne clear_fail   ; jump if not equal  ; jump if al!= 0x0A ; jump if ZF = 0
		 		 
		 add esp, 4  ; esp = esp + 4  ; n jest nie poprawne, zdejmujemy je ze stosu
		 
		 jmp get_n

check_newline:
		 call _getchar  ; getchar()
		 
		 cmp al, 0x0A	   ; al - 0x0A	 	; OF SF ZF AF PF CF affected
		 
		 je validate_n     ; jump if equal
clear_extra:
		 call _getchar  ; getchar()
		 
		 cmp al, 0x0A	   ; al - 0x0A 		; OF SF ZF AF PF CF affected
		 
		 jne clear_extra   ; jump if not equal  ; jump if al!= 0x0A ; jump if ZF = 0
		 
		 add esp, 4  ; esp = esp + 4  ; n jest nie poprawne, zdejmujemy je ze stosu
		 
		 jmp get_n

validate_n:
		 mov esi, [esp]  ; esi = [esp] = n
		 
		 cmp esi, 1  	 ; eax - 1		    ; OF SF ZF AF PF CF affected
		 
		 jl bad_n 	     ; jump if less
		 
;        esp -> [n][ret]  ; n jest poprawne zostaje na stosie
		 
		 jmp seq2
bad_n:
		 add esp, 4  ; esp = esp + 4  ; n jest nie poprawne, zdejmujemy je ze stosu
		 
		 jmp get_n	 
 

%ifdef COMMENT
Ramka dwuzębna
a   b
|---|
1   2    3   4   5   6    indeksy
3   4    8  12  22  35    wartości
|   |---|
d   a   b
    
Przesunięcie ramki w prawo:
d = a
a = b
b = 0.5 * a + 2 * d
%endif

seq2:    
         mov ecx, [esp]  ; ecx = (int)esp = n
         
         pop esi  ; esi <- stack
         
;        esp -> [ret]         
         
         finit  ; fpu init

;        st = []  ; fpu stack

         fld qword [addr_b]  ; *(double*)addr_b = 4,0 -> st = [b]    ; fpu load floating-point 		 
         fld qword [addr_a]  ; *(double*)addr_a = 3.0 -> st = [a, b]  ;      		 

;        st = [st0, st1] = [a, b]

         cmp ecx, 1      ; ecx - 1            ; OF SF ZF AF PF CF affected
         jne next1_seq2  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

;        Robimy miejsce na wartosc typu double

         sub esp, 8  ; esp = esp - 8
         
;        esp -> [ ][ ][ ][ ][ret]
		 
         fstp qword [esp]  ; *(double*)esp <- st = a ; fpu store floating-point value and pop 
         fstp st0 		   ; pop st0
         
;        st = []              
		 
;        esp -> [fl][fh][ret]

         jmp done_seq2
         
next1_seq2:
         cmp ecx, 2       ; ecx - 2            ; OF SF ZF AF PF CF affected
         jne shift_seq2   ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

;        Robimy miejsce na wartosc typu double

         sub esp, 8  ; esp = esp - 8
         
;        esp -> [ ][ ][ ][ ][ret]

		 fstp st0  ; pop st0

;        st = [st0] = [b]		 
		 
         fstp qword [esp]  ; *(double*)esp <- st = b ; fpu store floating-point value and pop      

;        st = []    		 
		 
;        esp -> [fl][fh][ret]
	
         jmp done_seq2
		 
shift_seq2:   
		 sub ecx, 2  ; ecx = ecx - 2 ; dzięki temu pętla wykonuje sie odpowiednią ilość razy (n-2)
		 
.loop_seq2:	 
         
         finit  ; fpu init and clear stack

;        st = []  ; fpu stack       
         
;		 ładujemy wartości, d będzie istniało tylko na stosie fpu jako tymczasowe
;										    					   temporary d = a
         fld qword [addr_a]  ; *(double*)addr_a = 0.0 -> st = [a]    ; fpu load floating-point																					 
         fld qword [addr_2]  ; *(double*)addr_2 = 2 -> st = [2, d]  ; 
         
;		 aktualizujemy a do nowej wartości         
         fld qword [addr_b]  ; *(double*)addr_b = b -> st = [b, 2, d]
		 fstp qword [addr_a] ; *(double*)addr_a <- st = b ; a = b ; fpu store floating-point value and pop

;        st = [st0, st1] = [2, d]	

;		 kontynuujemy ładowanie na stos           																						   
         fld qword [addr_05] ; *(double*)addr_05 = 0.5 -> st = [ 0.5 , 2, d]          																				 	          
         fld qword [addr_a]  ; *(double*)addr_a = a -> st = [a ,0.5 , 2, d]     
		          	
;        st = [st0, st1, st2, st3] = [a ,0.5 , 2, d]		 	 

;        Wykonaj obliczenia przy pomocy FPU		 

;        fmulp st1  ; [st0, st1, st2, st3] => [st0, st1*st0, st2, st3] => [st1*st0, st2, st3]

         fmulp st1  ; st1 = st1 * st0 and pop

;        st = [st0, st1, st2] = [0.5*a, 2, d]

		 fxch st2  ; (st0, st2) = (st2, st0)
		 
;        st = [st0, st1, st2] = [d, 2, 0.5*a]
 
;        fmulp st1  ; [st0, st1, st2] => [st0, st1*st0, st2] => [st1*st0, st2]

         fmulp st1  ; st1 = st1 * st0 and pop
         
;        st = [st0, st1] = [2*d, 0.5*a]  

;		 faddp st1  ; [st0, st1] => [st0 + st1] = [2*d + 0.5*a]

		 faddp st1  ; st1 = st1 * st0 and pop
		 
;        st = [st0] = [2*d + 0.5*a]

		 fstp qword [addr_b]   ; addr_b = b = st0 
		 
;        st = []  ; fpu stack 	

         loop .loop_seq2

         fld qword [addr_b]   ; *(double*)addr_b = b -> st = [b]	

;        st = [b]
         
;        Robimy miejsce na wartosc typu double

         sub esp, 8  ; esp = esp - 8

;        esp -> [ ][ ][ ][ ][ret]
      
         fstp qword [esp]  ; *(double*)esp <- st = 0.5*a + 2*d  ; fpu store floating-point value and pop

;        st = []

;        esp -> [fl][fh][ret]        

done_seq2:
         push esi  ; n -> stack

         push format3
;        esp -> [format3][esi][fl][fh][ret]

         call _printf  ; printf(format3, esi, fl:fh);
         add esp, 4*4    ; esp = esp + 16

;        esp -> [ret]

		 push esi  ; esi -> stack

;        esp -> [n][ret]		 

%ifdef COMMENT
Ramka trójzębna
a1  b1   c1
|---|----|
1   2    3   4   5   6    indeksy
3   4    8  12  22  35    wartości
    |---|---|
    a1  b1  c1

Przesunięcie ramki w prawo:
a1 = b1
b1 = c1
c1 = 0.5 * b1 + 2 * a1
%endif

seq3:    
         mov ecx, [esp]  ; ecx = (int)esp = n
         
         pop esi  ; esi <- stack
         
;        esp -> [ret]         
         
         finit  ; fpu init

;        st = []  ; fpu stack

         fld qword [addr_c1]  ; *(double*)addr_c1 = 8.0 -> st = [c]       ; fpu load floating-point 	
         fld qword [addr_b1]  ; *(double*)addr_b1 = 4.0 -> st = [b, c]     ; 	      		 
         fld qword [addr_a1]  ; *(double*)addr_a1 = 3.0 -> st = [a, b, c]  ;  
         	
;        st = [st0, st1] = [a, b]

         cmp ecx, 1      ; ecx - 1            ; OF SF ZF AF PF CF affected
         jne next1_seq3  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

;        Robimy miejsce na wartosc typu double

         sub esp, 8  ; esp = esp - 8
         
;        esp -> [ ][ ][ ][ ][ret]
		 
         fstp qword [esp]  ; *(double*)esp <- st = a1 ; fpu store floating-point value and pop 
         fstp st0 		   ; pop st0
         fstp st0 		   ; pop st0
         
;        st = []              
		 
;        esp -> [fl][fh][ret]

         jmp done_seq3
         
next1_seq3:
         cmp ecx, 2      ; ecx - 2            ; OF SF ZF AF PF CF affected
         jne next2_seq3  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

;        Robimy miejsce na wartosc typu double

         sub esp, 8  ; esp = esp - 8
         
;        esp -> [ ][ ][ ][ ][ret]

		 fstp st0  ; pop st0

;        st = [st0] = [b]		 
		 
         fstp qword [esp]  ; *(double*)esp <- st = b ; fpu store floating-point value and pop      
		
		 fstp st0  ; pop st0	 

;        st = []    		 
		 
;        esp -> [fl][fh][ret]
	
         jmp done_seq3
         
next2_seq3:
         cmp ecx, 3      ; ecx - 2            ; OF SF ZF AF PF CF affected
         jne shift_seq3  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

;        Robimy miejsce na wartosc typu double

         sub esp, 8  ; esp = esp - 8
         
;        esp -> [ ][ ][ ][ ][ret]

		 fstp st0  ; pop st0
		 fstp st0  ; pop st0		 

;        st = [st0] = [b]		 
		 
         fstp qword [esp]  ; *(double*)esp <- st = b ; fpu store floating-point value and pop      

;        st = []    		 
		 
;        esp -> [fl][fh][ret]
	
         jmp done_seq3
         		 
shift_seq3:   
		 sub ecx, 3  ; ecx = ecx - 3 ; dzięki temu pętla wykonuje sie odpowiednią ilość razy (n-3)
		 
.loop_seq3:	 

         finit  ; fpu init and clear stack

;        st = []  ; fpu stack       
         
;		 ładujemy oraz zamieniamy wartości zmiennych

		 fld qword [addr_b1]  ; *(double*)addr_b1 = b1 -> st = [b1]
		 fstp qword [addr_a1] ; *(double*)addr_a1 <- st = b1 ; a1 = b1 ; fpu store floating-point value and pop
		 
		 fld qword [addr_c1]  ; *(double*)addr_c1 = c1 -> st = [c1]
		 fstp qword [addr_b1] ; *(double*)addr_b1 <- st = b1 ; b1 = c1 ; fpu store floating-point value and pop	 

;        st = []  ; fpu stack   


;		 ładujemy zaktualizowane wartości
																				   		
         fld qword [addr_a1]  ; *(double*)addr_a1 = a1 -> st = [a1]     	 	      ; fpu load floating-point																					 
         fld qword [addr_2_1] ; *(double*)addr_2_1 = 2 -> st = [2, a1]  	      ;   																						   
         fld qword [addr_05_1]; *(double*)addr_05_1 = 0.5 -> st = [ 0.5 , 2, a1]  ;         																				 	          
         fld qword [addr_b1]  ; *(double*)addr_b1 = b1 -> st = [b1 ,0.5 , 2,  a1]  ;

;        st = [st0, st1, st2, st3] = [b1 ,0.5 , 2,  a1]		 	 

;        Wykonaj obliczenia przy pomocy FPU		 

;        fmulp st1  ; [st0, st1, st2, st3] => [st0, st1*st0, st2, st3] => [st1*st0, st2, st3]

         fmulp st1  ; st1 = st1 * st0 and pop

;        st = [st0, st1, st2] = [0.5*b1, 2, a1]

		 fxch st2  ; (st0, st2) = (st2, st0)
		 
;        st = [st0, st1, st2] = [a1, 2, 0.5*b1]
 
;        fmulp st1  ; [st0, st1, st2] => [st0, st1*st0, st2] => [st1*st0, st2]

         fmulp st1  ; st1 = st1 * st0 and pop
         
;        st = [st0, st1] = [2*a1, 0.5*b1]  

;		 faddp st1  ; [st0, st1] => [st0 + st1] = [2*a1 + 0.5*b1]

		 faddp st1  ; st1 = st1 * st0 and pop
		 
;        st = [st0] = [2*a1 + 0.5*b1]

		 fstp qword [addr_c1]   ; addr_c1 = c = st0  ;
		 
;        st = []  ; fpu stack 		 

         loop .loop_seq3

         fld qword [addr_c1]   ; *(double*)addr_c1 = c1 -> st = [c1]	

;        st = [b]
         
;        Robimy miejsce na wartosc typu double

         sub esp, 8  ; esp = esp - 8

;        esp -> [ ][ ][ ][ ][ret]
      
         
         fstp qword [esp]  ; *(double*)esp <- st = 0.5*b1 + 2*a1  ; fpu store floating-point value and pop

;        st = []

;        esp -> [fl][fh][ret]        

done_seq3:
         push esi  ; n -> stack

         push format4
;        esp -> [format4][esi][fl][fh][ret]

         call _printf  ; printf(format4, esi, fl:fh);
         add esp, 4*4  ; esp = esp + 16

;        esp -> [ret]

         push 0      ; esp -> [00 00 00 00][ret]
         call _exit  ; exit(0);
         
%ifdef COMMENT
Kompilacja:

nasm sequence.asm -o sequence.o -f win32

ld sequence.o -o sequence.exe c:\windows\system32\msvcrt.dll -m i386pe

lub:
nasm sequence.asm -o sequence.o -f win32

gcc sequence.o -o sequence.exe -m32
%endif

