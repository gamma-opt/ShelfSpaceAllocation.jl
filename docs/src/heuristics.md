# Heuristics
Solving a mixed-integer linear program is computationally hard. Heuristics can be used to obtain feasible solutions and improving them faster than using deterministic algorithms by trading off some accuracy. Two heuristics, *relax-and-fix* and *fix-and-optimize*, are covered here. In the literature, they are referred as *MIP-based heuristics* [^Wolsey1998] or *matheuristics*.

## Relax-and-Fix
![](figures/relax-and-fix.png)

Partition the set of blocks $B$ into $n$ disjoint subsets $B_1, B_2, ..., B_n$. Partitioning affects the runtime and goodness of the heuristic solution. There might be no easy way to do partitioning optimally. As an example of partitioning, we could partition $B_1$ to contain two blocks that we predict to have most items allocated to the shelfs, then $B_2$ to contain two block that will have second most items allocated to the shelfs and so forth.

Each iteration, the *relax-and-fix* heuristic solves the original optimization problem such that the block constraints $z_{b,s}, z_{b,s}^f, z_{b,s}^l$ are either fixed, relaxed or binary constrained for a particular block $b$.

* **Fix**: Fix the block constraint for the blocks that were fixed or integer constrained in the previous iteration.
* **Binary**: Binary constraint for the next block from the previous iteration
* **Relax**: Relax the binary constraints for rest of the blocks.

The algorithm runs for $n$ iterations and returns a feasible solution. If the model is infeasible at any iteration, it returns infeasible.

## Fix-and-Optimize


## References
[^Wolsey1998]: Wolsey, L. A. (1998). Integer programming. Wiley.
