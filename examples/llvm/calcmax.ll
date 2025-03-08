; ModuleID = './examples/calcmax.pl0.ll'
source_filename = "./examples/calcmax.pl0.ll"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

declare i32 @read()

declare void @write(i32)

define i32 @main(i32 %0) {
main:
  %MAX = alloca i32
  store i32 100, i32* %MAX
  %max = alloca i32
  store i32 0, i32* %max
  %a = alloca i32
  store i32 0, i32* %a
  %b = alloca i32
  store i32 0, i32* %b
  %read = call i32 @read()
  store i32* %a, i32 %read
  %read1 = call i32 @read()
  store i32* %b, i32 %read1
  %1 = call i32 @Max()
  %max2 = load i32, i32* %max
  call void @write(i32 %max2)
  ret i32 0
}

define i32 @Max() {
Max:
  br label %if_condition

if_condition:                                     ; preds = %Max
  %a = load i32, i32* %a
  %b = load i32, i32* %b
  %tmp = icmp sge i32 %a, %b
  br i1 %tmp, label %if_true, label %if_exit

if_true:                                          ; preds = %if_condition
  %a1 = load i32, i32* %a
  store i32 %a1, i32* %max
  br label %if_exit

if_exit:                                          ; preds = %if_true, %if_condition
  br label %if_condition2

if_condition2:                                    ; preds = %if_exit
  %b5 = load i32, i32* %b
  %a6 = load i32, i32* %a
  %tmp7 = icmp sgt i32 %b5, %a6
  br i1 %tmp7, label %if_true3, label %if_exit4

if_true3:                                         ; preds = %if_condition2
  %b8 = load i32, i32* %b
  store i32 %b8, i32* %max
  br label %if_exit4

if_exit4:                                         ; preds = %if_true3, %if_condition2
  br label %if_condition9

if_condition9:                                    ; preds = %if_exit4
  %max = load i32, i32* %max
  %MAX = load i32, i32* %MAX
  %tmp12 = icmp slt i32 %max, %MAX
  br i1 %tmp12, label %if_true10, label %if_exit11

if_true10:                                        ; preds = %if_condition9
  %MAX13 = load i32, i32* %MAX
  store i32 %MAX13, i32* %max
  br label %if_exit11

if_exit11:                                        ; preds = %if_true10, %if_condition9
  ret i32 0
}
