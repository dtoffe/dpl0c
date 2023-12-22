program nested;

    const opADD = 1;
    const opSUB = 2;
    const opMULT = 3;
    const opDIV = 4;

    var
        op,
        x,
        y,
        done : integer;

    procedure calculate();

        procedure doAdd();

        begin
            x := x + y
        end;

        procedure doSub();

        begin
            x := x - y
        end;

        procedure doMult();

            var
                c : integer;

        begin
            x := x * y
        end;

        procedure doDiv();

        begin
            if y <> 0 then
                x := x div y;
            if y = 0 then
                done := 1
        end;

    begin
        if op = opADD then
            doAdd();
        if op = opSUB then
            doSub();
        if op = opMULT then
            doMult();
        if op = opDIV then
            doDiv();
        if done = 0 then
            writeln(x)
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
                    calculate()
                end
        end
end.
