# Model
TODO: parameters and variables

**Objective**: Minimize
\[
∑_s o_s + ∑_p G_p e_p + ∑_{p,s} L_p H_s n_{p,s}
\]

1) Minimizes empty shelf space
2) Minimizes lost profit
3) Places products at preferred heights

**Constraints**: Subject to
\[
\begin{aligned}
& s_p = \min\left(∑_s \frac{30}{R_p} P_{p,s} n_{p,s}, D_p\right) \\
& s_p + e_p = D_p
\end{aligned}
\]

\[
N_p^{min} ≤ ∑_s n_{p,s} ≤ N_p^{max}
\]

\[
y_p ∈ \{0,1\} \\
∑_p n_{p,s} ≥ y_{p} \\
\]

\[
∑_p W_p n_{p,s} + o_s = W_s
\]

The total weight of the products \(P\) on shelf \(s\) should be within the given bounds.
\[
M_s^{min} ≤ ∑_p M_p n_{p,s} ≤ M_s^{max}
\]

Product \(p\) allocated on shelf \(s\) is has height \(H_p\) less than the shelf height \(H_s\).

- \(y_{p,s} ∈ \{0,1\}\) -- \(1\) if product \(p\) is allocated on shelf \(s\) otherwise \(0\)

\[
n_{p, s} ≤ N_p^{max} y_{p, s} \\
y_{p,s} H_p ≤ H_s
\]

---


## Linearization
The constraint $$z=\min{x, y}$$

This can be implemented in a MIP model using a big-$M$ formulation
$$
\begin{align}
 &z \le x\\
 &z \le y\\
 &z \ge x - M\delta\\
 &z \ge y - M(1-\delta)\\
 &\delta \in \{0,1\}
\end{align}
$$
where $M$ is a large enough constant.

https://math.stackexchange.com/a/2564713/351414

---

$$M≥\max(x, y)$$

---

\[
\begin{aligned}
z &= s_p \\
x &= ∑_s \frac{30}{R_p} P_{ps} n_{ps} \\
y &= D_p
\end{aligned}
\]

Upper bound for \(x\)
\[
\begin{aligned}
x &= ∑_s c_{ps} n_{ps}, c_{ps}=\frac{30}{R_p} P_{ps} \\
&≤ ∑_s \bar{c}_p n_{ps}, \bar{c}_p=\max_s c_{ps} \\
&= \bar{c}_p ∑_s n_{ps}, ∑_s n_{ps} ≤ \bar{N}_p \\
&≤ \bar{c}_p \bar{N}_p
\end{aligned}
\]

Then
\[
M_p ≥ \max(\bar{c}_p \bar{N}_p, D_p) ≥ \max(x, y)
\]
