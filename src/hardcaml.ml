module Always = Always
module Architecture = Architecture
module Assertion_manager = Assertion_manager
module Async_fifo = Async_fifo
module Bits = Bits
module Bits_list = Bits_list
module Build_mode = Build_mode
module Caller_id = Caller_id
module Circuit = Circuit
module Circuit_database = Circuit_database
module Circuit_utilization = Circuit_utilization
module Comb = Comb
module Combinational_op = Combinational_op
module Combinational_ops_database = Combinational_ops_database
module Constant = Constant
module Cyclesim = Cyclesim
module Cyclesim_float_ops = Cyclesim_float_ops
module Design_rule_checks = Design_rule_checks
module Dedup = Dedup
module Edge = Edge
module Enum = Enum
module Fifo = Fifo
module Flags_vector = Flags_vector
module Hierarchy = Hierarchy
module Interface = Interface
module Instantiation = Instantiation
module Level = Level
module Logic = Logic
module Mangler = Mangler
module Parameter = Parameter
module Parameter_name = Parameter_name
module Property = Property
module Property_manager = Property_manager
module Ram = Ram
module Reg_spec = Reg_spec
module Reserved_words = Reserved_words

module Rtl = struct
  include Rtl
  module Ast = Rtl_ast
  module Deprecated = Rtl_deprecated
  module Name = Rtl_name
  module Verilog = Rtl_verilog_of_ast
  module Vhdl = Rtl_vhdl_of_ast
end

module Rtl_attribute = Rtl_attribute
module Scope = Scope
module Side = Side
module Signal = Signal
module Signal_graph = Signal_graph
module Signedness = Signedness
module Structural = Structural
module Types = Types
module Vcd = Vcd
module With_valid = With_valid

(** These are exposed for code that does [@@deriving hardcaml]. *)
let sexp_of_array = Base.sexp_of_array

let sexp_of_list = Base.sexp_of_list
