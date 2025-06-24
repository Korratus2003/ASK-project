         [bits 32]

;        esp -> [ret]  ; ret - adres powrotu do asmloader

         call print_name  ; push on the stack the run-time address of format_name and jump to print_name
format_name:
         db "sequence.asm", 0xA, 0xA, 0
print_name:

;        esp -> [format_name][ret]

         call [ebx+3*4]  ; printf(format_name)
         add esp, 4      ; esp = esp + 4

get_n:
         call getaddr  ; push on the stack the run-time address of format and jump to getaddr
format:
         db "Podaj n = ", 0
getaddr:

;        esp -> [format][ret]

         call [ebx+3*4]  ; printf(format)
         
;        esp -> [n][ret] ; zmienna a adres format nie jest juz potrzebny

         push esp  ; esp -> stack = addr_n
         
;        esp -> [addr_a][a][ret]

         call getaddr_n  ; push on the stack the run-time address of format_n and jump to getaddr_n
format_n:
         db "%d", 0
getaddr_n:

;        esp -> [format_n][addr_n][n][ret]

         call [ebx+4*4]  ; scanf(format_n, addr_n)
         add esp, 2*4    ; esp = esp + 8

;        esp -> [n][ret]
         
		 cmp eax, 1           ; eax - 1 	; OF SF ZF AF PF CF affected
		 
		 je check_newline	  ; jump if equal
		 
clear_fail:
		 call [ebx + 2*4]  ; getchar()
		 
		 cmp al, 0x0A      ; al - 0x0A		; OF SF ZF AF PF CF affected
		 
		 jne clear_fail   ; jump if not equal  ; jump if al!= 0x0A ; jump if ZF = 0
		 		 
		 add esp, 4  ; esp = esp + 4  ; n jest nie poprawne, zdejmujemy je ze stosu
		 
		 jmp get_n

check_newline:
		 call [ebx + 2*4]  ; getchar()
		 
		 cmp al, 0x0A	   ; al - 0x0A	 	; OF SF ZF AF PF CF affected
		 
		 je validate_n     ; jump if equal
clear_extra:
		 call [ebx + 2*4]  ; getchar()
		 
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
         
		 call fpu_load_seq2 ; push on the stack the run-time address of addr_d and jump to fpu_load_seq2
addr_a	 dq 3.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; define quad word    
addr_05  dq 0.5  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_05 = addr_a + 8
addr_b	 dq 4.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_b = addr_a + 16
addr_2   dq 2.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_2 = addr_a + 24	
fpu_load_seq2:

;        esp -> [addr_a][ret]

         finit  ; fpu init

;        st = []  ; fpu stack

         mov edi, [esp]  ; edi = *(int*)esp = addr_a

         fld qword [edi+16]  ; *(double*)(edi+16) = *(double*)addr_b = 4,0 -> st = [b]    ; fpu load floating-point 		 
         fld qword [edi]     ; *(double*)(edi+0) = *(double*)addr_a = 3.0 -> st = [a, b]  ;      		 

;        st = [st0, st1] = [a, b]

         cmp ecx, 1      ; ecx - 1            ; OF SF ZF AF PF CF affected
         jne next1_seq2  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

;        Robimy miejsce na wartosc typu double

         sub esp, 4  ; esp = esp - 4
         
;        esp -> [ ][ ][ret]  ; addr_a nie jest juz potrzebny  
		 
         fstp qword [esp]  ; *(double*)esp <- st = a ; fpu store floating-point value and pop 
         fstp st0 		   ; pop st0
         
;        st = []              
		 
;        esp -> [fl][fh][ret]

         jmp done_seq2
         
next1_seq2:
         cmp ecx, 2       ; ecx - 2            ; OF SF ZF AF PF CF affected
         jne shift_seq2   ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

;        Robimy miejsce na wartosc typu double

         sub esp, 4  ; esp = esp - 4
         
;        esp -> [ ][ ][ret]  ; addr_a nie jest juz potrzebny  

		 fstp st0  ; pop st0

;        st = [st0] = [b]		 
		 
         fstp qword [esp]  ; *(double*)esp <- st = b ; fpu store floating-point value and pop      

