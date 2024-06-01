#include <stdio.h>

void square(int *squ, int *x);


void square(int *squ, int *x)
{
    *squ = *x * *x;
}

int main(int argc, char *argv[])
{
    int x;
    int squ;

    x = 1;
    while (x <= 10)
    {
        square(&squ, &x);
        printf("%d\n", squ);
        x = x + 1;
    }
    return 0;
}

