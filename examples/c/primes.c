#include <stdio.h>

void isprime(int *ret, int *arg);
void primes(int *arg, int max, int *ret);


void primes(int *arg, int max, int *ret)
{
    *arg = 2;
    while (*arg < max)
    {
        isprime(ret, arg);
        if (*ret == 1)
            printf("%d\n", *arg);
        *arg = *arg + 1;
    }
}

void isprime(int *ret, int *arg)
{
    int i;

    *ret = 1;
    i = 2;
    while (i < *arg)
    {
        if (*arg / i * i == *arg)
        {
            *ret = 0;
            i = *arg;
        }
        i = i + 1;
    }
}

int main(int argc, char *argv[])
{
    const int max = 100;

    int arg;
    int ret;

    primes(&arg, max, &ret);
    return 0;
}

