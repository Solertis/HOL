(*****************************************************************************)
(* Definitions from LRM B.3 "Syntactic sugaring"                             *)
(*****************************************************************************)

(*****************************************************************************)
(* START BOILERPLATE                                                         *)
(*****************************************************************************)

(*
quietdec := true;
loadPath := "../official-semantics" :: !loadPath;
map load ["intLib","stringLib","stringTheory","SyntaxTheory"];
open intLib stringLib stringTheory SyntaxTheory;
val _ = intLib.deprecate_int();
quietdec := false;
*)

(******************************************************************************
* Boilerplate needed for compilation
******************************************************************************)
open HolKernel Parse boolLib bossLib;

(******************************************************************************
* Open theories
******************************************************************************)
open intLib stringLib stringTheory SyntaxTheory;

(******************************************************************************
* Set default parsing to natural numbers rather than integers
******************************************************************************)
val _ = intLib.deprecate_int();

(*****************************************************************************)
(* END BOILERPLATE                                                           *)
(*****************************************************************************)

(******************************************************************************
* Start a new theory called SyntacticSugarTheory
******************************************************************************)
val _ = new_theory "SyntacticSugar";

(******************************************************************************
* Ensure term_of_int has correct type
* (i.e. not  int/1 -> term)
******************************************************************************)
val term_of_int = numLib.term_of_int;

(******************************************************************************
* pureDefine doesn't export definitions to theCompset (for EVAL).
******************************************************************************)
val pureDefine = with_flag (computeLib.auto_import_definitions, false) Define;

(******************************************************************************
* Additional boolean operators
******************************************************************************)

(******************************************************************************
* Definition of disjunction
******************************************************************************)

val B_OR_def =
 pureDefine `B_OR(b1,b2) = B_NOT(B_AND(B_NOT b1, B_NOT b2))`;

(******************************************************************************
* Definition of implication
******************************************************************************)

val B_IMP_def =
 pureDefine `B_IMP(b1,b2) = B_OR(B_NOT b1, b2)`;

(******************************************************************************
* Definition of logical equivalence
******************************************************************************)

val B_IFF_def =
 pureDefine `B_IFF(b1,b2) = B_AND(B_IMP(b1, b2),B_IMP(b2, b1))`;

(******************************************************************************
* Definition of truth
******************************************************************************)

val B_TRUE_def =
 pureDefine `B_TRUE = B_OR(B_PROP ARB, B_NOT(B_PROP ARB))`;

(******************************************************************************
* Definition of falsity
******************************************************************************)

val B_FALSE_def =
 pureDefine `B_FALSE = B_NOT B_TRUE`;

(******************************************************************************
* Additional SERE operators
******************************************************************************)

(******************************************************************************
* SERE versions of T and F
******************************************************************************)

val S_TRUE_def  = Define `S_TRUE  = S_BOOL B_TRUE`
and S_FALSE_def = Define `S_FALSE = S_BOOL B_FALSE`;

(******************************************************************************
* {r1} & {r2} = {{r1} && {r2;T[*]}} | {{r1;T[*]} && {r2}}
******************************************************************************)
val S_FLEX_AND_def =
 Define
  `S_FLEX_AND(r1,r2) =
    S_OR
     (S_AND(r1,S_CAT(r2, S_REPEAT S_TRUE)),
      S_AND(S_CAT(r1,S_REPEAT S_TRUE), r2))`;

(******************************************************************************
*         |  F[*]                  if i = 0
* r[*i] = <
*         |  r;r;...;r (i times)   otherwise
******************************************************************************)
val S_REPEAT_ITER_def =
 Define
  `S_REPEAT_ITER r i =
    if i=0 then S_REPEAT(S_BOOL B_FALSE)
           else if i=1 then r else S_CAT(r, S_REPEAT_ITER r (i-1))`;

(******************************************************************************
* RANGE_ITER(i, j) op f = (f i) op (f(i+1)) op ... op (f j)
******************************************************************************)

