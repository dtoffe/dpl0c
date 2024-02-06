#include <stdio.h>

const int MAX = 100;

int max_;
int a;
int b;

void Max__(void)
{
    if (a >= b)
        max_ = a;
    if (b > a)
        max_ = b;
    if (max_ < MAX)
        max_ = MAX;
}

int main(int argc, char *argv[])
{
    scanf("%d", &a);
    scanf("%d", &b);
    Max__();
    printf("%d\n", max_);
    return 0;
}

