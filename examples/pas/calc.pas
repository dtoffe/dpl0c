program calc;

    const opADD = 1;
    const opSUB = 2;
    const opMULT = 3;
    const opDIV = 4;

    var
        op,
        x,
        y,
        done : integer;

    procedure doAdd();

    begin
        x := x + y;
        writeln(x)
    end;

    procedure doSub();

    begin
        x := x - y;
        writeln(x)
    end;

    procedure doMult();

    begin
        x := x * y;
        writeln(x)
    end;

    procedure doDiv();

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
                    if op = opADD then
                        doAdd();
                    if op = opSUB then
                        doSub();
                    if op = opMULT then
                        doMult();
                    if op = opDIV then
                        doDiv()
                end
        end
end.
