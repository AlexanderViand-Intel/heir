"""Emitter from numba IR (SSA) to MLIR."""

from collections import deque
from dataclasses import dataclass
import operator
import textwrap
from typing import Any

from numba.core import ir
from numba.core import types
from numba.core import bytecode
from numba.core import controlflow
from numba.core.types import Type as NumbaType


def mlirType(numba_type: NumbaType) -> str:
  if isinstance(numba_type, types.Integer):
    # TODO (#1162): fix handling of signedness
    # Since `arith` only allows signless integers, we ignore signedness here.
    return "i" + str(numba_type.bitwidth)
  if isinstance(numba_type, types.RangeType):
    return mlirType(numba_type.dtype)
  if isinstance(numba_type, types.Boolean):
    return "i1"
  if isinstance(numba_type, types.Float):
    return "f" + str(numba_type.bitwidth)
  if isinstance(numba_type, types.Complex):
    return "complex<" + str(numba_type.bitwidth) + ">"
  if isinstance(numba_type, types.Array):
    shape = None
    if hasattr(numba_type, "shape"):
      shape = "x".join(str(s) for s in numba_type.shape)  # type: ignore
      return f"tensor<{shape}x{mlirType(numba_type.dtype)}>"
    return "tensor<" + "?x" * numba_type.ndim + mlirType(numba_type.dtype) + ">"
  raise NotImplementedError("Unsupported type: " + str(numba_type))


def mlirLoc(loc: ir.Loc) -> str:
  return (
      f"loc(\"{loc.filename or '<unknown>'}\":{loc.line or 0}:{loc.col or 0})"
  )


def arithSuffix(numba_type: NumbaType) -> str:
  if isinstance(numba_type, types.Integer):
    return "i"
  if isinstance(numba_type, types.Boolean):
    return "i"
  if isinstance(numba_type, types.Float):
    return "f"
  if isinstance(numba_type, types.Complex):
    raise NotImplementedError(
        "Complex numbers not supported in `arith` dialect"
    )
  if isinstance(numba_type, types.Array):
    return arithSuffix(numba_type.dtype)
  raise NotImplementedError("Unsupported type: " + str(numba_type))


class HeaderInfo:
  """
  Header info provides info from a loop's header block

  Attributes:
    phi_var: An ir.Var representing the loop iterator
    body_id: The block id of the loop body
    next_id: The block id of the block after the loop
  """

  def __init__(self, header_block):
    body = header_block.body
    assert len(body) == 5
    self.phi_var = body[3].target
    self.body_id = body[4].truebr
    self.next_id = body[4].falsebr


class RangeArgs:
  """
  Range args provides a ranges start, stop, step args.

  Attributes:
    start: An ir.Var or int providing the lower bound
    stop: An ir.Var or int providing the upper bound
    step: An ir.Var or int providing the step
  """

  def __init__(self, range_call):
    args = range_call.value.args
    self.start = 0
    self.step = 1
    match len(args):
      case 1:
        self.stop = args[0]
      case 2:
        self.start, self.stop = args
      case 3:
        self.start, self.stop, self.step = args


@dataclass
class Loop:
  """
  A dataclass containing Loop info.

  Attributes:
    header_id: The block id of the loop's header
    header: A HeaderInfo object with the iterator and loop block ids
    rage: A RangeArg object with the loop's range info
    inits: A list of ir.Vars that initialize any loop-carried vars
  """

  header_id: int
  header: HeaderInfo
  range: RangeArgs
  inits: list[ir.Var]


def build_loop_from_call(index, block_id, blocks, cfa):
  body = blocks[block_id].body
  # Build a loop from a range call starting at index
  header_id = body[index + 3].target
  header = HeaderInfo(blocks[header_id])
  range_args = RangeArgs(body[index])

  # Loop body must start with assigning the local iter var
  loop_body = blocks[header.body_id]
  assert loop_body.body[0].value == header.phi_var
  iter_var = loop_body.body[0].target

  inits = set()
  loop_body_blocks = cfa.graph._loops[header_id].body
  loop_header_blocks = set([l.header for l in cfa.graph._loops.values()])
  loop_body_blocks = loop_body_blocks - loop_header_blocks

  for id in loop_body_blocks:
    block = blocks[id]
    for instr in blocks[id].body:
      match type(instr):
        case ir.Assign:
          if type(instr.value) == ir.Global:
            continue
          if instr.target == iter_var:
            continue
          # not temp and defined outside before the loop block
          if not instr.target.is_temp:
            if instr.target.loc.line < block.loc.line:
              inits.add(instr.target)

  return Loop(
      header_id,
      header,
      range_args,
      list(inits),
  )


