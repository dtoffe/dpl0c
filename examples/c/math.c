#include <stdio.h>

void multiply(int *x, int *y, int *z);
void divide(int *r, int *x, int *q, int *y);
void gcd(int *x, int *y, int *z);
void fact(int *n, int *f);


void fact(int *n, int *f)
{
    if (*n > 1)
    {
        *f = *n * *f;
        *n = *n - 1;
        fact(n, f);
    }
}

void gcd(int *x, int *y, int *z)
{
    int f_;
    int g;

    f_ = *x;
    g = *y;
    while (f_ != g)
    {
        if (f_ < g)
            g = g - f_;
        if (g < f_)
            f_ = f_ - g;
    }
    *z = f_;
}

void divide(int *r, int *x, int *q, int *y)
{
    int w;

    *r = *x;
    *q = 0;
    w = *y;
    while (w <= *r)
        w = 2 * w;
    while (w > *y)
    {
        *q = 2 * *q;
        w = w / 2;
        if (w <= *r)
        {
            *r = *r - w;
            *q = *q + 1;
        }
    }
}

void multiply(int *x, int *y, int *z)
{
    int a;
    int b;

    a = *x;
    b = *y;
    *z = 0;
    while (b > 0)
    {
        if ((b) & 1)
            *z = *z + a;
        a = 2 * a;
        b = b / 2;
    }
}

int main(int argc, char *argv[])
{
    int x;
    int y;
    int z;
    int q;
    int r;
    int n;
    int f;

    scanf("%d", &x);
    scanf("%d", &y);
    multiply(&x, &y, &z);
    printf("%d\n", z);
    scanf("%d", &x);
    scanf("%d", &y);
    divide(&r, &x, &q, &y);
    printf("%d\n", q);
    printf("%d\n", r);
    scanf("%d", &x);
    scanf("%d", &y);
    gcd(&x, &y, &z);
    printf("%d\n", z);
    scanf("%d", &n);
    f = 1;
    fact(&n, &f);
    printf("%d\n", f);
    return 0;
}

