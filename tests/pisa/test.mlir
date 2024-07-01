!t = tensor<128xi32>
func.func @foo(%x : !t, %y : !t ) -> !t {
    %0 = affine.for %i = 0 to 128 iter_args(%yy = %y) -> !t {
        %xi = tensor.extract %x[%i] : !t
        %yi = tensor.extract %y[%i] : !t
        %x2 = arith.addi %xi, %xi : i32
        %y2 = arith.addi %yi, %yi : i32
        %s  = arith.subi %x2, %y2 : i32
        %r  = tensor.insert %s into %yy[%i] : !t
        affine.yield %r : !t
    }
    func.return %0 : !t
}
