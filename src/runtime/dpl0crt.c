#include <stdio.h>
#include <stdlib.h>

int read() {
    int num;
    scanf("%d", &num);
    return num;
}

void write(int num) {
    printf("%d\n", num);
}
