# Heuristics
Solving a mixed-integer linear program can be computationally difficult and integer programming is indeed NP-complete problem. Heuristics can be used to obtain feasible solutions and improving them faster than using deterministic algorithms by trading off some accuracy. Also, heuristics are not guaranteed to obtain good solutions. Two heuristics, *relax-and-fix* and *fix-and-optimize*, are covered here. In the literature, they are referred to as *MIP-based heuristics*, a type of metaheuristics. [^Wolsey1998]

## Definitions
In the context of linear programming, *relaxation* means removing integrality constraint from a variable. *Fixing* variable means setting a fixed value for the variable.

## Relax-and-Fix
![](figures/relax-and-fix.png)

The main design decision for relax-and-fix heuristic is choosing which variables will be relaxed. For shelf space allocation model the main options are the integer variables for number of facings $n_{p,s}$ and binary variables for block-shelf allocation $z_{b,s}$, $z_{b,s}^f$ and $z_{b,s}^l$. Testing indicated that relaxation of block-shelf allocation variables is a better choice because the reduction of computational time by all relaxing variables for the number of facings was insignificant.

The block-shelf variables will be relaxed by a subset of blocks at a time. This transforms the original problem into one where all the blocks are not being allocated at the same time but one subset of blocks at a time.

Partitioning set of blocks $B$ into $n$ disjoint subsets $B_1, B_2, ..., B_n$ determines the order in which variables are relaxed. Partitioning affects the runtime and goodness of the heuristic solution. The optimal way to partition is still unknown to us and partitioning policy is a user decision.

!!! example
 For example, $B_1$ could be partition to contain two blocks that are predicted to have most items allocated to the shelves, then partition $B_2$ to contain two blocks that are predicted to have second-most items allocated to the shelves and so forth.

Each iteration, the *relax-and-fix* heuristic solves the original optimization problem such that the block constraints $z_{b,s}, z_{b,s}^f, z_{b,s}^l$ are either fixed, relaxed or binary constrained for a particular block $b$.

* **Fix**: Fix the blocking constraint for the blocks that were fixed or integer constrained in the previous iteration.
* **Binary**: Binary constraint for the next block from the previous iteration
* **Relax**: Relax the binary constraints for rest of the blocks.

The algorithm runs for $n$ iterations and returns a feasible solution. If the model is infeasible at any iteration, it returns infeasible.

## Fix-and-Optimize
!!! note
 Not yet implemented.


## References
[^Wolsey1998]: Wolsey, L. A. (1998). Integer programming. Wiley.
