# Model
*Sets and Subsets*

- \(p∈P\) -- Products
- \(s∈S\) -- Shelves
- \(b∈B\) -- Blocks, index of (mutually exclusive) subsets of products
- \(P_b⊆P\) -- Block, subset of products
- \(m∈M\) -- Modules, index of (mutually exclusive) subset of shelves
- \(S_m⊆S\) -- Module, subset of shelves

*Parameters*

- \(G_p\) -- Unit profit of product \(p\); used as shortage penalty (treated to be \(\max\{0, G_p\}\)
- \(R_p\) -- Replenishment period of product \(p\)
- \(D_p\) -- Demand forecast of product \(p\)
- \(P_{p,s}\) -- Number units per facing of product \(p\) on shelf \(s\)
- \(N_p^{min}\), \(N_p^{max}\) -- The minimum and maximum number of facings for product \(p\)
- \(W_p\) -- Facing width of product \(p\)
- \(W_s\) -- Width of shelf \(s\)
- \(M_s^{min}\), \(M_s^{max}\) -- The minimum and maximum unit weight on shelf \(s\)
- \(M_p\) -- Unit weight of product \(p\)
- \(H_s\) -- Height of shelf \(s\)
- \(H_p\) -- Height of product \(p\)

*Variables*

- \(s_p ≥ 0,∀p\) -- Amount of product \(p\)
- \(e_p ≥ 0,∀p\) -- Shortage of product \(p\) (mismatch between demand and on-shelf inventory)
- \(o_s ≥ 0,∀s\) -- Total empty space on shelf \(s\)
- \(n_{p,s} ∈ ℤ_{≥0},∀p,s\) -- Number of facings of product \(p\) on shelf \(s\)

**Objective**:
\[
\text{minimize} ∑_s o_s + ∑_p G_p e_p
\]

1) Minimizes empty shelf space
2) Minimizes lost profit
<!-- 3) Places products at preferred heights \(∑_{p,s} L_p H_s n_{p,s}\) -->

<!-- TODO: multiobjective formulation? f_1, f_2, ... -->
<!-- TODO: normalization?
\[
\text{minimize} \frac{c_1}{φ_1} ∑_s o_s + \frac{c_2}{φ_2} ∑_p G_p e_p,
\]
where \(c_1,c_2≥0\) and \(c_1+c_2=1\) are weight coefficients.
\[
φ_1 = \max ∑_s o_s =  ∑_s W_s \\
φ_2 = \max ∑_p G_p e_p = ∑_p G_p D_p
\]
Minimums for both objectives are \(0\) -->

**Constraints**:

Number of product \(p\) sold must equal to the minimum of the expected sales and demand
\[
s_p = \min\left(∑_s \frac{30}{R_p} P_{p,s} n_{p,s}, D_p\right), ∀p \\
\]

The shortage of product \(p\) is the mismatch between demand and on-shelf inventory
\[
s_p + e_p = D_p, ∀p
\]

The total number of facings of product \(p\) must be withing the bounds
\[
N_p^{min} ≤ ∑_s n_{p,s} ≤ N_p^{max}, ∀p
\]

<!-- \[
\begin{aligned}
y_p ∈ \{0,1\} \\
∑_p n_{p,s} ≥ y_{p}, ∀p \\
\end{aligned}
\] -->

The total width of products and empty space on shelf \(s\) must be equal to the shelf width
\[
∑_p W_p n_{p,s} + o_s = W_s, ∀s
\]

The total weight of the products \(P\) on shelf \(s\) must be within the bounds
\[
M_s^{min} ≤ ∑_p M_p n_{p,s} ≤ M_s^{max}, ∀s
\]

Defines an indicator variable \(y_{p,s}\) which takes value \(1\) if product \(p\) is allocated on shelf \(s\) otherwise \(0\)
\[
\begin{aligned}
& \(y_{p,s} ∈ \{0,1\}\), ∀p,s \\
& n_{p, s} ≤ N_p^{max} y_{p, s}, ∀p,s
\end{aligned}
\]

The height of product \(p\) allocated on shelf \(s\) must be less or equal to the shelf height
\[
y_{p,s} H_p ≤ H_s, ∀p,s
\]

---

TODO: variables

- \(b_{b,s}≥0,∀b,s\)
- \(z_{b,s}∈\{0,1\},∀b,s\)
- \(m_{b,m}≥0,∀b,m\)

\[
W_p n_{p,s} ≤ b_{b,s}, ∀s,b,p∣p∈P_b
\]

\[
∑_b b_{b,s} ≤ W_s, ∀s
\]

\[
\begin{aligned}
b_{b,s} &≥ m_{b,m} - W_s (1 - z_{b,s}) \\
b_{b,s} &≤ m_{b,m} + W_s (1 - z_{b,s}) & ∀b,m,s∣s∈S_m
\end{aligned}
\]

\[
b_{b,s} ≤ W_s z_{b,s}, ∀b,s
\]

---

TODO: variables

- \(z_{b,s}^f∈\{0,1\},∀b,s\)
- \(z_{b,s}^l∈\{0,1\},∀b,s\)

\[
z_{b,s+1}^f + z_{b,s} = z_{b,s+1} + z_{b,s}^l, ∀b,s∣s≤|S|-1
\]

\[
∑_s z_{b,s}^f ≤ 1, ∀b
\]

\[
∑_s z_{b,s}^l ≤ 1, ∀b
\]

\[
z_{b,s}^f = z_{b,s}, ∀b,s=1
\]

\[
z_{b,s}^l = z_{b,s}, ∀b,s=|S|
\]

\[
∑_p n_{p,s} ≥ z_{b,s}, ∀b,s
\]

\[
n_{p,s} ≤ N_p^{max} z_{b,s}, b,p,s∣p∈P_b
\]

---

TODO: variables

- \(x_{b,s}≥0,b,s∣s∈S_m\)
- \(x_{b,m}≥0,∀b,m\)
- \(w_{b,b'}∈\{0,1\},∀b,b'∣b≠b'\)

\[
x_{b,s} ≥ x_{b',s} + b_{b,s} - W_s (1 - w_{b,b'}), ∀b,b',m∣b≠b'
\]

\[
x_{b',s} ≥ x_{b,s} + b_{b,s} - W_s w_{b,b'}, ∀b,b',m∣b≠b'
\]

\[
x_{b,m} ≥ x_{b,s} - W_s (1 - z_{b,s}), ∀b,m,s∣s∈S_m
\]

\[
x_{b,m} ≤ x_{b,s} + W_s (1 - z_{b,s}), ∀b,m,s∣s∈S_m
\]

\[
x_{b,s} ≤ W_s z_{b,s}, ∀b,s
\]

---

TODO: variables

- \(v_{b,m}∈\{0,1\},∀b,m\)

\[
n_{p,s} ≤ N_p^{max} v_{b,m}, ∀p,b,m,s∣s∈S_m,p∈P_b
\]

\[
∑_m v_{b,m} ≤ 1, ∀b
\]


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
