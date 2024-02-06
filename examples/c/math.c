#include <stdio.h>


int x;
int y;
int z;
int q;
int r;
int n;
int f;
int a;
int b;
int w;
int f_;
int g;

void multiply(void)
{
    a = x;
    b = y;
    z = 0;
    while (b > 0)
    {
        if ((b) & 1)
            z = z + a;
        a = 2 * a;
        b = b / 2;
    }
}

void divide(void)
{
    r = x;
    q = 0;
    w = y;
    while (w <= r)
        w = 2 * w;
    while (w > y)
    {
        q = 2 * q;
        w = w / 2;
        if (w <= r)
        {
            r = r - w;
            q = q + 1;
        }
    }
}

void gcd(void)
{
    f_ = x;
    g = y;
    while (f_ != g)
    {
        if (f_ < g)
            g = g - f_;
        if (g < f_)
            f_ = f_ - g;
    }
    z = f_;
}

void fact(void)
{
    if (n > 1)
    {
        f = n * f;
        n = n - 1;
        fact();
    }
}

int main(int argc, char *argv[])
{
    scanf("%d", &x);
    scanf("%d", &y);
    multiply();
    printf("%d\n", z);
    scanf("%d", &x);
    scanf("%d", &y);
    divide();
    printf("%d\n", q);
    printf("%d\n", r);
    scanf("%d", &x);
    scanf("%d", &y);
    gcd();
    printf("%d\n", z);
    scanf("%d", &n);
    f = 1;
    fact();
    printf("%d\n", f);
    return 0;
}

