program primes;

    const max = 100;

    var
        arg,
        ret : integer;

    procedure isprime();

        var
            i : integer;

    begin
        ret := 1;
        i := 2;
        while i < arg do
            begin
                if arg div i * i = arg then
                    begin
                        ret := 0;
                        i := arg
                    end;
                i := i + 1
            end
    end;

    procedure primes();

    begin
        arg := 2;
        while arg < max do
            begin
                isprime();
                if ret = 1 then
                    writeln(arg);
                arg := arg + 1
            end
    end;

begin
    primes()
end
.
