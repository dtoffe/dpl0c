#include <stdio.h>

const int max = 100;

int arg;
int ret;
int i;

void isprime(void)
{
    ret = 1;
    i = 2;
    while (i < arg)
    {
        if (arg / i * i == arg)
        {
            ret = 0;
            i = arg;
        }
        i = i + 1;
    }
}

void primes(void)
{
    arg = 2;
    while (arg < max)
    {
        isprime();
        if (ret == 1)
            printf("%d\n", arg);
        arg = arg + 1;
    }
}

int main(int argc, char *argv[])
{
    primes();
    return 0;
}

