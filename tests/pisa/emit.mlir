// RUN: heir-translate --emit-pisa %s | FileCheck %s

func.func @test_emit(%arg0 : tensor<8192xi32>, %arg1 : tensor<8192xi32>) ->  tensor<8192xi32> {
    %0 = pisa.padd %arg0, %arg1 {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    %1 = pisa.psub %arg0, %arg1 {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    %2 = pisa.pmul %arg0, %arg1 {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    %3 = pisa.pmuli %arg0 {q = 2147483647 : i32, i = 0 : i32, imm = 5 : i32} : tensor<8192xi32>
    %4 = pisa.pmac %arg0, %arg1, %arg0 {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    %5 = pisa.pmaci %arg0, %arg1 {q = 2147483647 : i32, i = 0 : i32, imm = 5 : i32} : tensor<8192xi32>
    %w = arith.constant dense<42> : tensor<8192xi32>
    %6 = pisa.pntt %arg0, %w {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    %7 = pisa.pintt %arg0, %w {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    return %0 : tensor<8192xi32>
}
