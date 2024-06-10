!t = tensor<8192xi32>
func.func @foo(%x0: !t, %x1: !t, %y0: !t, %y1 : !t, %w : !t) -> (!t, !t, !t) {
    %x0n = pisa.pintt %x0, %w {q = 463187969 : i32, i = 0 : i32} : !t
    %x1n = pisa.pintt %x1, %w {q = 463187969 : i32, i = 0 : i32} : !t
    %y0n = pisa.pintt %y0, %w {q = 463187969 : i32, i = 0 : i32} : !t
    %y1n = pisa.pintt %y1, %w {q = 463187969 : i32, i = 0 : i32} : !t
    %xx0 = pisa.pmul  %x0n, %x0n {q = 463187969 : i32, i = 0 : i32} : !t
    %xt = pisa.pmul %x0n, %x1n {q = 463187969 : i32, i = 0 : i32} : !t
    %xx1 = pisa.padd %xt, %xt {q = 463187969 : i32, i = 0 : i32} : !t
    %xx2 = pisa.pmul %x1n, %x1n {q = 463187969 : i32, i = 0 : i32} : !t
    %yy0 = pisa.pmul %y0n, %y0n {q = 463187969 : i32, i = 0 : i32} : !t
    %yt = pisa.pmul %y0n, %y1n {q = 463187969 : i32, i = 0 : i32} : !t
    %yy1 = pisa.padd %yt, %yt {q = 463187969 : i32, i = 0 : i32} : !t
    %yy2 = pisa.pmul %y1n, %y1n {q = 463187969 : i32, i = 0 : i32} : !t
    %s0 = pisa.psub %yy0, %xx0 {q = 463187969 : i32, i = 0 : i32} : !t
    %s1 = pisa.psub %yy1, %xx1 {q = 463187969 : i32, i = 0 : i32} : !t
    %s2 = pisa.psub %yy2, %xx2 {q = 463187969 : i32, i = 0 : i32} : !t
    %r0 = pisa.pintt %s0, %w {q = 463187969 : i32, i = 0 : i32} : !t
    %r1 = pisa.pintt %s1, %w {q = 463187969 : i32, i = 0 : i32} : !t
    %r2 = pisa.pintt %s2, %w {q = 463187969 : i32, i = 0 : i32} : !t
    return %r0, %r1, %r2 : !t, !t, !t
}
