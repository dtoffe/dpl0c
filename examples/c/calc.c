#include <stdio.h>

const int ADD = 1;
const int SUB = 2;
const int MULT = 3;
const int DIV = 4;

int op;
int x;
int y;
int done;

void add_(void)
{
    x = x + y;
    printf("%d\n", x);
}

void sub_(void)
{
    x = x - y;
    printf("%d\n", x);
}

void mult_(void)
{
    x = x * y;
    printf("%d\n", x);
}

void div_(void)
{
    if (y != 0)
    {
        x = x / y;
        printf("%d\n", x);
    }
    if (y == 0)
        done = 1;
}

int main(int argc, char *argv[])
{
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
                add_();
            if (op == SUB)
                sub_();
            if (op == MULT)
                mult_();
            if (op == DIV)
                div_();
        }
    }
    return 0;
}

