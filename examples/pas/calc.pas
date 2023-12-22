program calc;

    const
        ADD = 1;
        SUB = 2;
        MULT = 3;
        DIVI = 4;

    var
        op,
        x,
        y,
        done : integer;

    procedure add();

    begin
        x := x + y;
        writeln(x)
    end;

    procedure sub();

    begin
        x := x - y;
        writeln(x)
    end;

    procedure mult();

    begin
        x := x * y;
        writeln(x)
    end;

    procedure divi();

    begin
        if y <> 0 then
            begin
                x := x div y;
                writeln(x)
            end;
        if y = 0 then
            done := 1
    end;

begin
    done := 0;
    readln(x);
    while done = 0 do
        begin
            readln(op);
            if op < 1 then
                done := 1;
            if op > 4 then
                done := 1;
            if done = 0 then
                begin
                    readln(y);
                    if op = ADD then
                        add();
                    if op = SUB then
                        sub();
                    if op = MULT then
                        mult();
                    if op = DIVI then
                        divi()
                end
        end
end.
