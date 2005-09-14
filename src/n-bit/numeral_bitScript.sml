(* ========================================================================= *)
(* FILE          : numeral_bitScript.sml                                     *)
(* DESCRIPTION   : Theorems providing numeral based evaluation of            *)
(*                 functions in bitTheory                                    *)
(* AUTHOR        : (c) Anthony Fox, University of Cambridge                  *)
(* DATE          : 2001-2005                                                 *)
(* ========================================================================= *)

(* interactive use:
  load "bitTheory";
*)

open HolKernel Parse boolLib bossLib;
open Q arithmeticTheory numeralTheory;
open bitTheory;

val _ = new_theory "numeral_bit";

(* ------------------------------------------------------------------------- *)

val SUC_RULE = CONV_RULE numLib.SUC_TO_NUMERAL_DEFN_CONV;

val iMOD_2EXP_def = 
 Prim_rec.new_recursive_definition
  {name = "iMOD_2EXP_def",
   def = ``(iMOD_2EXP 0 n = 0) /\
           (iMOD_2EXP (SUC x) n =
              2 * (iMOD_2EXP x (n DIV 2)) + SBIT (ODD n) 0)``,
   rec_axiom = prim_recTheory.num_Axiom};

val iBITWISE_def = 
  Definition.new_definition("iBITWISE_def", ``iBITWISE = BITWISE``);

val SIMP_BIT1 = (GSYM o SIMP_RULE arith_ss []) BIT1;

val iBITWISE = prove(
  `(!opr a b. iBITWISE 0 opr a b = ZERO) /\
   (!x opr a b.
     iBITWISE (SUC x) opr a b =
       let w = iBITWISE x opr (DIV2 a) (DIV2 b) in
       if opr (ODD a) (ODD b) then BIT1 w else iDUB w)`,
  RW_TAC arith_ss [iBITWISE_def,iDUB,SIMP_BIT1,SBIT_def,EXP,
                   LSB_ODD,GSYM DIV2_def,BITWISE_EVAL,LET_THM]
    THEN REWRITE_TAC [BITWISE_def,ALT_ZERO]);

val iBITWISE = save_thm("iBITWISE", SUC_RULE iBITWISE);

val NUMERAL_BITWISE = store_thm("NUMERAL_BITWISE",
  `(!x f a. BITWISE x f 0 0 = NUMERAL (iBITWISE x f 0 0)) /\
   (!x f a. BITWISE x f (NUMERAL a) 0 =
              NUMERAL (iBITWISE x f (NUMERAL a) 0)) /\
   (!x f b. BITWISE x f 0 (NUMERAL b) =
              NUMERAL (iBITWISE x f 0 (NUMERAL b))) /\
    !x f a b. BITWISE x f (NUMERAL a) (NUMERAL b) =
                 NUMERAL (iBITWISE x f (NUMERAL a) (NUMERAL b))`,
  REWRITE_TAC [iBITWISE_def,NUMERAL_DEF]);

val NUMERAL_DIV2 = store_thm("NUMERAL_DIV2",
   `(DIV2 0 = 0) /\
     (!n. DIV2 (NUMERAL (BIT1 n)) = NUMERAL n) /\
     (!n. DIV2 (NUMERAL (BIT2 n)) = NUMERAL (SUC n))`,
  RW_TAC bool_ss [ALT_ZERO,NUMERAL_DEF,BIT1,BIT2]
    THEN SIMP_TAC arith_ss [DIV2_def,
           ONCE_REWRITE_RULE [MULT_COMM] ADD_DIV_ADD_DIV]);

val DIV_2EXP = prove(
  `(!n. DIV_2EXP 0 n = n) /\
   (!x. DIV_2EXP x 0 = 0) /\
   (!x n. DIV_2EXP (SUC x) (NUMERAL n) =
            DIV_2EXP x (DIV2 (NUMERAL n)))`,
  RW_TAC arith_ss [DIV_2EXP_def,DIV2_def,EXP,ZERO_DIV,
    DIV_DIV_DIV_MULT,ZERO_LT_TWOEXP]);