;        st = []    		 
		 
;        esp -> [fl][fh][ret]
	
         jmp done_seq2
		 
shift_seq2:   
		 sub ecx, 2  ; ecx = ecx - 2 ; dzięki temu pętla wykonuje sie odpowiednią ilość razy (n-2)
		 
.loop_seq2:	 

;        esp -> [addr_a][ret]
         
         finit  ; fpu init and clear stack

;        st = []  ; fpu stack       
         
;		 ładujemy wartości, d będzie istniało tylko na stosie fpu jako tymczasowe
;										    					   temporary d = a
         fld qword [edi]     ; *(double*)(edi+0) = *(double*)addr_a = 0.0 -> st = [a]    ; fpu load floating-point																					 
         fld qword [edi+24]  ; *(double*)(edi+24) = *(double*)addr_2 = 2 -> st = [2, d]  ; 
         
;		 aktualizujemy a do nowej wartości         
         fld qword [edi+16]  ; *(double*)(edi+16) = *(double*)addr_b = b -> st = [b, 2, d]
		 fstp qword [edi]    ; *(double*)(edi+8) <- st = b ; a = b ; fpu store floating-point value and pop

;        st = [st0, st1] = [2, d]	

;		 kontynuujemy ładowanie na stos           																						   
         fld qword [edi+8]   ; *(double*)(edi+16) = *(double*)addr_05 = 0.5 -> st = [ 0.5 , 2, d]          																				 	          
         fld qword [edi]     ; *(double*)(edi+0) = *(double*)addr_a = a -> st = [a ,0.5 , 2, d]     
		          	
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

		 fstp qword [edi+16]   ; [edi+16] = b = st0 
		 
;        st = []  ; fpu stack 	

         loop .loop_seq2

         fld qword [edi+16]   ; *(double*)(edi+16) = *(double*)addr_b = b -> st = [b]	

;        st = [b]
         
;        Robimy miejsce na wartosc typu double

         sub esp, 8  ; esp = esp - 4

;        esp -> [ ][ ][ret]  ; addr_a nie jest juz potrzebny   
      
         fstp qword [esp]  ; *(double*)esp <- st = 0.5*a + 2*d  ; fpu store floating-point value and pop

;        st = []

;        esp -> [fl][fh][ret]        

done_seq2:
         push esi  ; n -> stack

         call getaddr3  ; push on the stack the run-time address of format3 and jump to getaddr3 
format3:
         db "seq2(%d) = %.2f", 0xA, 0
getaddr3:

;        esp -> [format3][esi][fl][fh][ret]

         call [ebx+3*4]  ; printf(format3, esi, fl:fh);
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
         
		 call fpu_load_seq3 ; push on the stack the run-time address of addr_d and jump to .loop
addr_a1    dq 3.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; define quad word
addr_b1	   dq 4.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_b1 = addr_a1 + 8  
addr_05_1  dq 0.5  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_05 = addr_a1 + 16
addr_c1	   dq 8.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_c1 = addr_a1 + 24
addr_2_1   dq 2.0  ; [ ][ ][ ][ ][ ][ ][ ][ ]  ; addr_2 = addr_a1 + 32	
fpu_load_seq3:

;        esp -> [addr_a1][ret]

         finit  ; fpu init

;        st = []  ; fpu stack

         mov edi, [esp]  ; edi = *(int*)esp = addr_a1
         
         fld qword [edi+24]  ; *(double*)(edi+24) = *(double*)addr_c1 = 8.0 -> st = [c]       ; fpu load floating-point 	
         fld qword [edi+8]   ; *(double*)(edi+8) = *(double*)addr_b1 = 4.0 -> st = [b, c]     ; 	      		 
         fld qword [edi]     ; *(double*)(edi+0) = *(double*)addr_a1 = 3.0 -> st = [a, b, c]  ;  
         	
;        st = [st0, st1] = [a, b]

         cmp ecx, 1      ; ecx - 1            ; OF SF ZF AF PF CF affected
         jne next1_seq3  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

;        Robimy miejsce na wartosc typu double

         sub esp, 4  ; esp = esp - 4
         
