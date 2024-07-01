!t = i32
func.func @foo(%x : !t {secret.secret}, %y : !t ) -> !t {
    %x2 = arith.addi %x, %x : i32
    %y2 = arith.addi %y, %y : i32
    %s  = arith.subi %x2, %y2 : i32
    func.return %s : !t
}
