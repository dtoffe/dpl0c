#include <stdio.h>


int x;
int squ;

void square(void)
{
    squ = x * x;
}

int main(int argc, char *argv[])
{
    x = 1;
    while (x <= 10)
    {
        square();
        printf("%d\n", squ);
        x = x + 1;
    }
    return 0;
}

