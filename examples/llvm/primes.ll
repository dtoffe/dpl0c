; ModuleID = './examples/primes.pl0.ll'
source_filename = "./examples/primes.pl0.ll"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

declare i32 @readInteger()

declare void @writeInteger(i32)

define i32 @main(i32 %0) {
main:
  %max = alloca i32, align 4
  store i32 100, i32* %max, align 4
  %arg = alloca i32, align 4
  store i32 0, i32* %arg, align 4
  %ret = alloca i32, align 4
  store i32 0, i32* %ret, align 4
  %1 = call i32 @primes()
  ret i32 0
}

define i32 @isprime() {
isprime:
  %i = alloca i32, align 4
  store i32 0, i32* %i, align 4
  store i32 1, i32* %ret, align 4
  store i32 2, i32* %i, align 4
  br label %loop_condition

loop_condition:                                   ; preds = %if_exit, %isprime
  %i1 = load i32, i32* %i, align 4
  %arg = load i32, i32* %arg, align 4
  %tmp = icmp slt i32 %i1, %arg
  br i1 %tmp, label %loop_body, label %loop_exit

loop_body:                                        ; preds = %loop_condition
  br label %if_condition

if_condition:                                     ; preds = %loop_body
  %arg2 = load i32, i32* %arg, align 4
  %i3 = load i32, i32* %i, align 4
  %tmp4 = udiv i32 %arg2, %i3
  %i5 = load i32, i32* %i, align 4
  %tmp6 = mul i32 %tmp4, %i5
  %arg7 = load i32, i32* %arg, align 4
  %tmp8 = icmp eq i32 %tmp6, %arg7
  br i1 %tmp8, label %if_true, label %if_exit

if_true:                                          ; preds = %if_condition
  store i32 0, i32* %ret, align 4
  %arg9 = load i32, i32* %arg, align 4
  store i32 %arg9, i32* %i, align 4
  br label %if_exit

if_exit:                                          ; preds = %if_true, %if_condition
  %i10 = load i32, i32* %i, align 4
  %tmp11 = add i32 %i10, 1
  store i32 %tmp11, i32* %i, align 4
  br label %loop_condition

loop_exit:                                        ; preds = %loop_condition
  ret i32 0
}

define i32 @primes() {
primes:
  store i32 2, i32* %arg, align 4
  br label %loop_condition

loop_condition:                                   ; preds = %if_exit, %primes
  %arg = load i32, i32* %arg, align 4
  %max = load i32, i32* %max, align 4
  %tmp = icmp slt i32 %arg, %max
  br i1 %tmp, label %loop_body, label %loop_exit

loop_body:                                        ; preds = %loop_condition
  %0 = call i32 @isprime()
  br label %if_condition

if_condition:                                     ; preds = %loop_body
  %ret = load i32, i32* %ret, align 4
  %tmp1 = icmp eq i32 %ret, 1
  br i1 %tmp1, label %if_true, label %if_exit

if_true:                                          ; preds = %if_condition
  %arg2 = load i32, i32* %arg, align 4
  call void @writeInteger(i32 %arg2)
  br label %if_exit

if_exit:                                          ; preds = %if_true, %if_condition
  %arg3 = load i32, i32* %arg, align 4
  %tmp4 = add i32 %arg3, 1
  store i32 %tmp4, i32* %arg, align 4
  br label %loop_condition

loop_exit:                                        ; preds = %loop_condition
  ret i32 0
}
