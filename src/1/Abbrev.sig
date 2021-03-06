signature Abbrev =
sig
  type thm          = Thm.thm
  type term         = Term.term
  type hol_type     = Type.hol_type
  type conv         = term -> thm
  type rule         = thm -> thm
  type goal         = term list * term
  type validation   = thm list -> thm
  type tactic       = goal -> goal list * validation
  type list_validation = thm list -> thm list
  type list_tactic  = goal list -> goal list * list_validation
  type ('a,'b) gentactic = 'a -> goal list * (thm list -> 'b)
      (* ['a |-> goal, 'b -> thm] gives tactic;
         ['a |-> goal list, 'b -> thm list] gives list_tactic *)
  type thm_tactic   = thm -> tactic
  type thm_tactical = thm_tactic -> thm_tactic
  type ppstream     = Portable.ppstream
  type 'a quotation = 'a Portable.frag list
  type ('a,'b)subst = ('a,'b) Lib.subst
  type defn         = DefnBase.defn
end

(*
   [conv] is the type of conversions: functions of type term -> thm that,
   given a term t, return a theorem of the form "|- t = t'".
*)