(******************************************************************************
* RANGE_ITER_AUX op f i n = (f i) op (f(i+1)) op ... op (f n)
******************************************************************************)
val RANGE_ITER_AUX_def =
 Define
  `(RANGE_ITER_AUX op f i 0 = f i)
   /\
   (RANGE_ITER_AUX op f i (SUC n) = op(f i, RANGE_ITER_AUX op f (i+1) n))`;

(******************************************************************************
* Prove if-then-else form needed by computeLib
******************************************************************************)
val RANGE_ITER_AUX =
 prove
  (``RANGE_ITER_AUX op f i n =
      if n=0 then f i
             else op(f i, RANGE_ITER_AUX op f (i+1) (n-1))``,
   Cases_on `n` THEN RW_TAC arith_ss [RANGE_ITER_AUX_def]);

val _ = computeLib.add_funs[RANGE_ITER_AUX];

val RANGE_ITER_def =
 Define `RANGE_ITER(i, j) op f = RANGE_ITER_AUX op f i (j-i)`;

(******************************************************************************
* S_RANGE_REPEAT(r, (i,j)) = r[*i..j] = {r[*i]} | {r[*(i+1)]} | ... | {r[*j]}
******************************************************************************)
val S_RANGE_REPEAT_def =
 Define
  `(S_RANGE_REPEAT(r, (i, SOME j)) = RANGE_ITER(i, j) S_OR (S_REPEAT_ITER r))
   /\
   (S_RANGE_REPEAT(r, (i, NONE)) = S_CAT(S_REPEAT_ITER r i, S_REPEAT r))`;

(******************************************************************************
* r[+] = r;r[*]
******************************************************************************)
val S_NON_ZERO_REPEAT_def =
 Define `S_NON_ZERO_REPEAT r = S_CAT(r, S_REPEAT r)`;

(******************************************************************************
* b[=i] = {!b[*];b}[*i];!b[*]
******************************************************************************)
val S_EQ_REPEAT_ITER_def =
 Define
  `S_EQ_REPEAT_ITER b i =
    S_CAT
     (S_REPEAT_ITER (S_CAT(S_REPEAT(S_BOOL(B_NOT b)),S_BOOL b)) i,
      S_REPEAT(S_BOOL(B_NOT b)))`;

(******************************************************************************
* S_RANGE_EQ_REPEAT(b, (i,j)) =
*  b[=i..j] = {b[=i]} | {b[*=i+1)]} | ... | {b[=j]}
******************************************************************************)
val S_RANGE_EQ_REPEAT_def =
 Define
  `(S_RANGE_EQ_REPEAT(b, (i, SOME j)) =
     RANGE_ITER(i, j) S_OR (S_EQ_REPEAT_ITER b))
   /\
   (S_RANGE_EQ_REPEAT(b, (i, NONE)) =
     S_CAT(S_EQ_REPEAT_ITER b i, S_REPEAT S_TRUE))`;

(******************************************************************************
* b[->i] = {!b[*];b}[*i]
******************************************************************************)
val S_GOTO_REPEAT_ITER_def =
 Define
  `S_GOTO_REPEAT_ITER b =
    S_REPEAT_ITER (S_CAT(S_REPEAT(S_BOOL(B_NOT b)),S_BOOL b))`;

(******************************************************************************
* S_RANGE_GOTO_REPEAT(b, (i,j)) =
*  b[=i..j] = {b[=i]} | {b[*=i+1)]} | ... | {b[=j]}
******************************************************************************)
val S_RANGE_GOTO_REPEAT_def =
 Define
  `(S_RANGE_GOTO_REPEAT(b, (i, SOME j)) =
     RANGE_ITER(i, j) S_OR (S_GOTO_REPEAT_ITER b))
   /\
   (S_RANGE_GOTO_REPEAT(b, (i, NONE)) = S_GOTO_REPEAT_ITER b i)`;

(******************************************************************************
* Formula disjunction: f1 \/ f2
******************************************************************************)
val F_OR_def =
 Define
  `F_OR(f1,f2) = F_NOT(F_AND(F_NOT f1, F_NOT f2))`;

