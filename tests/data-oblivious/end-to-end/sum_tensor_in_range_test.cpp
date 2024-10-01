#include <cstdint>
#include <vector>

#include "gtest/gtest.h"                               // from @googletest
#include "src/core/include/lattice/hal/lat-backend.h"  // from @openfhe
#include "src/pke/include/constants.h"                 // from @openfhe
#include "src/pke/include/cryptocontext-fwd.h"         // from @openfhe
#include "src/pke/include/gen-cryptocontext.h"         // from @openfhe
#include "src/pke/include/key/keypair.h"               // from @openfhe
#include "src/pke/include/openfhe.h"                   // from @openfhe
#include "src/pke/include/scheme/bgvrns/gen-cryptocontext-bgvrns-params.h"  // from @openfhe
#include "src/pke/include/scheme/bgvrns/gen-cryptocontext-bgvrns.h"  // from @openfhe

// Generated headers (block clang-format from messing up order)
#include "tests/data-oblivious/end_to_end/sum_tensor_in_range_lib.h"

namespace mlir {
namespace heir {
namespace openfhe {

TEST(SumTensorInRangeTest, RunTest) {
  // TODO(#661): Generate a helper function to set up CryptoContext based on
  // what is used in the generated code.
  auto cryptoContext = sum_tensor_in_range__generate_crypto_context();
  auto keyPair = cryptoContext->KeyGen();
  auto publicKey = keyPair.publicKey;
  auto secretKey = keyPair.secretKey;
  cryptoContext =
      sum_tensor_in_range__configure_crypto_context(cryptoContext, secretKey);

  int32_t n = cryptoContext->GetCryptoParameters()
                  ->GetElementParams()
                  ->GetCyclotomicOrder() /
              2;
  int32_t arg0Vals[16] = {1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8};
//   int16_t arg1Vals[8] = {2, 3, 4, 5, 6, 7, 8, 9};
  int64_t expected = 72;

  // TODO(#645): support cyclic repetition in add-client-interface
  std::vector<int32_t> arg0;
  arg0.reserve(n);
//   std::vector<int16_t> arg1;
//   arg1.reserve(n);

  for (int i = 0; i < n; ++i) {
    arg0.push_back(arg0Vals[i % 16]);
    // arg1.push_back(arg1Vals[i % 8]);
  }

  auto arg0Encrypted =
      sum_tensor_in_range__encrypt__arg0(cryptoContext, arg0, publicKey);
//   auto arg1Encrypted =
//       dot_product__encrypt__arg1(cryptoContext, arg1, publicKey);
  auto outputEncrypted =
      sum_tensor_in_range(cryptoContext, arg0Encrypted);
//   auto actual =
//       dot_product__decrypt__result0(cryptoContext, outputEncrypted, secretKey);

  EXPECT_EQ(expected, actual);
}

}  // namespace openfhe
}  // namespace heir
}  // namespace mlir
