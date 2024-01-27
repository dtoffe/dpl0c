program calcmax;

    const MAX = 100;

    var
        max_,
        a,
        b : integer;

    procedure Max__();

    begin
        if a >= b then
            max_ := a;
        if b > a then
            max_ := b;
        if max_ < MAX then
            max_ := MAX
    end;

begin
    readln(a);
    readln(b);
    Max__();
    writeln(max_)
end.
