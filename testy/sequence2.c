#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Deklaracje funkcji z assemblera
extern double seq2(int);
extern double seq3(int);

/*
Sekwencja: 3, 4, 8, 12, 22, 35, ...
Indeksy:   1, 2, 3,  4,  5,  6, ...

Ramka dwuzębna seq2:
r0  r1
|---|
1   2    3   4   5   6    indeksy
3   4    8  12  22  35    wartości
|   |---|
pom r0  r1
Przesunięcie ramki w prawo:
pom = r0
r0 = r1
r1 = 0.5 * r0 + 2 * pom
*/
double seq2_c(int n) {
    double r0 = 3.0;
    double r1 = 4.0;
    
    if (n == 1) return r0;
    if (n == 2) return r1;
    
    int i;
    for (i = 3; i <= n; i++) {
        double pom = r0;
        r0 = r1;
        r1 = 0.5 * r0 + 2.0 * pom;
    }
    
    return r1;
}

/*
Ramka trójzębna seq3:
r0  r1   r2
|---|----|
1   2    3   4   5   6    indeksy
3   4    8  12  22  35    wartości
    |---|---|
    r0  r1  r2
Przesunięcie ramki w prawo:
r0 = r1
r1 = r2
r2 = 0.5 * r1 + 2 * r0
*/
double seq3_c(int n) {
    double r0 = 3.0;
    double r1 = 4.0;
    double r2 = 8.0;
    
    if (n == 1) return r0;
    if (n == 2) return r1;
    if (n == 3) return r2;
    
    int i;
    for (i = 4; i <= n; i++) {
        r0 = r1;
        r1 = r2;
        r2 = 0.5 * r1 + 2.0 * r0;
    }
    
    return r2;
}

// Funkcja testująca wydajność
int test_performance(double (*fun_ptr)(int), int n, int limit) {
    clock_t start = clock();
    
    int i;
    for (i = 0; i < limit; i++) {
        fun_ptr(n);
    }
    
    clock_t end = clock();
    
    return end - start;
}

int main(int argc, char *argv[]) {
    printf("sequence2.c - Test funkcji seq2 i seq3\n\n");
    
        int n;
start:
    printf("n = ");
    if (scanf("%d", &n) != 1) {
        while (getchar() != '\n');
        goto start;
    }

    if (getchar() != '\n') {
        while (getchar() != '\n');
        goto start;
    }

    if (n <= 0) {
        goto start;
    }
    
    printf("\n=== Porównanie wyników ===\n");
    printf("seq2_asm(%d) = %.6f\n", n, seq2(n));
    printf("seq2_c(%d)   = %.6f\n", n, seq2_c(n));
    printf("seq3_asm(%d) = %.6f\n", n, seq3(n));
    printf("seq3_c(%d)   = %.6f\n", n, seq3_c(n));
    
    printf("\n=== Test wydajności ===\n");
    
    int limit = 1000 * 1000;
    printf("Liczba iteracji: %d\n\n", limit);
    
    printf("seq2_asm time = %d\n", test_performance(seq2, n, limit));
    printf("seq2_c   time = %d\n", test_performance(seq2_c, n, limit));
    printf("seq3_asm time = %d\n", test_performance(seq3, n, limit));
    printf("seq3_c   time = %d\n", test_performance(seq3_c, n, limit));
    
    printf("\n=== Weryfikacja pierwszych wartości ===\n");
    printf("n\tseq2_c\t\tseq3_c\n");
    printf("-----------------------------------\n");
    
    int i;
    for (i = 1; i <= 10 && i <= n + 5; i++) {
        printf("%d\t%.2f\t\t%.2f\n", i, seq2_c(i), seq3_c(i));
    }
    
    return 0;
}

/* WINDOWS
Instrukcje kompilacji:

nasm sequence-exe.asm -o sequence.o -f win32

gcc -c sequence2.c -o sequence2.o -m32

gcc sequence2.o sequence.o -o sequence2.exe -m32

*/

/* LINUX
Instrukcje kompilacji:

nasm -f elf32 sequence-linux.asm -o sequence.o

gcc -m32 -c sequence2.c -o sequence2.o

gcc sequence2.o sequence.o -o sequence2 -m32 -no-pie

*/