val NUMERAL_DIV_2EXP = save_thm("NUMERAL_DIV_2EXP", SUC_RULE DIV_2EXP);

val NUMERAL_BIT_REV = prove(
  `(!x y. BIT_REV 0 x y = y) /\
   (!n y. BIT_REV (SUC n) 0 y = BIT_REV n 0 (iDUB y)) /\
   (!n x y. BIT_REV (SUC n) (NUMERAL x) y =
      BIT_REV n (DIV2 (NUMERAL x)) (if ODD x then BIT1 y else iDUB y))`,
  RW_TAC bool_ss [BIT_REV_def,SBIT_def,NUMERAL_DEF,DIV2_def,
           ADD,ADD_0,BIT2,BIT1,iDUB,ALT_ZERO]
    THEN FULL_SIMP_TAC arith_ss []);

val NUMERAL_BIT_REV = save_thm("NUMERAL_BIT_REV", SUC_RULE NUMERAL_BIT_REV);

val NUMERAL_BIT_REVERSE = store_thm("NUMERAL_BIT_REVERSE",
  `(!m. BIT_REVERSE (NUMERAL m) 0 = NUMERAL (BIT_REV (NUMERAL m) 0 ZERO)) /\
    !n m. BIT_REVERSE (NUMERAL m) (NUMERAL n) =
       NUMERAL (BIT_REV (NUMERAL m) (NUMERAL n) ZERO)`,
  SIMP_TAC bool_ss [NUMERAL_DEF,ALT_ZERO,BIT_REVERSE_EVAL]);

(* ------------------------------------------------------------------------- *)

val ADD_DIV_ADD_DIV2 = (GEN_ALL o ONCE_REWRITE_RULE [MULT_COMM] o
  SIMP_RULE arith_ss [GSYM ADD1] o SPECL [`n`,`1`] o
  SIMP_RULE bool_ss [DECIDE (Term `0 < 2`)] o SPEC `2`) ADD_DIV_ADD_DIV;

val SPEC_MOD_COMMON_FACTOR = (GEN_ALL o
   SIMP_RULE arith_ss [GSYM EXP,ZERO_LT_TWOEXP] o
   SPECL [`2`,`m`,`2 ** SUC h`]) MOD_COMMON_FACTOR;

val SPEC_MOD_COMMON_FACTOR2 = (GEN_ALL o
   SYM o SIMP_RULE arith_ss [GSYM EXP,ZERO_LT_TWOEXP] o
   SPECL [`2`,`m`,`2 ** h`]) MOD_COMMON_FACTOR;

val SPEC_MOD_PLUS = (GEN_ALL o GSYM o
  SIMP_RULE bool_ss [ZERO_LT_TWOEXP] o SPEC `2 ** n`) MOD_PLUS;

val SPEC_TWOEXP_MONO = (GEN_ALL o SIMP_RULE arith_ss [] o
  SPECL [`0`,`SUC b`]) TWOEXP_MONO;

val lem = prove(
  `!m n. (2 * m) MOD 2 ** SUC n + 1 < 2 ** SUC n`,
  RW_TAC arith_ss [SPEC_MOD_COMMON_FACTOR2,EXP,DOUBLE_LT,MOD_2EXP_LT,
    (GEN_ALL o numLib.REDUCE_RULE o SPECL [`m`,`i`,`1`]) LESS_MULT_MONO]);

val BITS_SUC2 = prove(
  `!h n. BITS (SUC h) 0 n = 2 * BITS h 0 (n DIV 2) + SBIT (ODD n) 0`,
  RW_TAC arith_ss [SBIT_def]
    THEN FULL_SIMP_TAC arith_ss [GSYM EVEN_ODD,EVEN_EXISTS,ODD_EXISTS,
           BITS_ZERO3,ADD_DIV_ADD_DIV2,SPEC_MOD_COMMON_FACTOR,
           ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV]
    THEN SUBST1_TAC (SPEC `2 * m` ADD1)
    THEN ONCE_REWRITE_TAC [SPEC_MOD_PLUS]
    THEN SIMP_TAC bool_ss [LESS_MOD,ZERO_LT_TWOEXP,SPEC_TWOEXP_MONO,LESS_MOD,lem]);

