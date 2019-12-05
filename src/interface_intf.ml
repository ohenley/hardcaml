(** Interfaces specify the widths and names of a group of signals, and some functions for
    manipulating the signals as a group.

    They are generally used with [ppx_deriving_hardcaml] as follows

    {[
      type t = { ... } [@@deriving sexp_of, hardcaml]
    ]}

    The [sexp_of] is required, and must appear before [hardcaml].  This syntax
    generates a call to [Interface.Make], which therefore does not need to be
    explicitly called. *)

open! Import

module type Pre = sig
  type 'a t [@@deriving sexp_of]

  val t : (string * int) t
  val iter : 'a t -> f:('a -> unit) -> unit
  val iter2 : 'a t -> 'b t -> f:('a -> 'b -> unit) -> unit
  val map : 'a t -> f:('a -> 'b) -> 'b t
  val map2 : 'a t -> 'b t -> f:('a -> 'b -> 'c) -> 'c t
  val to_list : 'a t -> 'a list
end

module type Ast = sig
  (** The PPX can optionally generate an [ast] field containing an [Ast.t]. This
      represents the structure of the interface, including how it is constructed from
      fields, arrays, lists and sub-modules.

      This is of particular use when generating further code from the interface i.e. a
      register interace specification.

      [ast]s are not generated by default. *)
  module rec Ast : sig
    type t = Field.t list [@@deriving sexp_of]
  end

  and Field : sig
    type t =
      { name : string (** Name of the field *)
      ; type_ : Type.t (** Field type - a signal or a sub-module *)
      ; sequence : Sequence.t option (** Is the field type an array or list? *)
      ; doc : string option
      (** Ocaml documentation string, if any. Note that this must be placed in the [ml]
          and not [mli].*)
      }
    [@@deriving sexp_of]
  end

  and Type : sig
    type t =
      | Signal of
          { bits : int
          ; rtlname : string
          }
      | Module of
          { name : string
          ; ast : Ast.t
          }
    [@@deriving sexp_of]
  end

  and Sequence : sig
    module Kind : sig
      type t =
        | Array
        | List
      [@@deriving sexp_of]
    end

    type t =
      { kind : Kind.t
      ; length : int
      }
    [@@deriving sexp_of]
  end

  type t = Ast.t [@@deriving sexp_of]
end

module type Comb = sig
  type 'a interface
  type comb
  type t = comb interface [@@deriving sexp_of]

  (** Actual bit widths of each field. *)
  val widths : t -> int interface

  (** Raise if the widths of [t] do not match those specified in the interface. *)
  val assert_widths : t -> unit

  (** Each field is set to the constant integer value provided. *)
  val of_int : int -> t

  (** [consts c] sets each field to the integer value in [c] using the declared field bit
      width. *)
  val of_ints : int interface -> t

  val const : int -> t [@@deprecated "[since 2019-11] interface const"]
  val consts : int interface -> t [@@deprecated "[since 2019-11] interface consts"]

  (** Pack interface into a vector. *)
  val pack : ?rev:bool -> t -> comb

  (** Unpack interface from a vector. *)
  val unpack : ?rev:bool -> comb -> t

  (** Multiplex a list of interfaces. *)
  val mux : comb -> t list -> t

  val mux2 : comb -> t -> t -> t

  (** Concatenate a list of interfaces. *)
  val concat : t list -> t
end

module type S = sig
  include Pre
  include Equal.S1 with type 'a t := 'a t

  (** RTL names specified in the interface definition - commonly also the OCaml field
      name. *)
  val port_names : string t

  (** Bit widths specified in the interface definition. *)
  val port_widths : int t

  (** Create association list indexed by field names. *)
  val to_alist : 'a t -> (string * 'a) list

  (** Create interface from association list indexed by field names *)
  val of_alist : (string * 'a) list -> 'a t

  val zip : 'a t -> 'b t -> ('a * 'b) t
  val zip3 : 'a t -> 'b t -> 'c t -> ('a * 'b * 'c) t
  val zip4 : 'a t -> 'b t -> 'c t -> 'd t -> ('a * 'b * 'c * 'd) t
  val zip5 : 'a t -> 'b t -> 'c t -> 'd t -> 'e t -> ('a * 'b * 'c * 'd * 'e) t
  val map3 : 'a t -> 'b t -> 'c t -> f:('a -> 'b -> 'c -> 'd) -> 'd t
  val map4 : 'a t -> 'b t -> 'c t -> 'd t -> f:('a -> 'b -> 'c -> 'd -> 'e) -> 'e t

  val map5
    :  'a t
    -> 'b t
    -> 'c t
    -> 'd t
    -> 'e t
    -> f:('a -> 'b -> 'c -> 'd -> 'e -> 'f)
    -> 'f t

  val iter3 : 'a t -> 'b t -> 'c t -> f:('a -> 'b -> 'c -> unit) -> unit
  val iter4 : 'a t -> 'b t -> 'c t -> 'd t -> f:('a -> 'b -> 'c -> 'd -> unit) -> unit

  val iter5
    :  'a t
    -> 'b t
    -> 'c t
    -> 'd t
    -> 'e t
    -> f:('a -> 'b -> 'c -> 'd -> 'e -> unit)
    -> unit

  val fold : 'a t -> init:'b -> f:('b -> 'a -> 'b) -> 'b
  val fold2 : 'a t -> 'b t -> init:'c -> f:('c -> 'a -> 'b -> 'c) -> 'c

  (** Offset of each field within the interface.  The first field is placed at the least
      significant bit, unless the [rev] argument is true. *)
  val offsets : ?rev:bool (** default is [false]. *) -> unit -> int t

  (** Take a list of interfaces and produce a single interface where each field is a
      list. *)
  val of_interface_list : 'a t list -> 'a list t

  (** Create a list of interfaces from a single interface where each field is a list.
      Raises if all lists don't have the same length. *)
  val to_interface_list : 'a list t -> 'a t list

  module type Comb = Comb with type 'a interface := 'a t

  module Make_comb (Comb : Comb.S) : Comb with type comb = Comb.t
  module Of_bits : Comb with type comb = Bits.t

  module Of_signal : sig
    include Comb with type comb = Signal.t

    (** Create a wire for each field.  If [named] is true then wires are given the RTL field
        name.  If [from] is provided the wire is attached to each given field in [from]. *)
    val wires
      :  ?named:bool (** default is [false]. *)
      -> ?from:t (** No default *)
      -> unit
      -> t

    val assign : t -> t -> unit
    val ( <== ) : t -> t -> unit

    (** [inputs t] is [wires () ~named:true]. *)
    val inputs : unit -> t

    (** [outputs t] is [wires () ~from:t ~named:true]. *)
    val outputs : t -> t

    (** Apply name to field of the interface. Add [prefix] and [suffix] if specified. *)
    val apply_names
      :  ?prefix:string (** Default is [""] *)
      -> ?suffix:string (** Default is [""] *)
      -> ?naming_op:(comb -> string -> comb) (** Default is [Signal.(--)] *)
      -> t
      -> t
  end
end

module type Empty = sig
  type 'a t = None

  include S with type 'a t := 'a t
end

(** An enumerated type (generally a variant type with no arguments) which should derive
    [compare, enumerate, sexp_of, variants]. *)
module type Enum = sig
  type t [@@deriving compare, enumerate, sexp_of]

  module Variants : sig
    val to_rank : t -> int
  end
end

(** Functions to project an [Enum] type into and out of hardcaml bit vectors representated
    as an interface. *)
module type S_enum = sig
  module Enum : Enum
  include S

  val of_enum : (module Comb.S with type t = 'a) -> Enum.t -> 'a t
  val to_enum : Bits.t t -> Enum.t

  val mux
    :  (module Comb.S with type t = 'a)
    -> default:'a
    -> 'a t
    -> (Enum.t * 'a) list
    -> 'a

  module For_testing : sig
    val set : Bits.t ref t -> Enum.t -> unit
    val get : Bits.t ref t -> Enum.t
  end
end

(** Binary and onehot selectors for [Enums]. *)
module type S_enums = sig
  module Enum : Enum
  module Binary : S_enum with module Enum := Enum
  module One_hot : S_enum with module Enum := Enum
end

module type Interface = sig
  module type Pre = Pre
  module type S = S
  module type Ast = Ast
  module type Empty = Empty

  module Ast : Ast
  module Empty : Empty

  module type S_with_ast = sig
    include S

    val ast : Ast.t
  end

  (** Type of functions representing the implementation of a circuit from an input to
      output interface. *)
  module Create_fn (I : S) (O : S) : sig
    type 'a t = 'a I.t -> 'a O.t [@@deriving sexp_of]
  end

  module Make (X : Pre) : S with type 'a t := 'a X.t

  module type S_enum = S_enum
  module type S_enums = S_enums

  (** Constructs a hardcaml interface which represents hardware for the given [Enum] as an
      absstract [Interface]. *)
  module Make_enums (Enum : Enum) : S_enums with module Enum := Enum
end
