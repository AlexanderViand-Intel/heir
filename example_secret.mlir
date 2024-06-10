!t = tensor<8192xi64>
func.func @foo_vec_sec(%arg0: !secret.secret<!t>, %arg1: !secret.secret<!t>) -> !secret.secret<!t> {
%0 = secret.generic ins(%arg0, %arg1 : !secret.secret<!t>, !secret.secret<!t>) {
^bb0(%arg2: !t, %arg3: !t):
    %1 = arith.muli %arg3, %arg3 : !t
    %2 = arith.muli %arg2, %arg2 : !t
    %3 = arith.subi %2, %1 : !t
    secret.yield %3 : !t
} -> !secret.secret<!t>
return %0 : !secret.secret<!t>
}
