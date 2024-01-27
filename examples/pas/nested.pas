program nested;

    const ADD = 1;
    const SUB = 2;
    const MULT = 3;
    const DIV_ = 4;

    var
        op,
        x,
        y,
        done : integer;

    procedure calculate();

        procedure add_();

        begin
            x := x + y
        end;

        procedure sub_();

        begin
            x := x - y
        end;

        procedure mult_();

            var
                c : integer;

        begin
            x := x * y
        end;

        procedure div__();

        begin
            if y <> 0 then
                x := x div y;
            if y = 0 then
                done := 1
        end;

    begin
        if op = ADD then
            add_();
        if op = SUB then
            sub_();
        if op = MULT then
            mult_();
        if op = DIV_ then
            div__();
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
