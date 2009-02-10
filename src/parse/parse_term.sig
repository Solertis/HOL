signature parse_term = sig
    type 'a PStack
    type 'a qbuf= 'a qbuf.qbuf
    type stack_terminal = term_grammar.stack_terminal
    val initial_pstack : 'a PStack
    val is_final_pstack : 'a PStack -> bool
    val top_nonterminal : Term.term PStack -> Absyn.absyn

    exception PrecConflict of stack_terminal * stack_terminal
    exception ParseTermError of string locn.located

    (* not used anywhere, but can be useful for debugging *)
    val mk_prec_matrix :
        term_grammar.grammar ->
        ((stack_terminal * bool) * stack_terminal, order) Binarymap.dict ref

    val parse_term :
      term_grammar.grammar ->
      (''a qbuf -> Pretype.pretype) ->
      (''a qbuf * ''a PStack) ->
      (''a qbuf * ''a PStack) * unit option

end