def is_start_of_loop(index, body, ssa_ir):
  instr = body[index]
  # True if instr is a range call that begins a loop
  match instr:
    case ir.Assign(value=ir.Expr(op="call")):
      func = instr.value.func
    case _:
      return False

  assert func.name in ssa_ir._definitions
  func_def_list = ssa_ir._definitions[func.name]
  assert len(func_def_list) == 1
  func_def = func_def_list[0]

  match func_def:
    case ir.Global(name="range"):
      # The next instrs should be getiter, iternext, and jump
      next_instrs = map(type, body[index + 1 : index + 4])
      if list(next_instrs) != [ir.Assign, ir.Assign, ir.Jump]:
        return False
    case _:
      return False

  return True


class TextualMlirEmitter:

  def __init__(self, ssa_ir, secret_args: list[int], typemap, return_types):
    """Initialize the emitter with the given SSA IR and type information.

    ssa_ir: output of numba's compiler.run_frontend or similar
    secret_args: list of indices of secret arguments
    typemap: typemap produced by numba's type_inference_stage(...)
    return_types: return types produced by numba's type_inference_stage(...)
    """
    self.ssa_ir = ssa_ir
    self.secret_args = secret_args
    self.typemap = typemap
    self.return_types = (return_types,)
    self.temp_var_id = 0
    self.numba_names_to_ssa_var_names = {}
    self.globals_map = {}
    self.loops = {}

  def get_control_flow(self):
    bc = bytecode.ByteCode(self.ssa_ir.func_id)
    cfa = controlflow.ControlFlowAnalysis(bc)
    cfa.run()
    return cfa

  def emit(self):
    func_name = self.ssa_ir.func_id.func_name
    # probably should use unique name...
    # func_name = ssa_ir.func_id.unique_name
    args: list[str] = []
    for idx, name in enumerate(self.ssa_ir.arg_names):
      numba_type = self.typemap.get(name)
      arg = f"%{name}: {mlirType(numba_type)} "
      attrs: list[str] = []
      if idx in self.secret_args:
        attrs.append("secret.secret")
      if hasattr(numba_type, "shape"):
        attrs.append(f"shape.shape=[{','.join(map(str, numba_type.shape))}]")
      if attrs:
        arg += "{" + ", ".join(attrs) + "} "
      arg += mlirLoc(self.ssa_ir.loc)
      args.append(arg)

    args_str = ", ".join(args)

    # TODO(#1162): support multiple return values!
    if len(self.return_types) > 1:
      raise NotImplementedError("Multiple return values not supported")
    return_types_str = mlirType(self.return_types[0])

    body = self.emit_blocks()

    mlir_func = f"""func.func @{func_name}({args_str}) -> ({return_types_str}) {{
{textwrap.indent(body, '  ')}
}} {mlirLoc(self.ssa_ir.loc)}
"""
    return mlir_func

  def emit_blocks(self):
    blocks = self.ssa_ir.blocks
    cfa = self.get_control_flow()

    # collect loops and block header needs
    block_ids_to_omit_header = set()
    loop_entries = [list(l.entries)[0] for l in cfa.graph._loops.values()]
    for entry_id in loop_entries:
      block = blocks[entry_id]
      for i in range(len(block.body)):
        # Detect a range call
        instr = block.body[i]
        if is_start_of_loop(i, block.body, self.ssa_ir):
          loop = build_loop_from_call(i, entry_id, blocks, cfa)
          self.loops[instr.target] = loop
          block_ids_to_omit_header.add(loop.header.next_id)

    sorted_blocks = list(cfa.iterblocks())
    # first block doesn't require a block header
    block_ids_to_omit_header.add(sorted_blocks[0].offset)
    blocks_to_print = deque(
        [(b.offset, blocks[b.offset]) for b in sorted_blocks]
    )

    # print blocks
    str_blocks = []
    while blocks_to_print:
      block_id, block = blocks_to_print.popleft()
      if block_id in block_ids_to_omit_header:
        block_header = ""
      else:
        block_header = f"^bb{block_id}:\n"
      str_blocks.append(
          block_header
          + textwrap.indent(self.emit_block(block, blocks_to_print), "  ")
      )

    return "\n".join(str_blocks)

  def emit_block(self, block, blocks_to_print):
    instructions = []
    for i in range(len(block.body)):
      instr = block.body[i]
      if type(instr) == ir.Assign and instr.target in self.loops:
        # We hit a range call for a loop
        result = self.emit_loop(instr.target, blocks_to_print)
        instructions.append(result)
        # Exit instructions, should be the end of the block
        break
      else:
        result = self.emit_instruction(instr, blocks_to_print)
      if result:
        instructions.append(result)
    return "\n".join(instructions)

  def emit_instruction(self, instr, blocks_to_print):
    match instr:
      case ir.Assign():
        return self.emit_assign(instr)
      case ir.Branch():
        return self.emit_branch(instr, blocks_to_print)
      case ir.Return():
        return self.emit_return(instr)
      case ir.Jump():
        # TODO ignore
        assert instr.is_terminator
        return
    raise NotImplementedError("Unsupported instruction: " + str(instr))

  def get_or_create_name(self, var):
    name = var.name
    if name in self.numba_names_to_ssa_var_names:
      ssa_id = self.numba_names_to_ssa_var_names[name]
    else:
      ssa_id = self.temp_var_id
      self.numba_names_to_ssa_var_names[name] = ssa_id
      self.temp_var_id += 1
    return f"%{ssa_id}"

  def forward_to_new_id(self, from_var):
    # Creates a new SSA var name and forwards the old var.
    # Useful to create new intermediate vars or temp vars.
    to_name = self.temp_var_id
    self.temp_var_id += 1
    self.numba_names_to_ssa_var_names[from_var.name] = to_name
    return f"%{to_name}"

  def get_next_name(self):
    ssa_id = self.temp_var_id
    self.temp_var_id += 1
    return f"%{ssa_id}"

  def get_name(self, var):
    assert var.name in self.numba_names_to_ssa_var_names
    return self.get_or_create_name(var)

  def forward_name(self, from_var, to_var):
    to_name = self.numba_names_to_ssa_var_names[to_var.name]
    self.numba_names_to_ssa_var_names[from_var.name] = to_name

  def forward_name_to_id(self, from_var, to_str):
    self.numba_names_to_ssa_var_names[from_var.name] = to_str

  def emit_assign(self, assign: ir.Assign):
    match assign.value:
      case ir.Arg():
        if assign.target.name != assign.value.name:
          raise ValueError(
              "MLIR has no vanilla assignment op? "
              "Do I need to keep a mapping from func arg names to SSA names?"
          )
        self.numba_names_to_ssa_var_names[assign.target.name] = (
            assign.value.name
        )
        return ""
      case ir.Expr(op="binop"):
        emitted_expr, ext = self.emit_binop(assign.value)
        name = self.get_or_create_name(assign.target)
        return (
            f"{ext}"
            f"{name} = {emitted_expr} :"
            f" {mlirType(self.typemap.get(assign.value.lhs.name))} {mlirLoc(assign.loc)}"
        )
      case ir.Expr(op="call"):
        func = assign.value.func
        # if assert fails, variable was undefined
        assert func.name in self.globals_map
        if self.globals_map[func.name] == "bool":
          # nothing to do, forward the name to the arg of bool()
          self.forward_name(from_var=assign.target, to_var=assign.value.args[0])
          return ""
        # FIXME: hook into some kind of registry of mlir_op's that have been registered instead of matching on names here
        if self.globals_map[func.name] == "linalg.matmul":
          out_name = self.get_next_name()
          lhs = assign.value.args[0]
          rhs = assign.value.args[1]
          lhs_type = mlirType(self.typemap.get(str(lhs)))
          rhs_type = mlirType(self.typemap.get(str(rhs)))
          result_numba_type = self.typemap.get(assign.target.name)
          result_type = mlirType(result_numba_type)
          name = self.get_or_create_name(assign.target)
          # slight abuse of the arithSuffix utility to check whether we need a float dot
          zero = "0." if arithSuffix(result_numba_type) == "f" else "0"
          return (
              f"{out_name} = arith.constant dense<{zero}> :"
              f" {result_type} {mlirLoc(assign.loc)}\n{name} = linalg.matmul"
              f" ins({self.get_name(lhs)}, {self.get_name(rhs)} : {lhs_type},"
              f" {rhs_type}) outs({out_name} : {result_type}) ->"
              f" {result_type} {mlirLoc(assign.loc)}"
          )
        else:
          raise NotImplementedError(
              "Unknown function " + self.globals_map[func.name]
          )
      case ir.Expr(op="cast"):
        # not sure what to do here. maybe will be needed for type conversions
        # when interfacing with C
        self.forward_name(from_var=assign.target, to_var=assign.value.value)
        return ""
      case ir.Expr(op="getattr"):
        print(f"getattr(): {assign.value.value} and {assign.value.attr}")
        # look up the value:
        if str(assign.value.value) in self.globals_map:
          obj = self.globals_map[str(assign.value.value)]
          attr = assign.value.attr
          self.globals_map[assign.target.name] = f"{obj}.{attr}"
          return ""
        else:
          raise ValueError(
              f"Could not find {assign.value.value} in globals_map"
          )
      case ir.Const():
        name = self.get_or_create_name(assign.target)
        return (
            f"{name} = arith.constant {assign.value.value} :"
            f" {mlirType(self.typemap.get(assign.target.name))}"
            f" {mlirLoc(assign.loc)}"
        )
      case ir.Global():
        self.globals_map[assign.target.name] = assign.value.name
        return ""
      case ir.Var():
        self.forward_name(from_var=assign.target, to_var=assign.value)
        return ""
    raise NotImplementedError(
        f"Unsupported assignment RHS: {assign.value} of type"
        f" {type(assign.value).__name__}"
    )

  def emit_ext_if_needed(self, lhs, rhs):
    lhs_type = self.typemap.get(str(lhs))
    rhs_type = self.typemap.get(str(rhs))

    # Types agree: do nothing
    if lhs_type == rhs_type:
      return self.get_name(lhs), self.get_name(rhs), ""

    # types aren't integer types
    if not isinstance(lhs_type, types.Integer) or not isinstance(
        rhs_type, types.Integer
    ):
      raise NotImplementedError(
          "Extension handling for non-integer (e.g., floats, tensors) types"
          " is not yet supported. Please ensure (inferred) bit-widths match."
      )
      # TODO (#1162): Support bitwidth extension for float types
      #      (this probably requires adding support for local variable type hints,
      #       such as `b : F16 = 1.0` as there is no clear "natural" bitwidth for literals)
      # TODO (#1162): Support bitwidth extension for non-scalar types (e.g., tensors)

    if lhs_type.bitwidth == rhs_type.bitwidth:
      return self.get_name(lhs), self.get_name(rhs), ""

    # time to emit some extensions!
    short, long = lhs, rhs
    if lhs_type.bitwidth > rhs_type.bitwidth:
      short, long = rhs, lhs

    tmp = self.get_next_name()
    ext = (
        f"{tmp} = arith.extui {self.get_name(short)} : "
        f"{mlirType(self.typemap.get(str(short)))} "
        f"to {mlirType(self.typemap.get(str(long)))} "
        f"{mlirLoc(short.loc)}\n"
    )

    if lhs_type.bitwidth > rhs_type.bitwidth:
      return self.get_name(lhs), tmp, ext
    return tmp, self.get_name(rhs), ext

  def emit_binop(self, binop):
    # This should be the same, otherwise MLIR will complain
    suffix = arithSuffix(self.typemap.get(str(binop.lhs)))

    lhs_ssa, rhs_ssa, ext = self.emit_ext_if_needed(binop.lhs, binop.rhs)

    match binop.fn:
      case operator.lt:
        return f"arith.cmp{suffix} slt, {lhs_ssa}, {rhs_ssa}", ext
      case operator.ge:
        return f"arith.cmp{suffix} sge, {lhs_ssa}, {rhs_ssa}", ext
      case operator.eq:
        return f"arith.cmp{suffix} eq, {lhs_ssa}, {rhs_ssa}", ext
      case operator.ne:
        return f"arith.cmp{suffix} ne, {lhs_ssa}, {rhs_ssa}", ext
      case operator.add:
        return f"arith.add{suffix} {lhs_ssa}, {rhs_ssa}", ext
      case operator.mul:
        return f"arith.mul{suffix} {lhs_ssa}, {rhs_ssa}", ext
      case operator.sub:
        return f"arith.sub{suffix} {lhs_ssa}, {rhs_ssa}", ext
      case operator.lshift:
        return f"arith.shl{suffix} {lhs_ssa}, {rhs_ssa}", ext
      case operator.and_:
        return f"arith.and{suffix} {lhs_ssa}, {rhs_ssa}", ext
      case operator.xor:
        return f"arith.xor{suffix} {lhs_ssa}, {rhs_ssa}", ext
      case operator.mod:
        # Used signed semantics when integer types
        suffix = "si" if suffix == "i" else suffix
        return f"arith.rem{suffix} {lhs_ssa}, {rhs_ssa}", ext

    raise NotImplementedError("Unsupported binop: " + binop.fn.__name__)

  def emit_branch(self, branch, blocks_to_print):
    condvar = self.get_name(branch.cond)
    branches = [branch.truebr, branch.falsebr]
    branch_strs = [
        f"cf.cond_br {condvar}, ^bb{branch.truebr}, ^bb{branch.falsebr}"
    ]
    for _ in range(2):
      block_id, branch_block = blocks_to_print.popleft()
      assert block_id in branches
      body_str = self.emit_block(branch_block, blocks_to_print)
      block_header = f"^bb{block_id}:\n"
      branch_strs.append(block_header + textwrap.indent(body_str, "  "))
    return "\n".join(branch_strs)

  def emit_var_or_int(self, var_or_int: ir.Var | Any):
    if type(var_or_int) == ir.Var:
      # Create an index_cast operation
      var_name = self.get_name(var_or_int)
      new_name = self.forward_to_new_id(var_or_int)
      return (
          new_name,
          (
              f"{new_name} = arith.index_cast {var_name} :"
              f" {mlirType(self.typemap.get(var_or_int.name))} to index"
          ),
      )
    else:
      return var_or_int, ""

  def emit_loop_header(self, target, loop):
    # Returns the loop header str, e.g.
    # affine.for %i = 0 to 3 step 4 iter_args(%init = %var) {
    header = []
    resultvar = self.get_or_create_name(target)
    start, instr = self.emit_var_or_int(loop.range.start)
    if instr:
      header.append(instr)
    stop, instr = self.emit_var_or_int(loop.range.stop)
    if instr:
      header.append(instr)
    step, instr = self.emit_var_or_int(loop.range.step)
    if instr:
      header.append(instr)

    itvar = self.get_or_create_name(loop.header.phi_var)  # create var for i
    for_str = f"affine.for {itvar} = {start} to {stop}"
    if step != 1:
      for_str = f"{for_str} step {step}"

    if loop.inits:
      # Within the loop, forward the name for the init val to a new temp var
      init_args = [self.get_name(i) for i in loop.inits]
      iter_args = [self.forward_to_new_id(i) for i in loop.inits]
      iter_types = [mlirType(self.typemap.get(str(i))) for i in loop.inits]
      iter_args = ", ".join(
          [f"{it} = {init}" for (it, init) in zip(iter_args, init_args)]
      )
      iter_types = ", ".join([f"{ty}" for ty in iter_types])
      for_str = (
          f"{resultvar}:{len(loop.inits)} = {for_str} iter_args({iter_args}) ->"
          f" ({iter_types})"
      )
    header.append(for_str + " {")
    return "\n".join(header)

  def emit_loop(self, target, blocks_to_print):
    loop = self.loops[target]
    header = self.emit_loop_header(target, loop)
    blocks_to_print.popleft()

    # TODO(#1412): support nested loops.
    body_id, loop_block = blocks_to_print.popleft()
    assert body_id == loop.header.body_id
    for instr in loop_block.body:
      if type(instr) == ir.Assign and instr.target in self.loops:
        raise NotImplementedError("Nested loops are not supported")

    body_str = self.emit_block(loop_block, blocks_to_print)
    if len(loop.inits) > 1:
      # Yield the iter args
      yield_vars = ", ".join([self.get_name(init) for init in loop.inits])
      ret_types = ", ".join(
          [mlirType(self.typemap.get(str(i))) for i in loop.inits]
      )
      yield_str = f"affine.yield {yield_vars} : {ret_types}"
      body_str += "\n" + yield_str

    # After we emit the body, we need to replace all uses of the iterarg after
    # the block with the result of the for loop.
    target_ssa_name = self.get_name(target).strip("%")
    for i in range(len(loop.inits)):
      self.forward_name_to_id(loop.inits[i], f"{target_ssa_name}#{i}")

    result = "\n".join([header, textwrap.indent(body_str, "  "), "}"])
    return result

  def emit_return(self, ret: ir.Return):
    var = self.get_name(ret.value)
    return (
        f"func.return {var} :"
        f" {mlirType(self.typemap.get(str(ret.value)))} {mlirLoc(ret.loc)}"
    )
