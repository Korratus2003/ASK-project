[bits 32]

section  .data
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
global   _seq2
global   _seq3

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

_seq2:
;                     +4
;        esp -> [addr][n]
         mov ecx, [esp+4]  ; ecx = *(int*)(esp+4) = n
         
         ; Walidacja n >= 1
         cmp ecx, 1       ; ecx - 1            ; OF SF ZF AF PF CF affected
         jl invalid_n     ; jump if less than 1
         
         finit  ; fpu init

;        st = []  ; fpu stack

         ; Wartości początkowe są już zdefiniowane w sekcji .data

         fld qword [addr_b]  ; *(double*)addr_b = 4,0 -> st = [b]    ; fpu load floating-point 		 
         fld qword [addr_a]  ; *(double*)addr_a = 3.0 -> st = [a, b]  ;      		 

;        st = [st0, st1] = [a, b]

         cmp ecx, 1      ; ecx - 1            ; OF SF ZF AF PF CF affected
         jne next1_seq2  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

         ; Return a (3.0) for n=1
         fstp st1        ; pop b, keep a on stack
         ret             ; return with a on FPU stack
         
next1_seq2:
         cmp ecx, 2       ; ecx - 2            ; OF SF ZF AF PF CF affected
         jne shift_seq2   ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

         ; Return b (4.0) for n=2
         fstp st0        ; pop a
         ; b remains on stack
         ret             ; return with b on FPU stack
		 
shift_seq2:   
		 sub ecx, 2  ; ecx = ecx - 2 ; dzięki temu pętla wykonuje sie odpowiednią ilość razy (n-2)
		 
.loop_seq2:	 
         
         finit  ; fpu init and clear stack

;        st = []  ; fpu stack       
         
;		 ładujemy wartości, d będzie istniało tylko na stosie fpu jako tymczasowe
;										    					   temporary d = a
         fld qword [addr_a]  ; *(double*)addr_a = a -> st = [a]    ; fpu load floating-point																					 
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

		 faddp st1  ; st1 = st1 + st0 and pop
		 
;        st = [st0] = [2*d + 0.5*a]

		 fstp qword [addr_b]   ; addr_b = b = st0 
		 
;        st = []  ; fpu stack 	

         loop .loop_seq2

         fld qword [addr_b]   ; *(double*)addr_b = b -> st = [b]	

;        st = [b]
        
         ret  ; return with result on FPU stack

invalid_n:
         finit
         fldz    ; load 0.0 on FPU stack for invalid input
         ret

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

_seq3:
;                     +4
;        esp -> [addr][n]
         mov ecx, [esp+4]  ; ecx = *(int*)(esp+4) = n
         
         ; Walidacja n >= 1
         cmp ecx, 1       ; ecx - 1            ; OF SF ZF AF PF CF affected
         jl invalid_n3    ; jump if less than 1
         
         finit  ; fpu init

;        st = []  ; fpu stack

         ; Wartości początkowe są już zdefiniowane w sekcji .data

         fld qword [addr_c1]  ; *(double*)addr_c1 = 8.0 -> st = [c]       ; fpu load floating-point 	
         fld qword [addr_b1]  ; *(double*)addr_b1 = 4.0 -> st = [b, c]     ; 	      		 
         fld qword [addr_a1]  ; *(double*)addr_a1 = 3.0 -> st = [a, b, c]  ;  
         	
;        st = [st0, st1, st2] = [a, b, c]

         cmp ecx, 1      ; ecx - 1            ; OF SF ZF AF PF CF affected
         jne next1_seq3  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

         ; Return a1 (3.0) for n=1
         fstp st2        ; pop c
         fstp st1        ; pop b  
         ret             ; return with a on FPU stack
         
next1_seq3:
         cmp ecx, 2      ; ecx - 2            ; OF SF ZF AF PF CF affected
         jne next2_seq3  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

         ; Return b1 (4.0) for n=2
         fstp st0        ; pop a
         fstp st1        ; pop c
         ret             ; return with b on FPU stack
         
next2_seq3:
         cmp ecx, 3      ; ecx - 3            ; OF SF ZF AF PF CF affected
         jne shift_seq3  ; jump if not equal  ; jump if eax != ecx ; jump if ZF = 0

         ; Return c1 (8.0) for n=3
         fstp st0        ; pop a
         fstp st0        ; pop b		 
         ret             ; return with c on FPU stack
         		 
shift_seq3:   
		 sub ecx, 3  ; ecx = ecx - 3 ; dzięki temu pętla wykonuje sie odpowiednią ilość razy (n-3)
		 
.loop_seq3:	 

         finit  ; fpu init and clear stack

;        st = []  ; fpu stack       
         
;		 ładujemy oraz zamieniamy wartości zmiennych

		 fld qword [addr_b1]  ; *(double*)addr_b1 = b1 -> st = [b1]
		 fstp qword [addr_a1] ; *(double*)addr_a1 <- st = b1 ; a1 = b1 ; fpu store floating-point value and pop
		 
		 fld qword [addr_c1]  ; *(double*)addr_c1 = c1 -> st = [c1]
		 fstp qword [addr_b1] ; *(double*)addr_b1 <- st = c1 ; b1 = c1 ; fpu store floating-point value and pop	 

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

		 faddp st1  ; st1 = st1 + st0 and pop
		 
;        st = [st0] = [2*a1 + 0.5*b1]

		 fstp qword [addr_c1]   ; addr_c1 = c1 = st0  ;
		 
;        st = []  ; fpu stack 		 

         loop .loop_seq3

         fld qword [addr_c1]   ; *(double*)addr_c1 = c1 -> st = [c1]	

;        st = [c1]
        
         ret  ; return with result on FPU stack

invalid_n3:
         finit
         fldz    ; load 0.0 on FPU stack for invalid input
         ret