(******************************************************************************
* Formula implication: f1 --> f2
******************************************************************************)
val F_IMPLIES_def =
 Define
  `F_IMPLIES(f1,f2) = F_OR(F_NOT f1, f2)`;

(******************************************************************************
* Formula implication: f1 --> f2
* (alternative definition to match ML datatype)
******************************************************************************)
val F_IMP_def =
 Define
  `F_IMP = F_IMPLIES`;

(******************************************************************************
* Formula equivalence: f1 <--> f2
******************************************************************************)
val F_IFF_def =
 Define
  `F_IFF(f1,f2) = F_AND(F_IMPLIES(f1, f2), F_IMPLIES(f2, f1))`;

(******************************************************************************
* Weak next: X f
******************************************************************************)
val F_WEAK_X_def =
 Define
  `F_WEAK_X f = F_NOT(F_NEXT(F_NOT f))`;

(******************************************************************************
* Eventually: F f
******************************************************************************)
val F_F_def =
 Define
  `F_F f = F_UNTIL(F_BOOL B_TRUE, f)`;

(******************************************************************************
* Always: G f
******************************************************************************)
val F_G_def =
 Define
  `F_G f = F_NOT(F_F(F_NOT f))`;

(******************************************************************************
* Weak until: [f1 W f2]
******************************************************************************)
val F_W_def =
 Define
  `F_W(f1,f2) = F_OR(F_UNTIL(f1,f2), F_G f1)`;

(******************************************************************************
* always f
******************************************************************************)
val F_ALWAYS_def =
 Define
  `F_ALWAYS = F_G`;

(******************************************************************************
* never f
******************************************************************************)
val F_NEVER_def =
 Define
  `F_NEVER f = F_G(F_NOT f)`;

(******************************************************************************
* Strong next: next! f
******************************************************************************)
val F_STRONG_NEXT_def =
 Define
  `F_STRONG_NEXT f = F_NEXT f`;

(******************************************************************************
* Weak next: next f
******************************************************************************)
val F_WEAK_NEXT_def =
 Define
  `F_WEAK_NEXT = F_WEAK_X`;

(******************************************************************************
* eventually! f
******************************************************************************)
val F_STRONG_EVENTUALLY_def =
 Define
  `F_STRONG_EVENTUALLY = F_F`;

(******************************************************************************
* f1 until! f2
******************************************************************************)
val F_STRONG_UNTIL_def =
 Define
  `F_STRONG_UNTIL = F_UNTIL`;

(******************************************************************************
* f1 until f2
******************************************************************************)
val F_WEAK_UNTIL_def =
 Define
  `F_WEAK_UNTIL = F_W`;

(******************************************************************************
* f1 until!_ f2
******************************************************************************)
val F_STRONG_UNTIL_INC_def =
 Define
  `F_STRONG_UNTIL_INC(f1,f2) = F_UNTIL(f1, F_AND(f1,f2))`;

(******************************************************************************
* f1 until_ f2
******************************************************************************)
val F_WEAK_UNTIL_INC_def =
 Define
  `F_WEAK_UNTIL_INC(f1,f2) = F_W(f1, F_AND(f1,f2))`;

(******************************************************************************
* f1 before! f2
******************************************************************************)
val F_STRONG_BEFORE_def =
 Define
  `F_STRONG_BEFORE(f1,f2) = F_UNTIL(F_NOT f2, F_AND(f1, F_NOT f2))`;

(******************************************************************************
* f1 before f2
******************************************************************************)
val F_WEAK_BEFORE_def =
 Define
  `F_WEAK_BEFORE(f1,f2) = F_W(F_NOT f2, F_AND(f1, F_NOT f2))`;

(******************************************************************************
* f1 before!_ f2
******************************************************************************)
val F_STRONG_BEFORE_INC_def =
 Define
  `F_STRONG_BEFORE_INC(f1,f2) = F_UNTIL(F_NOT f2, f1)`;