;        esp -> [ ][ ][ret]  ; addr_a1 nie jest juz potrzebny  
		 
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

         sub esp, 4  ; esp = esp - 4
         
;        esp -> [ ][ ][ret]  ; addr_a1 nie jest juz potrzebny  

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

         sub esp, 4  ; esp = esp - 4
         
;        esp -> [ ][ ][ret]  ; addr_a1 nie jest juz potrzebny  

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

;        esp -> [addr_a1][ret]

         finit  ; fpu init and clear stack

;        st = []  ; fpu stack       
         
;		 ładujemy oraz zamieniamy wartości zmiennych

		 fld qword [edi+8]  ; *(double*)(edi+8) = *(double*)addr_b1 = b1 -> st = [b1]
		 fstp qword [edi]   ; *(double*)(edi+0) <- st = b1 ; a1 = b1 ; fpu store floating-point value and pop
		 
		 fld qword [edi+24]  ; *(double*)(edi+24) = *(double*)addr_c1 = c1 -> st = [c1]
		 fstp qword [edi+8]  ; *(double*)(edi+8) <- st = b1 ; b1 = c1 ; fpu store floating-point value and pop	 

;        st = []  ; fpu stack   


;		 ładujemy zaktualizowane wartości
																				   		
         fld qword [edi]     ; *(double*)(edi+0) = *(double*)addr_a1 = a1 -> st = [a1]     	 	      ; fpu load floating-point																					 
         fld qword [edi+32]  ; *(double*)(edi+32) = *(double*)addr_2_1 = 2 -> st = [2, a1]  	      ;   																						   
         fld qword [edi+16]  ; *(double*)(edi+16) = *(double*)addr_05_1 = 0.5 -> st = [ 0.5 , 2, a1]  ;         																				 	          
         fld qword [edi+8]   ; *(double*)(edi+8) = *(double*)addr_b1 = b1 -> st = [b1 ,0.5 , 2,  a1]  ;

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

		 fstp qword [edi+24]   ; [edi+24] = c = st0  ;
		 
;        st = []  ; fpu stack 		 

         loop .loop_seq3

         fld qword [edi+24]   ; *(double*)(edi+24) = *(double*)addr_c1 = c1 -> st = [c1]	

;        st = [b]
         
;        Robimy miejsce na wartosc typu double

         sub esp, 4  ; esp = esp - 4

;        esp -> [ ][ ][ret]  ; addr_a1 nie jest juz potrzebny   
      
         
         fstp qword [esp]  ; *(double*)esp <- st = 0.5*b1 + 2*a1  ; fpu store floating-point value and pop

;        st = []

;        esp -> [fl][fh][ret]        

done_seq3:
         push esi  ; n -> stack

         call getaddr4  ; push on the stack the run-time address of format4 and jump to getaddr4  
format4:
         db "seq3(%d) = %.2f", 0xA, 0
getaddr4:

;        esp -> [format4][esi][fl][fh][ret]

         call [ebx+3*4]  ; printf(format4, esi, fl:fh);
         add esp, 4*4    ; esp = esp + 16

;        esp -> [ret]

         push 0          ; esp -> [00 00 00 00][ret]
         call [ebx+0*4]  ; exit(0);
         
; asmloader API
;
; ESP wskazuje na prawidlowy stos
; argumenty funkcji wrzucamy na stos
; EBX zawiera pointer na tablice API
;
; call [ebx + NR_FUNKCJI*4] ; wywolanie funkcji API
;
; NR_FUNKCJI:
;
; 0 - exit
; 1 - putchar
; 2 - getchar
; 3 - printf
; 4 - scanf
;
; To co funkcja zwróci jest w EAX.
; Po wywolaniu funkcji sciagamy argumenty ze stosu.
;
; https://gynvael.coldwind.pl/?id=387

%ifdef COMMENT

ebx    -> [ ][ ][ ][ ] -> exit
ebx+4  -> [ ][ ][ ][ ] -> putchar
ebx+8  -> [ ][ ][ ][ ] -> getchar
ebx+12 -> [ ][ ][ ][ ] -> printf
ebx+16 -> [ ][ ][ ][ ] -> scanf

%endif
