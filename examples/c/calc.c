#include <stdio.h>

void add_(int *x, int *y);
void sub_(int *x, int *y);
void mult_(int *x, int *y);
void div_(int *y, int *x, int *done);


void div_(int *y, int *x, int *done)
{
    if (*y != 0)
    {
        *x = *x / *y;
        printf("%d\n", *x);
    }
    if (*y == 0)
        *done = 1;
}

void mult_(int *x, int *y)
{
    *x = *x * *y;
    printf("%d\n", *x);
}

void sub_(int *x, int *y)
{
    *x = *x - *y;
    printf("%d\n", *x);
}

void add_(int *x, int *y)
{
    *x = *x + *y;
    printf("%d\n", *x);
}

int main(int argc, char *argv[])
{
    const int ADD = 1;
    const int SUB = 2;
    const int MULT = 3;
    const int DIV = 4;

    int op;
    int x;
    int y;
    int done;

    done = 0;
    scanf("%d", &x);
    while (done == 0)
    {
        scanf("%d", &op);
        if (op < 1)
            done = 1;
        if (op > 4)
            done = 1;
        if (done == 0)
        {
            scanf("%d", &y);
            if (op == ADD)
                add_(&x, &y);
            if (op == SUB)
                sub_(&x, &y);
            if (op == MULT)
                mult_(&x, &y);
            if (op == DIV)
                div_(&y, &x, &done);
        }
    }
    return 0;
}