(******************************************************************************
* f1 before_ f2
******************************************************************************)
val F_WEAK_BEFORE_INC_def =
 Define
  `F_WEAK_BEFORE_INC(f1,f2) = F_W(F_NOT f2, f1)`;

(******************************************************************************
*          |  f                        if i = 0
* X![i]f = <
*          |  X! X! ... X! (i times)   otherwise
******************************************************************************)
val F_NUM_STRONG_X_def =
 Define
  `F_NUM_STRONG_X(i,f) = FUNPOW F_NEXT i f`;

(******************************************************************************
*         |  f                     if i = 0
* X[i]f = <
*         |  X X ... X (i times)   otherwise
*
* Note double-negation redundancy:
* EVAL ``F_NUM_WEAK_X(2,f)``;
* > val it =
*     |- F_NUM_WEAK_X (2,f) =
*        F_NOT (F_NEXT (F_NOT (F_NOT (F_NEXT (F_NOT f))))) : thm
*
******************************************************************************)
val F_NUM_WEAK_X_def =
 Define
  `F_NUM_WEAK_X(i,f) = FUNPOW F_WEAK_X i f`;

(******************************************************************************
* next![i] f = X! [i] f
******************************************************************************)
val F_NUM_STRONG_NEXT_def =
 Define
  `F_NUM_STRONG_NEXT = F_NUM_STRONG_X`;

(******************************************************************************
* next[i] f = X [i] f
******************************************************************************)
val F_NUM_WEAK_NEXT_def =
 Define
  `F_NUM_WEAK_NEXT = F_NUM_WEAK_X`;

(******************************************************************************
* next_a![i..j]f = X![i]f /\ ... /\ X![j]f
******************************************************************************)
val F_NUM_STRONG_NEXT_A_def =
 Define
  `F_NUM_STRONG_NEXT_A((i, SOME j),f) =
    RANGE_ITER (i,j) $F_AND (\n. F_NUM_STRONG_X(n,f))`;

(******************************************************************************
* next_a[i..j]f = X[i]f /\ ... /\ X[j]f
******************************************************************************)
val F_NUM_WEAK_NEXT_A_def =
 Define
  `F_NUM_WEAK_NEXT_A((i, SOME j),f) =
    RANGE_ITER (i,j) $F_AND (\n. F_NUM_WEAK_X(n,f))`;

(******************************************************************************
* next_e![i..j]f = X![i]f \/ ... \/ X![j]f
******************************************************************************)
val F_NUM_STRONG_NEXT_E_def =
 Define
  `F_NUM_STRONG_NEXT_E((i, SOME j),f) =
    RANGE_ITER (i,j) $F_OR (\n. F_NUM_STRONG_X(n,f))`;

(******************************************************************************
* next_e[i..j]f = X[i]f \/ ... \/ X[j]f
******************************************************************************)
val F_NUM_WEAK_NEXT_E_def =
 Define
  `F_NUM_WEAK_NEXT_E((i, SOME j),f) =
    RANGE_ITER (i,j) $F_OR (\n. F_NUM_WEAK_X(n,f))`;

(******************************************************************************
* next_event!(b)(f) = [!b U (b & f)]
******************************************************************************)
val F_STRONG_NEXT_EVENT_def =
 Define
  `F_STRONG_NEXT_EVENT(b,f) =
    F_UNTIL(F_BOOL(B_NOT b), F_AND(F_BOOL b, f))`;

(******************************************************************************
* next_event(b)(f) = [!b W (b & f)]
******************************************************************************)
val F_WEAK_NEXT_EVENT_def =
 Define
  `F_WEAK_NEXT_EVENT(b,f) =
    F_W(F_BOOL(B_NOT b), F_AND(F_BOOL b, f))`;

