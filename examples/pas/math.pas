program math;

    var
        x,
        y,
        z,
        q,
        r,
        n,
        f : integer;

    procedure multiply();

        var
            a,
            b : integer;

    begin
        a := x;
        b := y;
        z := 0;
        while b > 0 do
            begin
                if (b) mod 2 = 1 then
                    z := z + a;
                a := 2 * a;
                b := b div 2
            end
    end;

    procedure divide();

        var
            w : integer;

    begin
        r := x;
        q := 0;
        w := y;
        while w <= r do
            w := 2 * w;
        while w > y do
            begin
                q := 2 * q;
                w := w div 2;
                if w <= r then
                    begin
                        r := r - w;
                        q := q + 1
                    end
            end
    end;

    procedure gcd();

        var
            f_,
            g : integer;

    begin
        f_ := x;
        g := y;
        while f_ <> g do
            begin
                if f_ < g then
                    g := g - f_;
                if g < f_ then
                    f_ := f_ - g
            end;
        z := f_
    end;

    procedure fact();

    begin
        if n > 1 then
            begin
                f := n * f;
                n := n - 1;
                fact()
            end
    end;

begin
    readln(x);
    readln(y);
    multiply();
    writeln(z);
    readln(x);
    readln(y);
    divide();
    writeln(q);
    writeln(r);
    readln(x);
    readln(y);
    gcd();
    writeln(z);
    readln(n);
    f := 1;
    fact();
    writeln(f)
end.
