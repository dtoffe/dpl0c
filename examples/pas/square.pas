program square;

    var
        x,
        squ : integer;

    procedure square();

    begin
        squ := x * x
    end;

begin
    x := 1;
    while x <= 10 do
        begin
            square();
            writeln(squ);
            x := x + 1
        end
end.
