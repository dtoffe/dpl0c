program nested;

    const
        ADD = 1,
        SUB = 2,
        MULT = 3,
        DIV = 4;

    var
        op,
        x,
        y,
        done;

    procedure calculate();

        procedure add();

        begin
            x := x + y
        end;

        procedure sub();

        begin
            x := x - y
        end;

        procedure mult();

            var
                c;

        begin
            x := x * y
        end;

        procedure div();

        begin
            if y <> 0 then
                x := x / y;
            if y = 0 then
                done := 1
        end;

    begin
        if op = ADD then
            add();
        if op = SUB then
            sub();
        if op = MULT then
            mult();
        if op = DIV then
            div();
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
