/-
Copyright (c) 2020 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison.
-/
import algebra.star.algebra
import algebra.algebra.ordered
import analysis.special_functions.pow

/-!
# The Clauser-Horne-Shimony-Holt inequality.

We establish a version of the Clauser-Horne-Shimony-Holt (CHSH) inequality
(which is a generalization of Bell's inequality).
This is a foundational result which implies that
quantum mechanics is not a local hidden variable theory.

As usually stated the CHSH ienquality requires substantial language from physics and probability,
but it is possible to give a statement that is purely about ordered *-algebras.
We do that here, to avoid as many practical and logical dependencies as possible.
Since the algebra of observables of any quantum system is an ordered *-algebra
(in particular a von Neumann algebra) this is a strict generalization of the usual statement.

Let `R` be a *-ring.

A CHSH tuple in `R` consists of
* four elements `A₀ A₁ B₀ B₁ : R`, such that
* each `Aᵢ` and `Bⱼ` is a self-adjoint involution, and
* the `Aᵢ` commute with the `Bⱼ`.

(The physical interpretation is that the four elements are observables (hence self-adjoint)
that take values ±1 (hence involutions), and that the `Aᵢ` are spacelike separated from the `Bⱼ`
(and hence commute).)

The CHSH inequality says that when `R` is an ordered *-ring
(that is, a *-ring which is ordered, and for every `r : R`, `0 ≤ star r * r`),
which is moreover *commutative*, we have
`A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁ ≤ 2`

On the other hand, Tsirelson's inequality says that for any ordered *-ring we have
`A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁ ≤ 2√2`

(A caveat: in the commutative case we need 2⁻¹ in the ring,
and in the noncommutative case we need √2 and √2⁻¹.
To keep things simple we just assume our rings are ℝ-algebras.)

The proofs I've seen in the literature either
assume a significant framework for quantum mechanices,
or assume the ring is a C*-algebra.
In the C*-algebra case, the order structure is completely determined by the *-algebra structure:
`0 ≤ A` iff there exists some `B` so `A = star B * B`.
There's a nice proof of both bounds in this setting at
https://en.wikipedia.org/wiki/Tsirelson%27s_bound
The proof given here is purely algebraic.

## Future work

One can show that Tsirelson's inequality is tight.
In the *-ring of n-by-n complex matrices, if `A ≤ λ I` for some `λ : ℝ`,
then every eigenvalue has absolute value at most `λ`.
There is a CHSH tuple in 4-by-4 matrices such that
`A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁` has `2√2` as an eigenvalue.

## References

* J.F. Clauser; M.A. Horne; A. Shimony; R.A. Holt (1969),
  "Proposed experiment to test local hidden-variable theories",
  Phys. Rev. Lett., 23 (15): 880–4, doi:10.1103/PhysRevLett.23.880
* J.S. Bell (1964), "On the Einstein Podolsky Rosen Paradox",
  Physics Physique Физика, 1 (3): 195–200, doi:10.1103/PhysicsPhysiqueFizika.1.195,
  reproduced as Ch. 2 of J. S. Bell (1987), "Speakable and Unspeakable in Quantum Mechanics", CUP
* B. S. Tsirelson, (1980), "Quantum generalizations of Bell's inequality".
  Letters in Mathematical Physics. 4 (2): 93–100. doi:10.1007/bf00417500.

-/

universes u

structure is_CHSH_tuple {R} [monoid R] [star_monoid R] (A₀ A₁ B₀ B₁ : R) :=
(A₀_inv : A₀^2 = 1) (A₁_inv : A₁^2 = 1) (B₀_inv : B₀^2 = 1) (B₁_inv : B₁^2 = 1)
(A₀_sa : star A₀ = A₀) (A₁_sa : star A₁ = A₁) (B₀_sa : star B₀ = B₀) (B₁_sa : star B₁ = B₁)
(A₀B₀_commutes : A₀ * B₀ = B₀ * A₀)
(A₀B₁_commutes : A₀ * B₁ = B₁ * A₀)
(A₁B₀_commutes : A₁ * B₀ = B₀ * A₁)
(A₁B₁_commutes : A₁ * B₁ = B₁ * A₁)

variables {R : Type u}

-- set_option pp.all true
/--
Given a CHSH tuple (A₀, A₁, B₀, B₁) in a *commutative* ordered *-algebra over ℝ,
`A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁ ≤ 2`.

(We could work over ℤ[⅟2] if we wanted to!)
-/
lemma CHSH_inequality_of_comm
  [ordered_comm_ring R] [star_ordered_ring R] [ordered_algebra ℝ R]
  (A₀ A₁ B₀ B₁ : R) (T : is_CHSH_tuple A₀ A₁ B₀ B₁) :
  A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁ ≤ 2 :=
begin
  let P := (2 - A₀ * B₀ - A₀ * B₁ - A₁ * B₀ + A₁ * B₁),
  have i₁ : 0 ≤ P,
  { have idem : P * P = 4 * P,
    { -- If we had a Gröbner basis algorithm, this would be trivial.
      -- Without one, it is somewhat tedious!
      dsimp [P],
      simp only [add_mul, mul_add, sub_mul, mul_sub, mul_comm, mul_assoc, add_assoc],
      repeat { conv in (B₀ * (A₀ * B₀))
      { rw [T.A₀B₀_commutes, ←mul_assoc B₀ B₀ A₀, ←pow_two, T.B₀_inv, one_mul], } },
      repeat { conv in (B₀ * (A₁ * B₀))
      { rw [T.A₁B₀_commutes, ←mul_assoc B₀ B₀ A₁, ←pow_two, T.B₀_inv, one_mul], } },
      repeat { conv in (B₁ * (A₀ * B₁))
      { rw [T.A₀B₁_commutes, ←mul_assoc B₁ B₁ A₀, ←pow_two, T.B₁_inv, one_mul], } },
      repeat { conv in (B₁ * (A₁ * B₁))
      { rw [T.A₁B₁_commutes, ←mul_assoc B₁ B₁ A₁, ←pow_two, T.B₁_inv, one_mul], } },
      conv in (A₀ * (B₀ * (A₀ * B₁)))
      { rw [←mul_assoc, T.A₀B₀_commutes, mul_assoc, ←mul_assoc A₀, ←pow_two, T.A₀_inv, one_mul], },
      conv in (A₀ * (B₁ * (A₀ * B₀)))
      { rw [←mul_assoc, T.A₀B₁_commutes, mul_assoc, ←mul_assoc A₀, ←pow_two, T.A₀_inv, one_mul], },
      conv in (A₁ * (B₀ * (A₁ * B₁)))
      { rw [←mul_assoc, T.A₁B₀_commutes, mul_assoc, ←mul_assoc A₁, ←pow_two, T.A₁_inv, one_mul], },
      conv in (A₁ * (B₁ * (A₁ * B₀)))
      { rw [←mul_assoc, T.A₁B₁_commutes, mul_assoc, ←mul_assoc A₁, ←pow_two, T.A₁_inv, one_mul], },
      simp only [←pow_two, T.A₀_inv, T.A₁_inv],
      simp only [mul_comm A₁ A₀, mul_comm B₁ B₀, mul_left_comm A₁ A₀, mul_left_comm B₁ B₀,
        mul_left_comm B₀ A₀, mul_left_comm B₀ A₁, mul_left_comm B₁ A₀, mul_left_comm B₁ A₁],
      norm_num,
      simp only [mul_comm _ (2 : R), mul_comm _ (4 : R),
        mul_left_comm _ (2 : R), mul_left_comm _ (4 : R)],
      abel,
      simp only [neg_mul_eq_neg_mul_symm, mul_one, int.cast_bit0, one_mul, int.cast_one,
        gsmul_eq_mul, int.cast_neg],
      simp only [←mul_assoc, ←add_assoc],
      norm_num, },
    have idem' : P = (1 / 4 : ℝ) • (P * P),
    { have h : 4 * P = (4 : ℝ) • P := by simp [algebra.smul_def],
      rw [idem, h, ←mul_smul],
      norm_num, },
    have sa : star P = P,
    { dsimp [P],
      simp only [star_add, star_sub, star_mul, star_bit0, star_one,
        T.A₀_sa, T.A₁_sa, T.B₀_sa, T.B₁_sa, mul_comm B₀, mul_comm B₁], },
    rw idem',
    conv_rhs { congr, skip, congr, rw ←sa, },
    convert smul_le_smul_of_nonneg (star_mul_self_nonneg : 0 ≤ star P * P) _,
    { simp, },
    { norm_num, }, },
  apply le_of_sub_nonneg,
  simpa only [sub_add_eq_sub_sub, ←sub_add] using i₁,
end

/-!
Before proving Tsirelson's bound,
we prepare some easy lemmas about √2.
-/


local notation `√2` := (2^(2⁻¹ : ℝ) : ℝ)

lemma one_lt_sqrt_two : 1 < √2 :=
by { convert real.rpow_lt_rpow _ one_lt_two _; norm_num }

lemma sqrt_two_ne_zero : √2 ≠ 0 :=
ne_of_gt (lt_trans zero_lt_one one_lt_sqrt_two)

lemma zero_lt_sqrt_two_inv : 0 < √2⁻¹ :=
begin
  simp only [inv_pos],
  apply real.rpow_pos_of_pos,
  norm_num,
end

@[simp] lemma sqrt_two_inv_sq : √2⁻¹ * √2⁻¹ = (2⁻¹ : ℝ) :=
by { rw [←mul_inv', ←real.rpow_add]; norm_num }

/-!
We next need some silly lemmas about numerals in modules and algebras.
If anyone sees how to obtain these from general statements, please improve this!
-/

lemma two_gsmul_half_smul {α : Type*} [add_comm_group α] [module ℝ α] {X : α} :
  2 •ℤ (2⁻¹ : ℝ) • X = X :=
by { rw [module.gsmul_eq_smul_cast ℝ, ←mul_smul]; norm_num, }

lemma neg_two_gsmul_half_smul {α : Type*} [add_comm_group α] [module ℝ α] {X : α} :
  (-2) •ℤ (2⁻¹ : ℝ) • X = - X :=
by { rw [module.gsmul_eq_smul_cast ℝ, ←mul_smul]; norm_num, }

lemma smul_two {α : Type*} [ring α] [algebra ℝ α] {x : ℝ} :
  x • (2 : α) = (2 * x) • 1 :=
by { rw [mul_comm 2 x, mul_smul], simp, }

lemma smul_four {α : Type*} [ring α] [algebra ℝ α] {x : ℝ} :
  x • (4 : α) = (4 * x) • 1 :=
by { rw [mul_comm 4 x, mul_smul], simp, }

-- This calculation, which we need for Tsirelson's bound,
-- defeated me. Thanks for the rescue from Shing Tak Lam!
lemma tsirelson_inequality_aux : √2 * √2 ^ 3 = √2 * (2 * √2⁻¹ + 4 * (√2⁻¹ * 2⁻¹)) :=
begin
  ring,
  rw [mul_assoc, inv_mul_cancel, ←real.rpow_nat_cast, ←real.rpow_mul],
  { norm_num,
    rw show (2 : ℝ) ^ (2 : ℝ) = (2 : ℝ) ^ (2 : ℕ), by { rw ←real.rpow_nat_cast, norm_num },
    norm_num },
  { norm_num },
  { -- I didn't find rpow_ne_zero
    apply ne_of_gt,
    apply real.rpow_pos_of_pos,
    norm_num },
end

/--
In a noncommutative ordered *-algebra over ℝ,
Tsirelson's bound for a CHSH tuple (A₀, A₁, B₀, B₁) is
`A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁ ≤ 2^(3/2) • 1`.

We prove this by providing an explicit sum-of-squares decomposition
of the difference.

(We could work over `ℤ[2^(1/2), 2^(-1/2)]` if we really wanted to!)
-/
lemma tsirelson_inequality
  [ordered_comm_ring R] [star_ordered_ring R] [ordered_algebra ℝ R] [star_algebra ℝ R]
  (A₀ A₁ B₀ B₁ : R) (T : is_CHSH_tuple A₀ A₁ B₀ B₁) :
  A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁ ≤ √2^3 • 1 :=
begin
  let P := √2⁻¹ • (A₁ + A₀) - B₀,
  let Q := √2⁻¹ • (A₁ - A₀) + B₁,
  have w : √2^3 • 1 - A₀ * B₀ - A₀ * B₁ - A₁ * B₀ + A₁ * B₁ = √2⁻¹ • (P^2 + Q^2),
  { dsimp [P, Q],
    simp only [pow_two, sub_mul, mul_sub, add_mul, mul_add, smul_add, smul_sub],
    simp only [algebra.mul_smul_comm, algebra.smul_mul_assoc, ←mul_smul, sqrt_two_inv_sq],
    simp only [←pow_two, T.A₀_inv, T.A₁_inv, T.B₀_inv, T.B₁_inv],
    simp only [←T.A₀B₀_commutes, ←T.A₀B₁_commutes, ←T.A₁B₀_commutes, ←T.A₁B₁_commutes],
    abel,
    simp only [two_gsmul_half_smul, neg_two_gsmul_half_smul],
    abel,
    congr,
    simp only [mul_one, int.cast_bit0, algebra.mul_smul_comm, int.cast_one, gsmul_eq_mul],
    rw [smul_two, smul_four, ←add_smul],
    congr,
    exact mul_left_cancel' sqrt_two_ne_zero tsirelson_inequality_aux, },
  have pos : 0 ≤ √2⁻¹ • (P^2 + Q^2), {
    have P_sa : star P = P,
    { dsimp [P],
      simp only [star_smul, star_add, star_sub, star_id_of_comm,
        T.A₀_sa, T.A₁_sa, T.B₀_sa, T.B₁_sa], },
    have Q_sa : star Q = Q,
    { dsimp [Q],
      simp only [star_smul, star_add, star_sub, star_id_of_comm,
        T.A₀_sa, T.A₁_sa, T.B₀_sa, T.B₁_sa], },
    have P2_nonneg : 0 ≤ P^2,
    { rw [pow_two],
      conv { congr, skip, congr, rw ←P_sa, },
      convert (star_mul_self_nonneg : 0 ≤ star P * P), },
    have Q2_nonneg : 0 ≤ Q^2,
    { rw [pow_two],
      conv { congr, skip, congr, rw ←Q_sa, },
      convert (star_mul_self_nonneg : 0 ≤ star Q * Q), },
    convert smul_le_smul_of_nonneg (add_nonneg P2_nonneg Q2_nonneg) (le_of_lt zero_lt_sqrt_two_inv),
    simp, },
  apply le_of_sub_nonneg,
  simpa only [sub_add_eq_sub_sub, ←sub_add, w] using pos,
end