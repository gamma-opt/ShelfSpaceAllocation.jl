# Library
## Model
```@docs
ssap_model
```

*Sets and Subsets*

-  $p∈P$ -- A set of **products**.
-  $s∈S$ -- A set of **shelves**.
-  $b∈B$ -- A set of **blocks**. Blocks are an index of mutually exclusive subsets of products.
-  $P_b⊆P$ -- A **block** is a subset of products.
-  $m∈M$ -- A set of **modules**. Modules are an index of a mutually exclusive subset of shelves.
-  $S_m⊆S$ -- A **module** is a subset of shelves.

*Parameters*

-  $N_p^{min}$, $N_p^{max}$ -- The minimum and maximum number of facings for product $p$
-  $G_p$ -- Unit profit of product $p$; used as shortage penalty (treated to be $\max\{0, G_p\}$
-  $R_p$ -- Replenishment period of product $p$
-  $D_p$ -- Demand forecast of product $p$
-  $L_p$ -- Priority weight for height placement of product $p$
-  $W_p$ -- Facing width of product $p$
-  $H_p$ -- Height of product $p$
-  $M_p$ -- Unit weight of product $p$
-  $P_{p,s}$ -- Number units per facing of product $p$ on shelf $s$
-  $M_s^{min}$, $M_s^{max}$ -- The minimum and maximum unit weight on shelf $s$
-  $W_s$ -- Width of shelf $s$
-  $H_s$ -- Height of shelf $s$
-  $SL$ -- Slack, maximum difference in block starting points and between block max and min width

*Objective*

$$\min \left(w_1 ∑_s o_s + w_2 ∑_p G_p e_p + w_3 ∑_{p,s} L_p L_s n_{p,s}\right)$$

-  $w_1=0.5$
-  $w_2=10.0$
-  $w_3=0.1$

*Basic Variables*

-  $n_{p,s}$ -- Number of facings of product $p$ on shelf $s$
-  $s_p$ -- Amount of product $p$ sold
-  $e_p$ -- Shortage of product $p$ (mismatch between demand and on-shelf inventory)
-  $o_p$ -- Total empty space on shelf $s$
-  $y_p$ -- $1$ if product is assigned to module $m$, $0$ otherwise

*Basic Constraints*

$$\begin{aligned}
& n_{p,s} ∈ ℤ_{≥0}, & ∀p,s \\
& y_p ∈ \{0,1\}, & ∀p \\
& s_p ≥ 0, & ∀p \\
& e_p ≥ 0, & ∀p \\
& o_s ≥ 0, & ∀s \\
& \\
& n_{p,s}=0, & ∀p,s∣H_p > H_s \\
& n_{p,s}=0, & ∀p,s∣M_p > M_s^{max} \\
& ∑_p n_{p,s} ≥ y_{p}, & ∀p \\
& N_p^{min} y_p ≤ ∑_s n_{p,s} ≤ N_p^{max} y_p, & ∀p \\
& s_p ≤ \min\left(∑_s \frac{30}{R_p} P_{p,s} n_{p,s}, D_p\right), & ∀p \\
& s_p + e_p = D_p, & ∀p \\
& ∑_p W_p n_{p,s} + o_s = W_s, & ∀s \\
\end{aligned}$$

*Block Variables*

-  $z_{b,s}$ -- $1$ if block is assigned on shelf $s$, otherwise $0$
-  $z_{b,s}^f$ -- $1$ if shelf $s$ is the first shelf of block $b$, otherwise $0$
-  $z_{b,s}^l$ -- $1$ if shelf $s$ is the last shelf of block $b$, otherwise $0$
-  $b_{b,s}$ -- Width of block $b$ on shelf $s$
-  $m_{b,m}$ -- Block width on module
-  $v_{b,m}$ -- $1$ if block is assigned to module $m$, otherwise $0$
-  $x_{b,s}$ -- Block starting location on shelf $s$
-  $x_{b,m}$ -- Block starting location on module $m$
-  $w_{b,b'}$ -- $1$ if block $b$ precedes block $b'$, otherwise $0$

*Block Constraints*

$$\begin{aligned}
& b_{b,s}≥0, & ∀b,s \\
& z_{b,s}∈\{0,1\}, & ∀b,s \\
& m_{b,m}≥0, & ∀b,m \\
& z_{b,s}^f∈\{0,1\}, & ∀b,s \\
& z_{b,s}^l∈\{0,1\}, & ∀b,s \\
& x_{b,s}≥0, & ∀b,s \\
& x_{b,m}≥0, & ∀b,m \\
& w_{b,b'}∈\{0,1\}, & ∀b,b' \\
& v_{b,m}∈\{0,1\}, & ∀b,m \\
& \\
& ∑_{p∈P_b} W_p n_{p,s} ≤ b_{b,s}, & ∀s,b \\
& ∑_b b_{b,s} ≤ W_s, & ∀s \\
& b_{b,s} ≤ W_s z_{b,s}, & ∀b,s \\
& b_{b,s} ≥ m_{b,m} - W_s (1 - z_{b,s}) - SL, & ∀b,m,s∣s∈S_m \\
& b_{b,s} ≤ m_{b,m} + W_s (1 - z_{b,s}) + SL, & ∀b,m,s∣s∈S_m \\
& \\
& ∑_s z_{b,s}^f ≤ 1, & ∀b \\
& ∑_s z_{b,s}^l ≤ 1, & ∀b \\
& z_{b,s}^f = z_{b,s}, & ∀b,s=1 \\
& z_{b,s}^l = z_{b,s}, & ∀b,s=|S| \\
& z_{b,s+1}^f + z_{b,s} = z_{b,s+1} + z_{b,s}^l, & ∀b,s∣s≤|S|-1 \\
& \\
& ∑_{p∈P_b} n_{p,s} ≥ z_{b,s}, & ∀b,s \\
& n_{p,s} ≤ N_p^{max} z_{b,s}, & ∀b,p,s∣p∈P_b \\
& \\
& x_{b,s} ≤ W_s z_{b,s}, & ∀b,s \\
& x_{b,s} + b_{b,s} ≤ W_s, & ∀b,s \\
& x_{b,s} + W_s (1 - z_{b,s}) ≥ x_{b',s} + b_{b,s} - W_s (1 - w_{b,b'}), & ∀b,b',m∣b≠b' \\
& x_{b',s} + W_s (1 - z_{b', s}) ≥ x_{b,s} + b_{b,s} - W_s w_{b,b'}, & ∀b,b',m∣b≠b' \\
& x_{b,m} ≥ x_{b,s} - W_s (1 - z_{b,s}) - SL, & ∀b,m,s∣s∈S_m \\
& x_{b,m} ≤ x_{b,s} + W_s (1 - z_{b,s}) + SL, & ∀b,m,s∣s∈S_m \\
& \\
& n_{p,s} ≤ N_p^{max} v_{b,m}, & ∀p,b,m,s∣s∈S_m,p∈P_b \\
& ∑_m v_{b,m} ≤ 1, & ∀b
\end{aligned}$$


## IO
```@docs
load_parameters
save
extract_variables
extract_objectives
```

## Plotting
```@docs
planogram
product_facings
block_allocation
demand_and_sales
fill_amount
fill_percentage
```
