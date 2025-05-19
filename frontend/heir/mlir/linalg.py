from numba.extending import type_callable
from numba.core.types import Array
from numba.core.errors import TypingError


def mlir_op(op_name):
  """
  Decorator to register a function as an MLIR operation.
  """

  def decorator(func):
    func.mlir_op_name = op_name
    return func

  return decorator


@mlir_op("linalg.matmul")
def matmul(a, b):
  """
  Perform matrix multiplication of two matrices a and b.
  """
  return a @ b


@type_callable(matmul)
def build_typer_function(context):
  def typer_function(a, b):
    if not (isinstance(a, Array) and isinstance(b, Array)):
      raise TypingError("matmul: Both arguments must be array types.")

    # Trying to follow numpy's matmul behavior:
    if a.ndim == 1 and b.ndim == 1:
      # 1-D dot product returns the scalar type (should hopefully be the same)
      return a.dtype  # FIXME: call numba type inference on a.dtype * b.dtype?
    elif a.ndim == 1:
      # a is treated as a row vector (1, N) so the result has ndim = b.ndim - 1
      return Array(a.dtype, b.ndim - 1, b.layout)
    elif b.ndim == 1:
      # b is treated as a column vector (N, 1) so the result has ndim = a.ndim - 1
      return Array(a.dtype, a.ndim - 1, a.layout)
    else:
      # Both a and b are at least 2-D.
      # a: shape = (..., M, K)
      # b: shape = (..., K, N)
      # Output shape: broadcast(a.shape[:-2], b.shape[:-2]) + (M, N)
      # Since only dimensions matter, pick out_ndim = max(a.ndim, b.ndim)
      out_ndim = max(a.ndim, b.ndim)
      return Array(a.dtype, out_ndim, a.layout)

  return typer_function