(******************************************************************************
* next_event!(b)[k](f) = next_event!
*                         (b)
*                         (X! next_event!(b) ... (X! next_event!(b)(f)) ... )
*                          |---------------- k-1 times ----------------|
******************************************************************************)
val F_NUM_STRONG_NEXT_EVENT_def =
 Define
  `F_NUM_STRONG_NEXT_EVENT(b,k,f) =
    F_STRONG_NEXT_EVENT
     (b, FUNPOW (\f. F_NEXT(F_STRONG_NEXT_EVENT(b,f))) (k-1) f)`;

(******************************************************************************
* next_event(b)[k](f) = next_event
*                         (b)
*                         (X next_event(b) ... (X next_event(b)(f)) ... )
*                          |-------------- k-1 times --------------|
******************************************************************************)
val F_NUM_WEAK_NEXT_EVENT_def =
 Define
  `F_NUM_WEAK_NEXT_EVENT(b,k,f) =
    F_WEAK_NEXT_EVENT
     (b, FUNPOW (\f. F_NEXT(F_WEAK_NEXT_EVENT(b,f))) (k-1) f)`;

(******************************************************************************
* next_event_a!(b)[k..l](f) =
*  next_event! (b) [k] (f) /\ ... /\ next_event! (b) [l] (f)
******************************************************************************)
val F_NUM_STRONG_NEXT_EVENT_A_def =
 Define
  `F_NUM_STRONG_NEXT_EVENT_A(b,(k,SOME l),f) =
    RANGE_ITER (k,l) $F_AND (\n. F_NUM_STRONG_NEXT_EVENT(b,n,f))`;

(******************************************************************************
* next_event_a(b)[k..l](f) =
*  next_event (b) [k] (f) /\ ... /\ next_event (b) [l] (f)
******************************************************************************)
val F_NUM_WEAK_NEXT_EVENT_A_def =
 Define
  `F_NUM_WEAK_NEXT_EVENT_A(b,(k,SOME l),f) =
    RANGE_ITER (k,l) $F_AND (\n. F_NUM_WEAK_NEXT_EVENT(b,n,f))`;

(******************************************************************************
* next_event_e!(b)[k..l](f) =
*  next_event! (b) [k] (f) \/ ... \/ next_event! (b) [l] (f)
******************************************************************************)
val F_NUM_STRONG_NEXT_EVENT_E_def =
 Define
  `F_NUM_STRONG_NEXT_EVENT_E(b,(k,SOME l),f) =
    RANGE_ITER (k,l) $F_OR (\n. F_NUM_STRONG_NEXT_EVENT(b,n,f))`;

(******************************************************************************
* next_event_a(b)[k..l](f) =
*  next_event (b) [k] (f) \/ ... \/ next_event (b) [l] (f)
******************************************************************************)
val F_NUM_WEAK_NEXT_EVENT_E_def =
 Define
  `F_NUM_WEAK_NEXT_EVENT_E(b,(k,SOME l),f) =
    RANGE_ITER (k,l) $F_OR (\n. F_NUM_WEAK_NEXT_EVENT(b,n,f))`;

(******************************************************************************
* {r1} |=> {r2}! = {r1} |-> {T;r2}!
******************************************************************************)
val F_SKIP_STRONG_IMP_def =
 Define
  `F_SKIP_STRONG_IMP(r1,r2) = F_STRONG_IMP(r1, S_CAT(S_TRUE, r2))`;

(******************************************************************************
* {r1} |=> {r2} = {r1} |-> {T;r2}
******************************************************************************)
val F_SKIP_WEAK_IMP_def =
 Define
  `F_SKIP_WEAK_IMP(r1,r2) = F_WEAK_IMP(r1, S_CAT(S_TRUE, r2))`;

(******************************************************************************
* always{r} = {T[*]} |-> {r}
******************************************************************************)
val F_SERE_ALWAYS_def =
 Define
  `F_SERE_ALWAYS r = F_WEAK_IMP(S_REPEAT S_TRUE, r)`;

(******************************************************************************
* never{r} = {T[*];r} |-> {F}
******************************************************************************)
val F_SERE_NEVER_def =
 Define
  `F_SERE_NEVER r = F_WEAK_IMP(S_CAT(S_REPEAT S_TRUE, r), S_FALSE) `;

