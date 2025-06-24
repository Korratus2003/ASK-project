#include <stdio.h>
#include <stdlib.h>

/*
Ramka dwuzębna
r0  r1
|---|
1   2    3   4   5   6    indeksy
3   4    8  12  22  35    wartości
|   |---|
pom r0  r1

Przesunięcie ramki w prawo:
pom = r0
r0 = r1
r1 = 0.5 * r1 + 2 * r0
*/

double seq2(int n) {
    double r0 = 3;
    double r1 = 4;

    if (n == 1) return r0;
    if (n == 2) return r1;

    for (int i = 3; i <= n; i++) {
        double pom = r0;
        r0 = r1;
        r1 = 0.5 * r0 + 2 * pom;
    }

    return r1;
}

/*
Ramka trójzębna
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

double seq3(int n) {
    double r0 = 3;
    double r1 = 4;
    double r2 = 8;

    if (n == 1) return r0;
    if (n == 2) return r1;
    if (n == 3) return r2;
    
	int i;
    for ( i = 4; i <= n; i++ ) {
        r0 = r1;
        r1 = r2;
        r2 = 0.5 * r1 + 2 * r0;
    }
    
    return r2;
}

int main() {
    printf("sequence.c\n\n");
	
    
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

    // Ramka dwuzębna
    printf("seq2(%d) = %.2f\n", n, seq2(n));

    // Ramka trójzębna
    printf("seq3(%d) = %.2f\n", n, seq3(n));

    return 0;
}

