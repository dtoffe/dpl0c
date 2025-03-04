; ModuleID = './examples/math.pl0.ll'
source_filename = "./examples/math.pl0.ll"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

declare i32 @readInteger()

declare void @writeInteger(i32)

define i32 @main(i32 %0) {
main:
  %x = alloca i32, align 4
  store i32 0, i32* %x, align 4
  %y = alloca i32, align 4
  store i32 0, i32* %y, align 4
  %z = alloca i32, align 4
  store i32 0, i32* %z, align 4
  %q = alloca i32, align 4
  store i32 0, i32* %q, align 4
  %r = alloca i32, align 4
  store i32 0, i32* %r, align 4
  %n = alloca i32, align 4
  store i32 0, i32* %n, align 4
  %f = alloca i32, align 4
  store i32 0, i32* %f, align 4
  %read = call i32 @readInteger()
  store i32* %x, i32 %read, align 8
  %read1 = call i32 @readInteger()
  store i32* %y, i32 %read1, align 8
  %1 = call i32 @multiply()
  %z2 = load i32, i32* %z, align 4
  call void @writeInteger(i32 %z2)
  %read3 = call i32 @readInteger()
  store i32* %x, i32 %read3, align 8
  %read4 = call i32 @readInteger()
  store i32* %y, i32 %read4, align 8
  %2 = call i32 @divide()
  %q5 = load i32, i32* %q, align 4
  call void @writeInteger(i32 %q5)
  %r6 = load i32, i32* %r, align 4
  call void @writeInteger(i32 %r6)
  %read7 = call i32 @readInteger()
  store i32* %x, i32 %read7, align 8
  %read8 = call i32 @readInteger()
  store i32* %y, i32 %read8, align 8
  %3 = call i32 @gcd()
  %z9 = load i32, i32* %z, align 4
  call void @writeInteger(i32 %z9)
  %read10 = call i32 @readInteger()
  store i32* %n, i32 %read10, align 8
  store i32 1, i32* %f, align 4
  %4 = call i32 @fact()
  %f11 = load i32, i32* %f, align 4
  call void @writeInteger(i32 %f11)
  ret i32 0
}

define i32 @multiply() {
multiply:
  %a = alloca i32, align 4
  store i32 0, i32* %a, align 4
  %b = alloca i32, align 4
  store i32 0, i32* %b, align 4
  %x = load i32, i32* %x, align 4
  store i32 %x, i32* %a, align 4
  %y = load i32, i32* %y, align 4
  store i32 %y, i32* %b, align 4
  store i32 0, i32* %z, align 4
  br label %loop_condition

loop_condition:                                   ; preds = %if_exit, %multiply
  %b1 = load i32, i32* %b, align 4
  %tmp = icmp sgt i32 %b1, 0
  br i1 %tmp, label %loop_body, label %loop_exit

loop_body:                                        ; preds = %loop_condition
  br label %if_condition

if_condition:                                     ; preds = %loop_body
  %b2 = load i32, i32* %b, align 4
  %lsb = and i32 %b2, 1
  br i32 %lsb, label %if_true, label %if_exit

if_true:                                          ; preds = %if_condition
  %z = load i32, i32* %z, align 4
  %a3 = load i32, i32* %a, align 4
  %tmp4 = add i32 %z, %a3
  store i32 %tmp4, i32* %z, align 4
  br label %if_exit

if_exit:                                          ; preds = %if_true, %if_condition
  %a5 = load i32, i32* %a, align 4
  %tmp6 = mul i32 2, %a5
  store i32 %tmp6, i32* %a, align 4
  %b7 = load i32, i32* %b, align 4
  %tmp8 = udiv i32 %b7, 2
  store i32 %tmp8, i32* %b, align 4
  br label %loop_condition

loop_exit:                                        ; preds = %loop_condition
  ret i32 0
}

