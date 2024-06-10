// RUN: heir-translate --emit-pisa %s | FileCheck %s

func.func @test_emit(%arg0 : tensor<8192xi32>, %arg1 : tensor<8192xi32>) ->  tensor<8192xi32> {
    %0 = pisa.padd %arg0, %arg1 {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    %1 = pisa.psub %arg0, %arg1 {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    %2 = pisa.pmul %arg0, %arg1 {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    %3 = pisa.pmuli %arg0 {q = 2147483647 : i32, i = 0 : i32, imm = 5 : i32} : tensor<8192xi32>
    %4 = pisa.pmac %arg0, %arg1, %arg0 {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    // %5 = pisa.pmaci %arg0, %arg1 {q = 2147483647 : i32, i = 0 : i32, imm = 5 : i32} : tensor<8192xi32>
    // %w = arith.constant dense<42> : tensor<8192xi32>
    // %6 = pisa.pntt %arg0, %w {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    // %7 = pisa.pintt %arg0, %w {q = 2147483647 : i32, i = 0 : i32} : tensor<8192xi32>
    return %0 : tensor<8192xi32>
}

func.func @foo(%x0 : tensor<8192xi32>, %x1 : tensor<8192xi32>, %x2 : tensor<8192xi32>, %y0 : tensor<8192xi32>, %y1 : tensor<8192xi32>, %y2 : tensor<8192xi32>, %w : tensor<8192xi32>) ->  tensor<8192xi32> {
    %x0ntt = pisa.pntt %x0, %w {q = 463187969 : i32, i = 0 : i32} : tensor<8192xi32>
    %x1ntt = pisa.pntt %x1, %w {q = 679389209 : i32, i = 1 : i32} : tensor<8192xi32>
    %x2ntt = pisa.pntt %x2, %w {q = 383838383 : i32, i = 2 : i32} : tensor<8192xi32>
    %y0ntt = pisa.pntt %y0, %w {q = 463187969 : i32, i = 0 : i32} : tensor<8192xi32>
    %y1ntt = pisa.pntt %y1, %w {q = 679389209 : i32, i = 1 : i32} : tensor<8192xi32>
    %y2ntt = pisa.pntt %y2, %w {q = 383838383 : i32, i = 2 : i32} : tensor<8192xi32>
    %0 = pisa.pmul %x0ntt, %x0ntt {q = 463187969 : i32, i = 0 : i32} : tensor<8192xi32>
    %1 = pisa.pmul %x1ntt, %x1ntt {q = 679389209 : i32, i = 1 : i32} : tensor<8192xi32>
    %2 = pisa.pmul %x1ntt, %x2ntt {q = 383838383 : i32, i = 2 : i32} : tensor<8192xi32>
    return %0 : tensor<8192xi32>
}