(******************************************************************************
* eventually! {r} = {T} |-> {T[*];r}!
******************************************************************************)
val F_SERE_STRONG_EVENTUALLY_def =
 Define
  `F_SERE_STRONG_EVENTUALLY r =
    F_STRONG_IMP(S_TRUE, S_CAT(S_REPEAT S_TRUE, r))`;

(******************************************************************************
* within!(r1,b){r2} = {r1} |-> {r2&&b[=0];b}!
******************************************************************************)
val F_STRONG_WITHIN_def =
 Define
  `F_STRONG_WITHIN (r1,b,r2) =
    F_STRONG_IMP(r1, S_CAT(S_AND(r2, S_EQ_REPEAT_ITER b 0), S_BOOL b))`;

(******************************************************************************
* within(r1,b){r2} = {r1} |-> {r2&&b[=0];b}
******************************************************************************)
val F_WEAK_WITHIN_def =
 Define
  `F_WEAK_WITHIN (r1,b,r2) =
    F_WEAK_IMP(r1, S_CAT(S_AND(r2, S_EQ_REPEAT_ITER b 0), S_BOOL b))`;

(******************************************************************************
* within!_(r1,b){r2} = {r1} |-> {r2&&{b[=0];b}}!
******************************************************************************)
val F_STRONG_WITHIN_INC_def =
 Define
  `F_STRONG_WITHIN_INC (r1,b,r2) =
    F_STRONG_IMP(r1, S_AND(r2, S_CAT(S_EQ_REPEAT_ITER b 0, S_BOOL b)))`;

(******************************************************************************
* within_(r1,b){r2} = {r1} |-> {r2&&{b[=0];b}}
******************************************************************************)
val F_WEAK_WITHIN_INC_def =
 Define
  `F_WEAK_WITHIN_INC (r1,b,r2) =
    F_WEAK_IMP(r1, S_AND(r2, S_CAT(S_EQ_REPEAT_ITER b 0, S_BOOL b)))`;

(******************************************************************************
* within(r1,b){r2} = {r1} |-> {r2&&b[=0];b}
******************************************************************************)
val F_WEAK_WITHIN_def =
 Define
  `F_WEAK_WITHIN (r1,b,r2) =
    F_WEAK_IMP(r1, S_CAT(S_AND(r2, S_EQ_REPEAT_ITER b 0), S_BOOL b))`;

(******************************************************************************
* whilenot!(b){r} = within!(T,b){r}
******************************************************************************)
val F_STRONG_WHILENOT_def =
 Define
  `F_STRONG_WHILENOT (b,r) =  F_STRONG_WITHIN(S_TRUE,b,r)`;

(******************************************************************************
* whilenot(b){r} = within(T,b){r}
******************************************************************************)
val F_WEAK_WHILENOT_def =
 Define
  `F_WEAK_WHILENOT (b,r) =  F_WEAK_WITHIN(S_TRUE,b,r)`;

(******************************************************************************
* whilenot!_(b){r} = within!_(T,b){r}
******************************************************************************)
val F_STRONG_WHILENOT_INC_def =
 Define
  `F_STRONG_WHILENOT_INC (b,r) =  F_STRONG_WITHIN_INC(S_TRUE,b,r)`;

(******************************************************************************
* whilenot_(b){r} = within_(T,b){r}
******************************************************************************)
val F_WEAK_WHILENOT_INC_def =
 Define
  `F_WEAK_WHILENOT_INC (b,r) =  F_WEAK_WITHIN_INC(S_TRUE,b,r)`;

(******************************************************************************
* Define weak clocking: f@clk = !(!f)@clk)
******************************************************************************)
val F_WEAK_CLOCK_def =
 Define
  `F_WEAK_CLOCK(f,clk) = F_NOT(F_STRONG_CLOCK(F_NOT f, clk))`;

val _ = export_theory();
