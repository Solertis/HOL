signature bitLib =
sig
    include Abbrev

    val BITS_CONV : conv
    val BITS_TAC  : tactic

    val bits_compset : unit -> computeLib.compset
end
