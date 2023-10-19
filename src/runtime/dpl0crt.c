#include <stdio.h>
#include <stdlib.h>

int readInteger() {
    int num;
    printf("Enter an integer: ");
    scanf("%d", &num);
    return num;
}

void writeInteger(int num) {
    printf("Result: %d\n", num);
}
