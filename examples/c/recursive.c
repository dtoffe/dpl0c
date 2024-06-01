#include <stdio.h>

void fact(int *n, int *f);


void fact(int *n, int *f)
{
    int ans1;

    ans1 = *n;
    *n = *n - 1;
    if (*n == 0)
        *f = 1;
    if (*n > 0)
        fact(n, f);
    *f = *f * ans1;
}

int main(int argc, char *argv[])
{
    int f;
    int n;

    scanf("%d", &n);
    if (n < 0)
        f = -1;
    if (n == 0)
        f = 1;
    if (n > 0)
        fact(&n, &f);
    printf("%d\n", f);
    return 0;
}