val MOD_2EXP_ZERO = prove(
  `!x. MOD_2EXP x 0 = 0`,
  SIMP_TAC arith_ss [MOD_2EXP_def,ZERO_MOD,ZERO_LT_TWOEXP]);

val iMOD_2EXP = prove(
  `!x n. MOD_2EXP x (NUMERAL n) = NUMERAL (iMOD_2EXP x n)`,
  REWRITE_TAC [NUMERAL_DEF]
    THEN Induct
    THEN1 SIMP_TAC arith_ss [iMOD_2EXP_def,MOD_2EXP_def]
    THEN STRIP_TAC THEN REWRITE_TAC [iMOD_2EXP_def]
    THEN POP_ASSUM (SUBST1_TAC o SYM o SPEC `n DIV 2`)
    THEN Cases_on `x`
    THEN1 (SIMP_TAC arith_ss [MOD_2EXP_def,MOD_2,EVEN_ODD,SBIT_def]
             THEN PROVE_TAC [])
    THEN REWRITE_TAC [BITS_SUC2,(GSYM o REWRITE_RULE [GSYM MOD_2EXP_def])
           BITS_ZERO3]);

val iMOD_2EXP_CLAUSES = prove(
  `(!n. iMOD_2EXP 0 n = ZERO) /\
   (!x n. iMOD_2EXP x ZERO = ZERO) /\
   (!x n. iMOD_2EXP (SUC x) (BIT1 n) = BIT1 (iMOD_2EXP x n)) /\
   (!x n. iMOD_2EXP (SUC x) (BIT2 n) = iDUB (iMOD_2EXP x (SUC n)))`,
  RW_TAC arith_ss [iMOD_2EXP_def,iDUB,SBIT_def,numeral_evenodd,GSYM DIV2_def,
    REWRITE_RULE [SYM ALT_ZERO,NUMERAL_DEF,ADD1] NUMERAL_DIV2]
    THENL [
      REWRITE_TAC [ALT_ZERO],
      REWRITE_TAC [ALT_ZERO]
        THEN REWRITE_TAC [MOD_2EXP_ZERO,(GSYM o
               REWRITE_RULE [NUMERAL_DEF]) iMOD_2EXP],
      SIMP_TAC arith_ss [SPEC `iMOD_2EXP x n` BIT1],
      ONCE_REWRITE_TAC [(SYM o REWRITE_CONV [NUMERAL_DEF]) ``1``]
        THEN REWRITE_TAC [ADD1]]);

val iMOD_2EXP = save_thm("iMOD_2EXP",CONJ MOD_2EXP_ZERO iMOD_2EXP);

val NUMERAL_MOD_2EXP = save_thm("NUMERAL_MOD_2EXP",
  SUC_RULE iMOD_2EXP_CLAUSES);

val TIMES_2EXP_lem = prove(
  `!n. FUNPOW iDUB n 1 = 2 ** n`,
  Induct THEN ASM_SIMP_TAC arith_ss
    [EXP,CONJUNCT1 FUNPOW,FUNPOW_SUC,iDUB,GSYM TIMES2]);

val NUMERAL_TIMES_2EXP = store_thm("NUMERAL_TIMES_2EXP",
  `!x n. TIMES_2EXP (NUMERAL x) (NUMERAL n) =
     (NUMERAL n) * NUMERAL (FUNPOW iDUB (NUMERAL x) (BIT1 ZERO))`,
  `BIT1 ZERO = 1` by REWRITE_TAC [NUMERAL_DEF,BIT1,ALT_ZERO]
    THEN POP_ASSUM SUBST1_TAC
    THEN REWRITE_TAC [TIMES_2EXP_def,TIMES_2EXP_lem,NUMERAL_DEF]);

(* ------------------------------------------------------------------------- *)

