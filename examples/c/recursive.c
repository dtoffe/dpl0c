#include <stdio.h>


int f;
int n;
int ans1;

void fact(void)
{
    ans1 = n;
    n = n - 1;
    if (n == 0)
        f = 1;
    if (n > 0)
        fact();
    f = f * ans1;
}

int main(int argc, char *argv[])
{
    scanf("%d", &n);
    if (n < 0)
        f = -1;
    if (n == 0)
        f = 1;
    if (n > 0)
        fact();
    printf("%d\n", f);
    return 0;
}