define i32 @divide() {
divide:
  %w = alloca i32, align 4
  store i32 0, i32* %w, align 4
  %x = load i32, i32* %x, align 4
  store i32 %x, i32* %r, align 4
  store i32 0, i32* %q, align 4
  %y = load i32, i32* %y, align 4
  store i32 %y, i32* %w, align 4
  br label %loop_condition

loop_condition:                                   ; preds = %loop_body, %divide
  %w1 = load i32, i32* %w, align 4
  %r = load i32, i32* %r, align 4
  %tmp = icmp sle i32 %w1, %r
  br i1 %tmp, label %loop_body, label %loop_exit

loop_body:                                        ; preds = %loop_condition
  %w2 = load i32, i32* %w, align 4
  %tmp3 = mul i32 2, %w2
  store i32 %tmp3, i32* %w, align 4
  br label %loop_condition

loop_exit:                                        ; preds = %loop_condition
  br label %loop_condition4

loop_condition4:                                  ; preds = %if_exit, %loop_exit
  %w7 = load i32, i32* %w, align 4
  %y8 = load i32, i32* %y, align 4
  %tmp9 = icmp sgt i32 %w7, %y8
  br i1 %tmp9, label %loop_body5, label %loop_exit6

loop_body5:                                       ; preds = %loop_condition4
  %q = load i32, i32* %q, align 4
  %tmp10 = mul i32 2, %q
  store i32 %tmp10, i32* %q, align 4
  %w11 = load i32, i32* %w, align 4
  %tmp12 = udiv i32 %w11, 2
  store i32 %tmp12, i32* %w, align 4
  br label %if_condition

if_condition:                                     ; preds = %loop_body5
  %w13 = load i32, i32* %w, align 4
  %r14 = load i32, i32* %r, align 4
  %tmp15 = icmp sle i32 %w13, %r14
  br i1 %tmp15, label %if_true, label %if_exit

if_true:                                          ; preds = %if_condition
  %r16 = load i32, i32* %r, align 4
  %w17 = load i32, i32* %w, align 4
  %tmp18 = sub i32 %r16, %w17
  store i32 %tmp18, i32* %r, align 4
  %q19 = load i32, i32* %q, align 4
  %tmp20 = add i32 %q19, 1
  store i32 %tmp20, i32* %q, align 4
  br label %if_exit

if_exit:                                          ; preds = %if_true, %if_condition
  br label %loop_condition4

loop_exit6:                                       ; preds = %loop_condition4
  ret i32 0
}

define i32 @gcd() {
gcd:
  %f = alloca i32, align 4
  store i32 0, i32* %f, align 4
  %g = alloca i32, align 4
  store i32 0, i32* %g, align 4
  %x = load i32, i32* %x, align 4
  store i32 %x, i32* %f, align 4
  %y = load i32, i32* %y, align 4
  store i32 %y, i32* %g, align 4
  br label %loop_condition

loop_condition:                                   ; preds = %if_exit11, %gcd
  %f1 = load i32, i32* %f, align 4
  %g2 = load i32, i32* %g, align 4
  %tmp = icmp ne i32 %f1, %g2
  br i1 %tmp, label %loop_body, label %loop_exit

loop_body:                                        ; preds = %loop_condition
  br label %if_condition

if_condition:                                     ; preds = %loop_body
  %f3 = load i32, i32* %f, align 4
  %g4 = load i32, i32* %g, align 4
  %tmp5 = icmp slt i32 %f3, %g4
  br i1 %tmp5, label %if_true, label %if_exit

if_true:                                          ; preds = %if_condition
  %g6 = load i32, i32* %g, align 4
  %f7 = load i32, i32* %f, align 4
  %tmp8 = sub i32 %g6, %f7
  store i32 %tmp8, i32* %g, align 4
  br label %if_exit

if_exit:                                          ; preds = %if_true, %if_condition
  br label %if_condition9

if_condition9:                                    ; preds = %if_exit
  %g12 = load i32, i32* %g, align 4
  %f13 = load i32, i32* %f, align 4
  %tmp14 = icmp slt i32 %g12, %f13
  br i1 %tmp14, label %if_true10, label %if_exit11

if_true10:                                        ; preds = %if_condition9
  %f15 = load i32, i32* %f, align 4
  %g16 = load i32, i32* %g, align 4
  %tmp17 = sub i32 %f15, %g16
  store i32 %tmp17, i32* %f, align 4
  br label %if_exit11

if_exit11:                                        ; preds = %if_true10, %if_condition9
  br label %loop_condition

loop_exit:                                        ; preds = %loop_condition
  %f18 = load i32, i32* %f, align 4
  store i32 %f18, i32* %z, align 4
  ret i32 0
}

define i32 @fact() {
fact:
  br label %if_condition

if_condition:                                     ; preds = %fact
  %n = load i32, i32* %n, align 4
  %tmp = icmp sgt i32 %n, 1
  br i1 %tmp, label %if_true, label %if_exit

if_true:                                          ; preds = %if_condition
  %n1 = load i32, i32* %n, align 4
  %f = load i32, i32* %f, align 4
  %tmp2 = mul i32 %n1, %f
  store i32 %tmp2, i32* %f, align 4
  %n3 = load i32, i32* %n, align 4
  %tmp4 = sub i32 %n3, 1
  store i32 %tmp4, i32* %n, align 4
  %0 = call i32 @fact()
  br label %if_exit

if_exit:                                          ; preds = %if_true, %if_condition
  ret i32 0
}
