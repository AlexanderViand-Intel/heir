#ring = #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>
!poly = !polynomial.polynomial<ring = #ring>
!t = tensor<8192xi32, #ring>
func.func @foo(%x0: !poly, %x1: !poly, %y0: !poly, %y1 : !poly) -> (!poly, !poly, !poly) {
    %x0n = polynomial.ntt %x0 : !poly -> !t
    %x1n = polynomial.ntt %x1 : !poly -> !t
    %y0n = polynomial.ntt %y0 : !poly -> !t
    %y1n = polynomial.ntt %y1 : !poly -> !t
    %xx0 = arith_ext.mul %x0n, %x0n {modulus = 463187969 : i32} : !t
    %xt = arith_ext.mul %x0n, %x1n {modulus = 463187969 : i32} : !t
    %xx1 = arith_ext.add %xt, %xt {modulus = 463187969 : i32} : !t
    %xx2 = arith_ext.mul %x1n, %x1n {modulus = 463187969 : i32} : !t
    %yy0 = arith_ext.mul %y0n, %y0n {modulus = 463187969 : i32} : !t
    %yt = arith_ext.mul %y0n, %y1n {modulus = 463187969 : i32} : !t
    %yy1 = arith_ext.add %yt, %yt : {modulus = 463187969 : i32} : !t
    %yy2 = arith_ext.mul %y1n, %y1n {modulus = 463187969 : i32} : !t
    %s1 = arith.subi %yy0, %xx0 : !t
    %s2 = arith.subi %yy1, %xx1 : !t
    %s3 = arith.subi %yy2, %xx2 : !t
    %r0 = polynomial.intt %s1 : !t -> <ring = #ring>
    %r1 = polynomial.intt %s2 : !t -> <ring = #ring>
    %r2 = polynomial.intt %s3 : !t -> <ring = #ring>
    return %r0, %r1, %r2 : !poly, !poly ,!poly
}
