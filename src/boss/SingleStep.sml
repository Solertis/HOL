structure SingleStep :> SingleStep =
struct

open HolKernel Parse basicHol90Lib;

  type term = Term.term
  type thm = Thm.thm
  type tactic = Abbrev.tactic
  type 'a quotation = 'a Portable.frag list

infix THEN THENL ORELSE |-> ##;
infixr -->;

fun STEP_ERR func mesg =
     HOL_ERR{origin_structure = "SingleStep",
             origin_function = func,
             message = mesg};


fun name_eq s M = ((s = #Name(dest_var M)) handle HOL_ERR _ => false)
fun tm_free_eq M N P =
   (aconv N P andalso free_in N M) orelse raise STEP_ERR "tm_free_eq" ""

(*---------------------------------------------------------------------------*
 * Mildly altered STRUCT_CASES_TAC, so that it does a SUBST_ALL_TAC instead  *
 * of a SUBST1_TAC.                                                          *
 *---------------------------------------------------------------------------*)

val VAR_INTRO_TAC = REPEAT_TCL STRIP_THM_THEN SUBST_ALL_TAC;

val TERM_INTRO_TAC =
 REPEAT_TCL STRIP_THM_THEN
     (fn th => TRY (SUBST_ALL_TAC th) THEN ASSUME_TAC th);

fun away gfrees0 bvlist =
  rev(fst
    (rev_itlist (fn v => fn (plist,gfrees) =>
       let val v' = prim_variant gfrees v
       in ((v,v')::plist, v'::gfrees)
       end) bvlist ([], gfrees0)));

fun FREEUP [] g = ALL_TAC g
  | FREEUP tofree (g as (asl,w)) =
     let val (V,_) = strip_forall w
         val gfrees = free_varsl (w::asl)
         val Vmap = away gfrees V
         val tobind = map snd (gather (fn (v,_) => not (mem v tofree)) Vmap)
     in
       (MAP_EVERY X_GEN_TAC (map snd Vmap)
          THEN MAP_EVERY ID_SPEC_TAC (rev tobind)) g
     end;

(*---------------------------------------------------------------------------*
 * Do case analysis on given term. The quotation is parsed into a term M that*
 * must match a subterm in the body (or the assumptions). If M is a variable,*
 * then the match of the names must be exact. Once the term to split over is *
 * known, its type and the associated facts are obtained and used to do the  *
 * split with. Variables of M might be quantified in the goal. If so, we try *
 * to unquantify the goal so that the case split has meaning.                *
 *                                                                           *
 * It can happen that the given term is not found anywhere in the goal. If   *
 * the term is boolean, we do a case-split on whether it is true or false.   *
 *---------------------------------------------------------------------------*)

datatype category = Free of term
                  | Bound of term list * term
                  | Alien of term

fun cat_tyof (Free M)      = type_of M
  | cat_tyof (Bound (_,M)) = type_of M
  | cat_tyof (Alien M)     = type_of M

fun prim_find_subterm FVs tm (asl,w) =
   if (is_var tm)
   then let val name = #Name(dest_var tm)
        in
          Free (Lib.first(name_eq name) FVs)
          handle HOL_ERR _
          => Bound(let val (V,_) = strip_forall w
                       val v = Lib.first (name_eq name) V
                   in
                     ([v], v)
                   end)
        end
   else Free (tryfind(fn x => find_term (can(tm_free_eq x tm)) x) (w::asl))
        handle HOL_ERR _
        => Bound(let val (V,body) = strip_forall w
                     val M = find_term (can (tm_free_eq body tm)) body
                 in
                    (intersect (free_vars M) V, M)
                 end)
                 handle HOL_ERR _ => Alien tm;

fun find_subterm qtm (g as (asl,w)) =
  let val FVs = free_varsl (w::asl)
      val tm = parse_in_context FVs qtm
  in
    prim_find_subterm FVs tm g
  end;


fun Cases_on qtm (g as (asl,w)) =
 let val st = find_subterm qtm g
     val {Tyop, ...} = Type.dest_type(cat_tyof st)
 in case TypeBase.read Tyop
    of SOME facts =>
        let val thm = TypeBase.nchotomy_of facts
        in case st
           of Free M =>
               if (is_var M) then VAR_INTRO_TAC (ISPEC M thm) g else
               if (Tyop="bool") then ASM_CASES_TAC M g
               else TERM_INTRO_TAC (ISPEC M thm) g
            | Bound(V,M) => (FREEUP V THEN VAR_INTRO_TAC (ISPEC M thm)) g
            | Alien M    => if (Tyop="bool") then ASM_CASES_TAC M g
                            else TERM_INTRO_TAC (ISPEC M thm) g
        end
     | NONE => raise STEP_ERR "Cases_on"
                         ("No cases theorem found for type: "^Lib.quote Tyop)
 end
 handle e as HOL_ERR _ => Exception.Raise e;


fun primInduct st ind_tac (g as (asl,c)) =
 let fun ind_non_var V M =
       let val Mfrees = free_vars M
           fun has_vars tm = not(null_intersection (free_vars tm) Mfrees)
           val tms = filter has_vars asl
           val newvar = variant (free_varsl (c::asl))
                                (mk_var{Name="v",Ty=type_of M})
           val tm = mk_exists{Bvar=newvar, Body=mk_eq{lhs=newvar, rhs=M}}
           val th = EXISTS(tm,M) (REFL M)
        in
          FREEUP V
            THEN MAP_EVERY UNDISCH_TAC tms
            THEN CHOOSE_THEN MP_TAC th
            THEN MAP_EVERY ID_SPEC_TAC Mfrees
            THEN ID_SPEC_TAC newvar
            THEN ind_tac
        end
 in case st
     of Free M =>
         if is_var M
         then let val tms = filter (free_in M) asl
              in (MAP_EVERY UNDISCH_TAC tms THEN ID_SPEC_TAC M THEN ind_tac) g
              end
         else ind_non_var [] M g
      | Bound(V,M) =>
         if is_var M then (FREEUP V THEN ID_SPEC_TAC M THEN ind_tac) g
         else ind_non_var V M g
      | Alien M =>
         if is_var M then raise STEP_ERR "primInduct" "Alien variable"
         else ind_non_var (free_vars M) M g
 end
 handle e as HOL_ERR _ => Exception.Raise e;


fun Induct_on qtm g =
 let val st = find_subterm qtm g
     val {Tyop, ...} = Type.dest_type(cat_tyof st)
       handle HOL_ERR _ =>
         raise STEP_ERR "Induct_on"
           "No induction theorems available for variable types"
 in case TypeBase.read Tyop
     of SOME facts =>
        let val thm = TypeBase.induction_of facts
            val ind_tac = INDUCT_THEN thm ASSUME_TAC
        in primInduct st ind_tac g
        end
      | NONE => raise STEP_ERR "Induct_on"
                    ("No induction theorem found for type: "^Lib.quote Tyop)
 end;

fun completeInduct_on qtm g =
 let val st = find_subterm qtm g
     val ind_tac = INDUCT_THEN arithmeticTheory.COMPLETE_INDUCTION ASSUME_TAC
 in
     primInduct st ind_tac g
 end;

(*---------------------------------------------------------------------------
    Invoked e.g. measureInduct_on `LENGTH L` or
                 measureInduct_on `(\(x,w). x+w) (M,N)`
 ---------------------------------------------------------------------------*)

local open relationTheory prim_recTheory
      val mvar = mk_var{Name="m", Ty=Type`:'a -> num`}
      val measure_m = mk_comb{Rator= #const(const_decl"measure"),Rand=mvar}
      val ind_thm0 = GEN mvar
          (BETA_RULE
             (REWRITE_RULE[WF_measure,measure_def,inv_image_def]
                 (MATCH_MP (SPEC measure_m WF_INDUCTION_THM)
                         (SPEC_ALL WF_measure))))
in
fun measureInduct_on q (g as (asl,w)) =
 let val FVs = free_varsl (w::asl)
     val tm = parse_in_context FVs q
     val {Rator=meas, Rand=arg} = dest_comb tm
     val (d,r) = dom_rng (type_of meas)  (* r should be num *)
     val st = prim_find_subterm FVs arg g
     val st_type = cat_tyof st
     val meas' = inst (match_type d st_type) meas
     val ind_thm1 = INST_TYPE [Type.alpha |-> st_type] ind_thm0
     val ind_thm2 = CONV_RULE (DEPTH_CONV Let_conv.GEN_BETA_CONV)
                              (SPEC meas' ind_thm1)
     val ind_tac = INDUCT_THEN ind_thm2 ASSUME_TAC
 in
     primInduct st ind_tac g
 end
end;


fun Cases (g as (_,w)) =
  let val {Bvar,...} = dest_forall w handle HOL_ERR _
                       => raise STEP_ERR "Cases" "not a forall"
      val {Name,...} = dest_var Bvar
  in
    Cases_on [QUOTE Name] g
  end;


fun Induct (g as (_,w)) =
 let val {Bvar, ...} = Dsyntax.dest_forall w handle HOL_ERR _
                       => raise STEP_ERR "Induct" "not a forall"
      val {Name,...} = dest_var Bvar
 in
   Induct_on [QUOTE Name] g
 end;

(*---------------------------------------------------------------------------*
 * A simple aid to reasoning by contradiction.                               *
 *---------------------------------------------------------------------------*)

local val ss = simpLib.++(boolSimps.bool_ss,boolSimps.NOT_ss)
in
fun SPOSE_NOT_THEN ttac =
  CCONTR_TAC THEN
  POP_ASSUM (fn th => ttac (simpLib.SIMP_RULE ss [] th))
end;

(*---------------------------------------------------------------------------
     Assertional style reasoning
 ---------------------------------------------------------------------------*)

infix 8 by;

fun (q by tac) (g as (asl,w)) =
  let val tm = parse_in_context (free_varsl (w::asl)) q
  in
     Tactic.via(tm,tac) g
  end
  handle e as HOL_ERR {message,origin_function,...} =>
    raise STEP_ERR "by" ("Trapped message: \""^message^"\", from: "^
                         origin_function);

end;