val iLOG2_def = 
 Definition.new_definition("iLOG2_def", ``iLOG2 n = LOG2 (n + 1)``);

val LOG2_1 = (SIMP_RULE arith_ss [] o SPECL [`1`,`0`]) LOG2_UNIQUE;
val LOG2_BIT2 = (GEN_ALL o SIMP_RULE arith_ss [LEFT_ADD_DISTRIB] o
  ONCE_REWRITE_RULE [DECIDE ``!a b. (a = b) = (2 * a = 2 * b)``] o
  SIMP_RULE arith_ss [] o SPEC `n + 1`) LOG2;
val LOG2_BIT1 = (REWRITE_RULE [DECIDE ``!a. a + 2 + 1 = a + 3``] o
  ONCE_REWRITE_RULE [DECIDE ``!a b. (a = b) = (a + 1 = b + 1)``]) LOG2_BIT2;

val LESS_MULT_MONO_2 = 
  (GEN_ALL o numLib.REDUCE_RULE o INST [`n` |-> `1`] o SPEC_ALL) LESS_MULT_MONO;

val lem = prove(
  `!a b. 2 * (a MOD 2 ** b) < 2 ** (b + 1)`,
  METIS_TAC [MOD_2EXP_LT,ADD1,EXP,LESS_MULT_MONO_2]);

val lem2 = prove(
  `!a b. 2 * (a MOD 2 ** b) + 1 < 2 ** (b + 1)`,
  METIS_TAC [MOD_2EXP_LT,ADD1,EXP,LESS_MULT_MONO_2,
    DECIDE ``a < b ==> 2 * a + 1 < 2 * b``]);

val numeral_ilog2 = store_thm("numeral_ilog2",
  `(iLOG2 ZERO = 0) /\
   (!n. iLOG2 (BIT1 n) = 1 + iLOG2 n) /\
   (!n. iLOG2 (BIT2 n) = 1 + iLOG2 n)`,
  RW_TAC bool_ss [ALT_ZERO,NUMERAL_DEF,BIT1,BIT2,iLOG2_def]
    THEN SIMP_TAC arith_ss [LOG2_1]
    THENL [
      MATCH_MP_TAC ((SIMP_RULE arith_ss [] o
        SPECL [`2 * n + 2`,`LOG2 (n + 1) + 1`]) LOG2_UNIQUE)
        THEN EXISTS_TAC `2 * ((n + 1) MOD 2 ** LOG2 (n + 1))`
        THEN SIMP_TAC arith_ss [LOG2_BIT2,EXP_ADD,lem],
      MATCH_MP_TAC ((SIMP_RULE arith_ss [] o
        SPECL [`2 * n + 3`,`LOG2 (n + 1) + 1`]) LOG2_UNIQUE)
        THEN EXISTS_TAC `2 * ((n + 1) MOD 2 ** LOG2 (n + 1)) + 1`
        THEN SIMP_TAC arith_ss [LOG2_BIT1,EXP_ADD,lem2]]);

val numeral_log2 = store_thm("numeral_log2",
  `(!n. LOG2 (NUMERAL (BIT1 n)) = iLOG2 (iDUB n)) /\
   (!n. LOG2 (NUMERAL (BIT2 n)) = iLOG2 (BIT1 n))`,
  RW_TAC bool_ss [ALT_ZERO,NUMERAL_DEF,BIT1,BIT2,iLOG2_def,numeralTheory.iDUB]
    THEN SIMP_TAC arith_ss []);

(* ------------------------------------------------------------------------- *)

val _ = 
 let open EmitML
 in exportML (!Globals.exportMLPath)
   ("numeral_bits", 
     MLSIG  "type num = numML.num" :: OPEN ["num"] 
     ::
     map (DEFN o PURE_REWRITE_RULE [arithmeticTheory.NUMERAL_DEF])
         [NUMERAL_DIV2,iBITWISE, NUMERAL_BITWISE,
          NUMERAL_MOD_2EXP,iMOD_2EXP, NUMERAL_DIV_2EXP])
 end;

val _ = export_theory();
