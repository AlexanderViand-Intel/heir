"""Heracles Backend."""

import pathlib

import colorama

Fore = colorama.Fore
Style = colorama.Style

from heir.interfaces import BackendInterface, CompilationResult, ClientInterface, EncValue
from heir.backends.util import common

Path = pathlib.Path


class HeraclesClientInterface(ClientInterface):

  def __init__(self, compilation_result: CompilationResult):
    self.compilation_result = compilation_result

  def setup(self):
    print(
        "HEIR Warning (Heracles Backend): "
        + Fore.YELLOW
        + Style.BRIGHT
        + f"{self.compilation_result.func_name}.setup() is a no-op in the"
        " Heracles Backend"
    )

  # def encryt_<arg_name> is handled via __getattr__
  def __getattr__(self, key):

    if key.startswith("encrypt_"):
      arg_name = key[len("encrypt_") :]

      def wrapper(arg):
        print(
            "HEIR Warning (Heracles Backend): "
            + Fore.YELLOW
            + Style.BRIGHT
            + f"{self.compilation_result.func_name}.{key}() is a no-op in the"
            " Heracles Backend"
        )
        return arg

      return wrapper

    raise AttributeError(f"Attribute {key} not found")

  def eval(self, *args, **kwargs):
    print(
        "HEIR Warning (Heracles Backend): "
        + Fore.YELLOW
        + Style.BRIGHT
        + f"{self.compilation_result.func_name}.eval() is the same as"
        f" {self.compilation_result.func_name}() in the Heracles Backend."
    )
    stripped_args, stripped_kwargs = (
        common.strip_and_verify_eval_arg_consistency(
            self.compilation_result, *args, **kwargs
        )
    )

    return self.func(*stripped_args, **stripped_kwargs)

  def decrypt_result(self, result):
    print(
        "HEIR Warning (Heracles Backend): "
        + Fore.YELLOW
        + Style.BRIGHT
        + f"{self.compilation_result.func_name}.decrypt() is a no-op in the"
        " Heracles Backend"
    )
    return result

  def __call__(self, *args, **kwargs):
    print(
        "HEIR Warning (Heracles Backend): "
        + Fore.YELLOW
        + Style.BRIGHT
        + f"{self.compilation_result.func_name} is the same as"
        f" {self.compilation_result.func_name}.original() "
        "in the Heracles Backend."
    )
    return self.func(*args, **kwargs)


class HeraclesBackend(BackendInterface):

  def run_backend(
      self,
      workspace_dir,
      heir_opt,
      heir_translate,
      func_name,
      arg_names,
      secret_args,
      heir_opt_output,
      debug,
  ):

    # Initialize Colorama for error and debug messages
    colorama.init(autoreset=True)

    # Convert to common subset (e.g.`bgv.extract` to rotate/add/mul)
    heir_opt_options = [f"--bgv-to-lwe"]
    if debug:
      heir_opt_options.append("--view-op-graph")
      print(
          "HEIRpy Debug (Heracles Backend): "
          + Style.BRIGHT
          + f"Running heir-opt {' '.join(heir_opt_options)}"
      )
    heir_opt_output, graph = heir_opt.run_binary_stderr(
        input=heir_opt_output,
        options=(heir_opt_options),
    )
    if debug:
      # Print output after heir_opt:
      mlirpath = Path(workspace_dir) / f"{func_name}.backend.mlir"
      graphpath = Path(workspace_dir) / f"{func_name}.backend.dot"
      print(
          f"HEIRpy Debug (Heracles Backend): Writing backend MLIR to {mlirpath}"
      )
      with open(mlirpath, "w") as f:
        f.write(heir_opt_output)
      print(
          "HEIRpy Debug (Heracles Backend): Writing backend graph to"
          f" {graphpath}"
      )
      with open(graphpath, "w") as f:
        f.write(graph)

    # Translate to Heracles SDK *.csv format
    csv_filepath = Path(workspace_dir) / f"{func_name}.csv"
    heir_translate_options = [
        "--allow-unregistered-dialect",  # TODO(1414): remove once the translate input no longer includes stray attributes
        "--emit-heracles-sdk",
        "-o",
        csv_filepath,
    ]
    if debug:
      print(
          "HEIRpy Debug (Heracles Backend): "
          + Style.BRIGHT
          + "Running heir-translate"
          f" {' '.join(str(o) for o in heir_translate_options)}"
      )
    stdout, stderr = heir_translate.run_binary_stderr(
        input=heir_opt_output,
        options=heir_translate_options,
    )
    if debug:
      print(f"stdout was: {stdout}")
      print(f"stderr was: {stderr}")

    result = CompilationResult(
        module=None,
        func_name=func_name,
        secret_args=secret_args,
        arg_names=arg_names,
        arg_enc_funcs=None,
        result_dec_func=None,
        main_func=None,
        setup_funcs=None,
    )

    return HeraclesClientInterface(result)
