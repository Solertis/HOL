(* This file has been generated by java2opSem from /home/helen/Recherche/hol/HOL/examples/opsemTools/java2opsem/testFiles/javaFiles/SelectionSort.java*)


open HolKernel Parse boolLib
stringLib IndDefLib IndDefRules
finite_mapTheory relationTheory
newOpsemTheory
computeLib bossLib;

val _ = new_theory "SelectionSort";

(* Method selectionSort*)
val MAIN_def =
  Define `MAIN =
    RSPEC
    (\state.
      T)
      (Seq
        (Assign "i"
          (Const 0)
        )
        (Seq
          (Assign "j"
            (Const 0)
          )
          (Seq
            (Assign "indMin"
              (Const 0)
            )
            (Seq
              (Assign "aux"
                (Const 0)
              )
              (While 
                (Less 
                  (Var "i")
                  (Var "aLength")
                )
                (Seq
                  (Assign "indMin"
                    (Var "i")
                  )
                  (Seq
                    (Assign "j"
                      (Plus 
                        (Var "i")
                        (Const 1)
                      )
                    )
                    (Seq
                      (While 
                        (Less 
                          (Var "j")
                          (Var "aLength")
                        )
                        (Seq
                          (Cond 
                            (Less 
                              (Arr "a"
                                (Var "j")
                              )
                              (Arr "a"
                                (Var "indMin")
                              )
                            )
                            (Assign "indMin"
                              (Var "j")
                            )
                            Skip
                          )
                          (Assign "j"
                            (Plus 
                              (Var "j")
                              (Const 1)
                            )
                          )
                        )
                      )
                      (Seq
                        (Assign "aux"
                          (Arr "a"
                            (Var "i")
                          )
                        )
                        (Seq
                          (ArrayAssign "a"
                            (Var "i")
                            (Arr "a"
                              (Var "indMin")
                            )
                          )
                          (Seq
                            (ArrayAssign "a"
                              (Var "indMin")
                              (Var "aux")
                            )
                            (Assign "i"
                              (Plus 
                                (Var "i")
                                (Const 1)
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    (\state1 state2.
      (!i . (((i>=0)/\(i<Num(ScalarOf (state1 ' "aLength"))-1)))==>(((ArrayOf (state2 ' "a") ' (i))<=(ArrayOf (state2 ' "a") ' (i+1))))))
    `

    val intVar_def =
  	     Define `intVar =["i";"j";"indMin";"aux"]  `

    val arrVar_def =
  	     Define `arrVar =["a"]  `

  val _ = export_theory();
