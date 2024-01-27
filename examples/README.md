# Examples

When I started this project I took the three examples form the [PL/0](https://en.wikipedia.org/wiki/PL/0) page on Wikipedia to test the lexer and the parser with them.

``` Pascal
// Square

var x, squ;

procedure square;
begin
   squ:= x * x
end;

begin
   x := 1;
   while x <= 10 do
   begin
      call square;
      write squ;
      x := x + 1
   end
end.
```

``` Pascal
// Primes

const max = 100;
var arg, ret;

procedure isprime;
var i;
begin
  ret := 1;
  i := 2;
  while i < arg do
  begin
    if arg / i * i = arg then
    begin
      ret := 0;
      i := arg
    end;
  i := i + 1
  end
end;

procedure primes;
begin
  arg := 2;
  while arg < max do
  begin
    call isprime;
    if ret = 1 then write arg;
    arg := arg + 1
  end
end;

call primes.
```

``` Pascal
// Math

var x, y, z, q, r, n, f;

procedure multiply;
var a, b;
begin
  a := x;
  b := y;
  z := 0;
  while b > 0 do
  begin
    if odd b then z := z + a;
    a := 2 * a;
    b := b / 2
  end
end;

procedure divide;
var w;
begin
  r := x;
  q := 0;
  w := y;
  while w <= r do w := 2 * w;
  while w > y do
  begin
    q := 2 * q;
    w := w / 2;
    if w <= r then
    begin
      r := r - w;
      q := q + 1
    end
  end
end;

procedure gcd;
var f, g;
begin
  f := x;
  g := y;
  while f # g do
  begin
    if f < g then g := g - f;
    if g < f then f := f - g
  end;
  z := f
end;

procedure fact;
begin
  if n > 1 then
  begin
    f := n * f;
    n := n - 1;
    call fact
  end
end;

begin
  read x; read y; call multiply; write z;
  read x; read y; call divide; write q; write r;
  read x; read y; call gcd; write z;
  read n; f := 1; call fact; write f
end.
```

Halfway through the project I found this [PL/0 User Manual](https://github.com/addiedx44/pl0-compiler/blob/master/doc/PL0%20User's%20Manual.pdf) by Adam Dunson, with another three good examples.

The [grammar](../docs/PL-0%20Grammar.txt) I used in this implementation is almost exactly the grammar provided in the Wikipedia page for PL/0, save for replacing "?" and "!" with "read" and "write".

I had to apply these modifications to the source code of the examples in Adam's User Manual to agree with the grammar of this implementation:

- No "else"" in "if" statements.
- Semicolon is a statement separator, not a finalizer.
- Replace "in" and "out" by "read" and "write".
- Use "#" instead of "<>" for not-equal.
- Use "var" to declare variables, instead of "int".

``` Pascal
// Calc

const ADD = 1, SUB = 2, MULT = 3, DIV = 4;

var op, x, y, done;

procedure add;
begin
    x := x + y;
    write x
end;

procedure sub;
begin
    x := x - y;
    write x
end;

procedure mult;
begin
    x := x * y;
    write x
end;

procedure div;
begin
    // Check for divide-by-zero errors
    if y # 0 then
    begin
        x := x / y;
        write x
    end;
    if y = 0 then
        done := 1
end;

begin
    done := 0;
    read x;
    while done = 0 do
    begin
        read op;
        if op < 1 then
            done := 1;
        if op > 4 then
            done := 1;
        if done = 0 then
        begin
            read y;
            if op = ADD then
                call add;
            if op = SUB then
                call sub;
            if op = MULT then
                call mult;
            if op = DIV then
                call div
            //else done := 1;
        end
    end
end.
```

``` Pascal
// Nested

const ADD = 1, SUB = 2, MULT = 3, DIV = 4;

var op, x, y, done;

procedure calculate;

    procedure add;
    begin
        x := x + y
    end;

    procedure sub;
    begin
        x := x - y
    end;

    procedure mult;
    var c;
    begin
        x := x * y
    end;

    procedure div;
    begin
        // check for divide-by-zero errors
        if y # 0 then
            x := x / y;
        if y = 0 then
            done := 1
    end;

begin
    if op = ADD then
        call add;
    if op = SUB then
        call sub;
    if op = MULT then
        call mult;
    if op = DIV then
        call div;
    if done = 0 then
        write x
end;

begin
    done := 0;
    read x;
    while done = 0 do
    begin
        read op;
        if op < 1 then
            done := 1;
        if op > 4 then
            done := 1;
        if done = 0 then
        begin
            read y;
            call calculate
        end
    end
end.
```

``` Pascal
// Recursive

var f, n;

procedure fact;
var ans1;
begin
    ans1 := n;
    n := n - 1;
    if n = 0 then
        f := 1;
    if n > 0 then
        call fact;
    f := f * ans1
end;

begin
    read n;
    if n < 0 then
        f := -1;
    if n = 0 then
        f := 1;
    if n > 0 then
        call fact;
    write f
end.
```

``` Pascal
// Calcmax

const MAX = 100;

var max, a, b;

procedure Max;
begin
    if a >= b then
        max := a;
    if b > a then
        max := b;
    if max < MAX then
        max := MAX
end;

begin
    read a;
    read b;
    call Max;
    write max
end.
```
