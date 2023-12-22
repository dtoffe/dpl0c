program recursive;

    var
        f,
        n : integer;

    procedure fact();

        var
            ans1 : integer;

    begin
        ans1 := n;
        n := n - 1;
        if n = 0 then
            f := 1;
        if n > 0 then
            fact();
        f := f * ans1
    end;

begin
    readln(n);
    if n < 0 then
        f := -1;
    if n = 0 then
        f := 1;
    if n > 0 then
        fact();
    writeln(f)
end.
