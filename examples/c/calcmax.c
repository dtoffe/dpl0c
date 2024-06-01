#include <stdio.h>

void Max__(int *a, int *b, int *max_, int MAX);


void Max__(int *a, int *b, int *max_, int MAX)
{
    if (*a >= *b)
        *max_ = *a;
    if (*b > *a)
        *max_ = *b;
    if (*max_ < MAX)
        *max_ = MAX;
}

int main(int argc, char *argv[])
{
    const int MAX = 100;

    int max_;
    int a;
    int b;

    scanf("%d", &a);
    scanf("%d", &b);
    Max__(&a, &b, &max_, MAX);
    printf("%d\n", max_);
    return 0;
}

