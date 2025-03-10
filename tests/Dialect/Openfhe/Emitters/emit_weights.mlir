// RUN: heir-translate %s --emit-openfhe-pke --weights-file=%t | FileCheck %s

// Tests emitting dense elements attributes to a weights file.

module attributes {scheme.ckks} {
  // CHECK-LABEL: test_external_weights
  // CHECK-SAME: size_t [[v0:.*]]) {
  // CHECK-NEXT: Weights weights = GetWeightModule("[[FILE:.*]]");
  // CHECK-NEXT: std::vector<int8_t> [[v1:.*]] =
  // CHECK-SAME:    weights.int8_ts["[[v1]]"];
  // CHECK-NEXT: std::vector<int8_t> [[v2:.*]](std::begin([[v1]]) + [[v0]] * 10, std::end([[v1]]) + [[v0]] * 10 + 64);
  // CHECK-NEXT: return [[v2]];
  func.func @test_external_weights(%arg1: index) -> tensor<64xi8> {
    %cst = arith.constant dense<"0xFAEE28C4EEFECF0F1EF71F060DEDE9835CC918E3F914282A09F2183462EAEFD636B71EF73B222839C29DF1075E0B1E2C07DDFDC3D84AF328A716D5F1C305FD27CCBA1ECBD73DD42900FD2844FBF2F3B64FCF09F0FA45414905C5175D6400F8EE4817F4E92E4B2E3FDFEEE40838F116132F2AEDC2BF36F402CFAAD2FAAC13F6E8B56812B6CE0EDF58E449141503EDFAD440A7F6CAFB004D5EE4551D3045E2FC014881E9F11EFC2132ED4BEDFA2FD2FAFB4DA7EDC792DFE6DBF81FD9FA91F5E5C58C170FB9D2C7FE68D3512E491FBD01EB3117F0EFFFB85D62020F1F786AB0F9FE4FCCD3FF0A961E2CEDBCF40B42C8F1EA6E58ECC499AEDCD71287D806A2C2E6A28124E9ACCEB6156BBA00195829B6FE012596D2EC0E9C605FE9F4F5696BB5E1F65EB7B1E5119B1810E3E1E00D4FA5DEE56FE2FB9982A5C9B61F46F304C6CAD697901DC095F0193077C23CFA24024D06071502B0E72722674DF1C2F4643840DFF63A43B8E10D1511FEF5ECF9E52236E4FD6DBF0D8EB715BF9F16AD0A028E14DA9B8EC3A6CAF57F5156C1B3D935F87F040A033FBEEE19687850F9A7F77F1D76DBE833B9D7E7E86915F7F5B2FEE8F35BE2066E0936B7CC38BF8A28142E18A726CBB29537ACCDD7516744CD31DE04E96A00130A0CDD16E0247E49F1B504520150DDF526C9F4F8D6311BD0EF030AC0D44FE2FD72F45AC9D731C08E175E5700B43AC8D29232CBD8C3A66326CFBCE8579BE9F71CEA12F1F7DBB97F16F6E00870A2EDCCF11E1004F7A9B734AA0ADB2AA6B610EAF85E0672DDD0B9D6A0109F5A17B1E7C0019D01E0E0AF9C46D8AFE8CE028ABBE4F6F33607CACB876ECCD69E0A2A81D7CFC004EB24CCC9953381F7AD1C9CA4D6F9E63D847FCCD4B0F4A2E93C36EED5CFCD2D"> : tensor<10x64xi8>
    %1 = tensor.extract_slice %cst[%arg1, 0] [1, 64] [1, 1] : tensor<10x64xi8> to tensor<64xi8>
    return %1 : tensor<64xi8>
  }
}
