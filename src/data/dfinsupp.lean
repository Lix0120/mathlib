/-
Copyright (c) 2018 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Kenny Lau
-/
import algebra.module.linear_map
import algebra.module.pi
import algebra.big_operators.basic
import data.set.finite
import linear_algebra.basic

/-!
# Dependent functions with finite support

For a non-dependent version see `data/finsupp.lean`.
-/

universes u u₁ u₂ v v₁ v₂ v₃ w x y l

open_locale big_operators

variables (ι : Type u) (β : ι → Type v)

namespace dfinsupp

variable [Π i, has_zero (β i)]

structure pre : Type (max u v) :=
(to_fun : Π i, β i)
(pre_support : multiset ι)
(zero : ∀ i, i ∈ pre_support ∨ to_fun i = 0)

instance inhabited_pre : inhabited (pre ι β) :=
⟨⟨λ i, 0, ∅, λ i, or.inr rfl⟩⟩

instance : setoid (pre ι β) :=
{ r := λ x y, ∀ i, x.to_fun i = y.to_fun i,
  iseqv := ⟨λ f i, rfl, λ f g H i, (H i).symm,
    λ f g h H1 H2 i, (H1 i).trans (H2 i)⟩ }

end dfinsupp

variable {ι}
/-- A dependent function `Π i, β i` with finite support. -/
@[reducible]
def dfinsupp [Π i, has_zero (β i)] : Type* :=
quotient (dfinsupp.pre.setoid ι β)
variable {β}

notation `Π₀` binders `, ` r:(scoped f, dfinsupp f) := r
infix ` →ₚ `:25 := dfinsupp

namespace dfinsupp

section basic
variables [Π i, has_zero (β i)]
variables {β₁ : ι → Type v₁} {β₂ : ι → Type v₂}
variables [Π i, has_zero (β₁ i)] [Π i, has_zero (β₂ i)]

instance : has_coe_to_fun (Π₀ i, β i) :=
⟨λ _, Π i, β i, λ f, quotient.lift_on f pre.to_fun $ λ _ _, funext⟩

instance : has_zero (Π₀ i, β i) := ⟨⟦⟨λ i, 0, ∅, λ i, or.inr rfl⟩⟧⟩
instance : inhabited (Π₀ i, β i) := ⟨0⟩

@[simp] lemma zero_apply (i : ι) : (0 : Π₀ i, β i) i = 0 := rfl

@[ext] lemma ext {f g : Π₀ i, β i} (H : ∀ i, f i = g i) : f = g :=
quotient.induction_on₂ f g (λ _ _ H, quotient.sound H) H

/-- The composition of `f : β₁ → β₂` and `g : Π₀ i, β₁ i` is
  `map_range f hf g : Π₀ i, β₂ i`, well defined when `f 0 = 0`. -/
def map_range (f : Π i, β₁ i → β₂ i) (hf : ∀ i, f i 0 = 0) (g : Π₀ i, β₁ i) : Π₀ i, β₂ i :=
quotient.lift_on g (λ x, ⟦(⟨λ i, f i (x.1 i), x.2,
  λ i, or.cases_on (x.3 i) or.inl $ λ H, or.inr $ by rw [H, hf]⟩ : pre ι β₂)⟧) $ λ x y H,
quotient.sound $ λ i, by simp only [H i]

@[simp] lemma map_range_apply
  (f : Π i, β₁ i → β₂ i) (hf : ∀ i, f i 0 = 0) (g : Π₀ i, β₁ i) (i : ι) :
  map_range f hf g i = f i (g i) :=
quotient.induction_on g $ λ x, rfl

/-- Let `f i` be a binary operation `β₁ i → β₂ i → β i` such that `f i 0 0 = 0`.
Then `zip_with f hf` is a binary operation `Π₀ i, β₁ i → Π₀ i, β₂ i → Π₀ i, β i`. -/
def zip_with (f : Π i, β₁ i → β₂ i → β i) (hf : ∀ i, f i 0 0 = 0)
  (g₁ : Π₀ i, β₁ i) (g₂ : Π₀ i, β₂ i) : (Π₀ i, β i) :=
begin
  refine quotient.lift_on₂ g₁ g₂ (λ x y, ⟦(⟨λ i, f i (x.1 i) (y.1 i), x.2 + y.2,
    λ i, _⟩ : pre ι β)⟧) _,
  { cases x.3 i with h1 h1,
    { left, rw multiset.mem_add, left, exact h1 },
    cases y.3 i with h2 h2,
    { left, rw multiset.mem_add, right, exact h2 },
    right, rw [h1, h2, hf] },
  exact λ x₁ x₂ y₁ y₂ H1 H2, quotient.sound $ λ i, by simp only [H1 i, H2 i]
end

@[simp] lemma zip_with_apply
  (f : Π i, β₁ i → β₂ i → β i) (hf : ∀ i, f i 0 0 = 0) (g₁ : Π₀ i, β₁ i) (g₂ : Π₀ i, β₂ i) (i : ι) :
  zip_with f hf g₁ g₂ i = f i (g₁ i) (g₂ i) :=
quotient.induction_on₂ g₁ g₂ $ λ _ _, rfl

end basic

section algebra

instance [Π i, add_monoid (β i)] : has_add (Π₀ i, β i) :=
⟨zip_with (λ _, (+)) (λ _, add_zero 0)⟩

@[simp] lemma add_apply [Π i, add_monoid (β i)] (g₁ g₂ : Π₀ i, β i) (i : ι) :
  (g₁ + g₂) i = g₁ i + g₂ i :=
zip_with_apply _ _ g₁ g₂ i

instance [Π i, add_monoid (β i)] : add_monoid (Π₀ i, β i) :=
{ add_monoid .
  zero      := 0,
  add       := (+),
  add_assoc := λ f g h, ext $ λ i, by simp only [add_apply, add_assoc],
  zero_add  := λ f, ext $ λ i, by simp only [add_apply, zero_apply, zero_add],
  add_zero  := λ f, ext $ λ i, by simp only [add_apply, zero_apply, add_zero] }

instance is_add_monoid_hom [Π i, add_monoid (β i)] {i : ι} :
  is_add_monoid_hom (λ g : Π₀ i : ι, β i, g i) :=
{ map_add := λ f g, add_apply f g i, map_zero := zero_apply i }

instance [Π i, add_group (β i)] : has_neg (Π₀ i, β i) :=
⟨λ f, f.map_range (λ _, has_neg.neg) (λ _, neg_zero)⟩

instance [Π i, add_comm_monoid (β i)] : add_comm_monoid (Π₀ i, β i) :=
{ add_comm := λ f g, ext $ λ i, by simp only [add_apply, add_comm],
  .. dfinsupp.add_monoid }

@[simp] lemma neg_apply [Π i, add_group (β i)] (g : Π₀ i, β i) (i : ι) : (- g) i = - g i :=
map_range_apply _ _ g i

instance [Π i, add_group (β i)] : add_group (Π₀ i, β i) :=
{ add_left_neg := λ f, ext $ λ i, by simp only [add_apply, neg_apply, zero_apply, add_left_neg],
  .. dfinsupp.add_monoid,
  .. (infer_instance : has_neg (Π₀ i, β i)) }

@[simp] lemma sub_apply [Π i, add_group (β i)] (g₁ g₂ : Π₀ i, β i) (i : ι) :
  (g₁ - g₂) i = g₁ i - g₂ i :=
by rw [sub_eq_add_neg]; simp [sub_eq_add_neg]

instance [Π i, add_comm_group (β i)] : add_comm_group (Π₀ i, β i) :=
{ add_comm := λ f g, ext $ λ i, by simp only [add_apply, add_comm],
  ..dfinsupp.add_group }

/-- Dependent functions with finite support inherit a semiring action from an action on each
coordinate. -/
instance {γ : Type w} [semiring γ] [Π i, add_comm_monoid (β i)] [Π i, semimodule γ (β i)] :
  has_scalar γ (Π₀ i, β i) :=
⟨λc v, v.map_range (λ _, (•) c) (λ _, smul_zero _)⟩

@[simp] lemma smul_apply {γ : Type w} [semiring γ] [Π i, add_comm_monoid (β i)]
  [Π i, semimodule γ (β i)] (b : γ) (v : Π₀ i, β i) (i : ι) :
  (b • v) i = b • (v i) :=
map_range_apply _ _ v i

/-- Dependent functions with finite support inherit a semimodule structure from such a structure on
each coordinate. -/
instance {γ : Type w} [semiring γ] [Π i, add_comm_monoid (β i)] [Π i, semimodule γ (β i)] :
  semimodule γ (Π₀ i, β i) :=
{ smul_zero := λ c, ext $ λ i, by simp only [smul_apply, smul_zero, zero_apply],
  zero_smul := λ c, ext $ λ i, by simp only [smul_apply, zero_smul, zero_apply],
  smul_add := λ c x y, ext $ λ i, by simp only [add_apply, smul_apply, smul_add],
  add_smul := λ c x y, ext $ λ i, by simp only [add_apply, smul_apply, add_smul],
  one_smul := λ x, ext $ λ i, by simp only [smul_apply, one_smul],
  mul_smul := λ r s x, ext $ λ i, by simp only [smul_apply, smul_smul],
  .. (infer_instance : has_scalar γ (Π₀ i, β i)) }

end algebra

section filter_and_subtype_domain

/-- `filter p f` is the function which is `f i` if `p i` is true and 0 otherwise. -/
def filter [Π i, has_zero (β i)] (p : ι → Prop) [decidable_pred p] (f : Π₀ i, β i) : Π₀ i, β i :=
quotient.lift_on f (λ x, ⟦(⟨λ i, if p i then x.1 i else 0, x.2,
  λ i, or.cases_on (x.3 i) or.inl $ λ H, or.inr $ by rw [H, if_t_t]⟩ : pre ι β)⟧) $ λ x y H,
quotient.sound $ λ i, by simp only [H i]

@[simp] lemma filter_apply [Π i, has_zero (β i)]
  (p : ι → Prop) [decidable_pred p] (i : ι) (f : Π₀ i, β i) :
  f.filter p i = if p i then f i else 0 :=
quotient.induction_on f $ λ x, rfl

lemma filter_apply_pos [Π i, has_zero (β i)]
  {p : ι → Prop} [decidable_pred p] (f : Π₀ i, β i) {i : ι} (h : p i) :
  f.filter p i = f i :=
by simp only [filter_apply, if_pos h]

lemma filter_apply_neg [Π i, has_zero (β i)]
  {p : ι → Prop} [decidable_pred p] (f : Π₀ i, β i) {i : ι} (h : ¬ p i) :
  f.filter p i = 0 :=
by simp only [filter_apply, if_neg h]

lemma filter_pos_add_filter_neg [Π i, add_monoid (β i)] (f : Π₀ i, β i)
  (p : ι → Prop) [decidable_pred p] :
  f.filter p + f.filter (λi, ¬ p i) = f :=
ext $ λ i, by simp only [add_apply, filter_apply]; split_ifs; simp only [add_zero, zero_add]

/-- `subtype_domain p f` is the restriction of the finitely supported function
  `f` to the subtype `p`. -/
def subtype_domain [Π i, has_zero (β i)] (p : ι → Prop) [decidable_pred p]
  (f : Π₀ i, β i) : Π₀ i : subtype p, β i :=
begin
  fapply quotient.lift_on f,
  { intro x,
    refine ⟦⟨λ i, x.1 (i : ι),
      (x.2.filter p).attach.map $ λ j, ⟨j, (multiset.mem_filter.1 j.2).2⟩, _⟩⟧,
    refine λ i, or.cases_on (x.3 i) (λ H, _) or.inr,
    left, rw multiset.mem_map, refine ⟨⟨i, multiset.mem_filter.2 ⟨H, i.2⟩⟩, _, subtype.eta _ _⟩,
    apply multiset.mem_attach },
  intros x y H,
  exact quotient.sound (λ i, H i)
end

@[simp] lemma subtype_domain_zero [Π i, has_zero (β i)] {p : ι → Prop} [decidable_pred p] :
  subtype_domain p (0 : Π₀ i, β i) = 0 :=
rfl

@[simp] lemma subtype_domain_apply [Π i, has_zero (β i)] {p : ι → Prop} [decidable_pred p]
  {i : subtype p} {v : Π₀ i, β i} :
  (subtype_domain p v) i = v i :=
quotient.induction_on v $ λ x, rfl

@[simp] lemma subtype_domain_add [Π i, add_monoid (β i)] {p : ι → Prop} [decidable_pred p]
  {v v' : Π₀ i, β i} :
  (v + v').subtype_domain p = v.subtype_domain p + v'.subtype_domain p :=
ext $ λ i, by simp only [add_apply, subtype_domain_apply]

instance subtype_domain.is_add_monoid_hom [Π i, add_monoid (β i)]
  {p : ι → Prop} [decidable_pred p] :
  is_add_monoid_hom (subtype_domain p : (Π₀ i : ι, β i) → Π₀ i : subtype p, β i) :=
{ map_add := λ _ _, subtype_domain_add, map_zero := subtype_domain_zero }

@[simp]
lemma subtype_domain_neg [Π i, add_group (β i)] {p : ι → Prop} [decidable_pred p] {v : Π₀ i, β i} :
  (- v).subtype_domain p = - v.subtype_domain p :=
ext $ λ i, by simp only [neg_apply, subtype_domain_apply]

@[simp] lemma subtype_domain_sub [Π i, add_group (β i)] {p : ι → Prop} [decidable_pred p]
  {v v' : Π₀ i, β i} :
  (v - v').subtype_domain p = v.subtype_domain p - v'.subtype_domain p :=
ext $ λ i, by simp only [sub_apply, subtype_domain_apply]

end filter_and_subtype_domain


variable [dec : decidable_eq ι]
include dec

section basic
variable [Π i, has_zero (β i)]

omit dec
lemma finite_supp (f : Π₀ i, β i) : set.finite {i | f i ≠ 0} :=
begin
  classical,
  exact quotient.induction_on f (λ x, x.2.to_finset.finite_to_set.subset (λ i H,
    multiset.mem_to_finset.2 ((x.3 i).resolve_right H)))
end
include dec

/-- Create an element of `Π₀ i, β i` from a finset `s` and a function `x`
defined on this `finset`. -/
def mk (s : finset ι) (x : Π i : (↑s : set ι), β (i : ι)) : Π₀ i, β i :=
⟦⟨λ i, if H : i ∈ s then x ⟨i, H⟩ else 0, s.1,
λ i, if H : i ∈ s then or.inl H else or.inr $ dif_neg H⟩⟧

@[simp] lemma mk_apply {s : finset ι} {x : Π i : (↑s : set ι), β i} {i : ι} :
  (mk s x : Π i, β i) i = if H : i ∈ s then x ⟨i, H⟩ else 0 :=
rfl

theorem mk_injective (s : finset ι) : function.injective (@mk ι β _ _ s) :=
begin
  intros x y H,
  ext i,
  have h1 : (mk s x : Π i, β i) i = (mk s y : Π i, β i) i, {rw H},
  cases i with i hi,
  change i ∈ s at hi,
  dsimp only [mk_apply, subtype.coe_mk] at h1,
  simpa only [dif_pos hi] using h1
end

/-- The function `single i b : Π₀ i, β i` sends `i` to `b`
and all other points to `0`. -/
def single (i : ι) (b : β i) : Π₀ i, β i :=
mk {i} $ λ j, eq.rec_on (finset.mem_singleton.1 j.prop).symm b

@[simp] lemma single_apply {i i' b} :
  (single i b : Π₀ i, β i) i' = (if h : i = i' then eq.rec_on h b else 0) :=
begin
  dsimp only [single],
  by_cases h : i = i',
  { have h1 : i' ∈ ({i} : finset ι) := finset.mem_singleton.2 h.symm,
    simp only [mk_apply, dif_pos h, dif_pos h1], refl },
  { have h1 : i' ∉ ({i} : finset ι) := finset.not_mem_singleton.2 (ne.symm h),
    simp only [mk_apply, dif_neg h, dif_neg h1] }
end

@[simp] lemma single_zero {i} : (single i 0 : Π₀ i, β i) = 0 :=
quotient.sound $ λ j, if H : j ∈ ({i} : finset _)
then by dsimp only; rw [dif_pos H]; cases finset.mem_singleton.1 H; refl
else dif_neg H

@[simp] lemma single_eq_same {i b} : (single i b : Π₀ i, β i) i = b :=
by simp only [single_apply, dif_pos rfl]

lemma single_eq_of_ne {i i' b} (h : i ≠ i') : (single i b : Π₀ i, β i) i' = 0 :=
by simp only [single_apply, dif_neg h]

lemma single_injective {i} : function.injective (single i : β i → Π₀ i, β i) :=
λ x y H, congr_fun (mk_injective _ H) ⟨i, by simp⟩

/-- Like `finsupp.single_eq_single_iff`, but with a `heq` due to dependent types -/
lemma single_eq_single_iff (i j : ι) (xi : β i) (xj : β j) :
  dfinsupp.single i xi = dfinsupp.single j xj ↔ i = j ∧ xi == xj ∨ xi = 0 ∧ xj = 0 :=
begin
  split,
  { intro h,
    by_cases hij : i = j,
    { subst hij,
      exact or.inl ⟨rfl, heq_of_eq (dfinsupp.single_injective h)⟩, },
    { have h_coe : ⇑(dfinsupp.single i xi) = dfinsupp.single j xj := congr_arg coe_fn h,
      have hci := congr_fun h_coe i,
      have hcj := congr_fun h_coe j,
      rw dfinsupp.single_eq_same at hci hcj,
      rw dfinsupp.single_eq_of_ne (ne.symm hij) at hci,
      rw dfinsupp.single_eq_of_ne (hij) at hcj,
      exact or.inr ⟨hci, hcj.symm⟩, }, },
  { rintros (⟨hi, hxi⟩ | ⟨hi, hj⟩),
    { subst hi,
      rw eq_of_heq hxi, },
    { rw [hi, hj, dfinsupp.single_zero, dfinsupp.single_zero], }, },
end

/-- Redefine `f i` to be `0`. -/
def erase (i : ι) (f : Π₀ i, β i) : Π₀ i, β i :=
quotient.lift_on f (λ x, ⟦(⟨λ j, if j = i then 0 else x.1 j, x.2,
λ j, or.cases_on (x.3 j) or.inl $ λ H, or.inr $ by simp only [H, if_t_t]⟩ : pre ι β)⟧) $ λ x y H,
quotient.sound $ λ j, if h : j = i then by simp only [if_pos h]
else by simp only [if_neg h, H j]

@[simp] lemma erase_apply {i j : ι} {f : Π₀ i, β i} :
  (f.erase i) j = if j = i then 0 else f j :=
quotient.induction_on f $ λ x, rfl

@[simp] lemma erase_same {i : ι} {f : Π₀ i, β i} : (f.erase i) i = 0 :=
by simp

lemma erase_ne {i i' : ι} {f : Π₀ i, β i} (h : i' ≠ i) : (f.erase i) i' = f i' :=
by simp [h]

end basic

section add_monoid

variable [Π i, add_monoid (β i)]

@[simp] lemma single_add {i : ι} {b₁ b₂ : β i} : single i (b₁ + b₂) = single i b₁ + single i b₂ :=
ext $ assume i',
begin
  by_cases h : i = i',
  { subst h, simp only [add_apply, single_eq_same] },
  { simp only [add_apply, single_eq_of_ne h, zero_add] }
end

variables (β)

/-- `dfinsupp.single` as an `add_monoid_hom`. -/
@[simps] def single_add_hom (i : ι) : β i →+ Π₀ i, β i :=
{ to_fun := single i, map_zero' := single_zero, map_add' := λ _ _, single_add }

variables {β}

lemma single_add_erase {i : ι} {f : Π₀ i, β i} : single i (f i) + f.erase i = f :=
ext $ λ i',
if h : i = i'
then by subst h; simp only [add_apply, single_apply, erase_apply, dif_pos rfl, if_pos, add_zero]
else by simp only [add_apply, single_apply, erase_apply, dif_neg h, if_neg (ne.symm h), zero_add]

lemma erase_add_single {i : ι} {f : Π₀ i, β i} : f.erase i + single i (f i) = f :=
ext $ λ i',
if h : i = i'
then by subst h; simp only [add_apply, single_apply, erase_apply, dif_pos rfl, if_pos, zero_add]
else by simp only [add_apply, single_apply, erase_apply, dif_neg h, if_neg (ne.symm h), add_zero]

protected theorem induction {p : (Π₀ i, β i) → Prop} (f : Π₀ i, β i)
  (h0 : p 0) (ha : ∀i b (f : Π₀ i, β i), f i = 0 → b ≠ 0 → p f → p (single i b + f)) :
  p f :=
begin
  refine quotient.induction_on f (λ x, _),
  cases x with f s H, revert f H,
  apply multiset.induction_on s,
  { intros f H, convert h0, ext i, exact (H i).resolve_left id },
  intros i s ih f H,
  by_cases H1 : i ∈ s,
  { have H2 : ∀ j, j ∈ s ∨ f j = 0,
    { intro j, cases H j with H2 H2,
      { cases multiset.mem_cons.1 H2 with H3 H3,
        { left, rw H3, exact H1 },
        { left, exact H3 } },
      right, exact H2 },
    have H3 : (⟦{to_fun := f, pre_support := i ::ₘ s, zero := H}⟧ : Π₀ i, β i)
      = ⟦{to_fun := f, pre_support := s, zero := H2}⟧,
    { exact quotient.sound (λ i, rfl) },
    rw H3, apply ih },
  have H2 : p (erase i ⟦{to_fun := f, pre_support := i ::ₘ s, zero := H}⟧),
  { dsimp only [erase, quotient.lift_on_beta],
    have H2 : ∀ j, j ∈ s ∨ ite (j = i) 0 (f j) = 0,
    { intro j, cases H j with H2 H2,
      { cases multiset.mem_cons.1 H2 with H3 H3,
        { right, exact if_pos H3 },
        { left, exact H3 } },
      right, split_ifs; [refl, exact H2] },
    have H3 : (⟦{to_fun := λ (j : ι), ite (j = i) 0 (f j),
         pre_support := i ::ₘ s, zero := _}⟧ : Π₀ i, β i)
      = ⟦{to_fun := λ (j : ι), ite (j = i) 0 (f j), pre_support := s, zero := H2}⟧ :=
      quotient.sound (λ i, rfl),
    rw H3, apply ih },
  have H3 : single i _ + _ = (⟦{to_fun := f, pre_support := i ::ₘ s, zero := H}⟧ : Π₀ i, β i) :=
    single_add_erase,
  rw ← H3,
  change p (single i (f i) + _),
  cases classical.em (f i = 0) with h h,
  { rw [h, single_zero, zero_add], exact H2 },
  refine ha _ _ _ _ h H2,
  rw erase_same
end

lemma induction₂ {p : (Π₀ i, β i) → Prop} (f : Π₀ i, β i)
  (h0 : p 0) (ha : ∀i b (f : Π₀ i, β i), f i = 0 → b ≠ 0 → p f → p (f + single i b)) :
  p f :=
dfinsupp.induction f h0 $ λ i b f h1 h2 h3,
have h4 : f + single i b = single i b + f,
{ ext j, by_cases H : i = j,
  { subst H, simp [h1] },
  { simp [H] } },
eq.rec_on h4 $ ha i b f h1 h2 h3

@[simp] lemma add_closure_Union_range_single :
  add_submonoid.closure (⋃ i : ι, set.range (single i : β i → (Π₀ i, β i))) = ⊤ :=
top_unique $ λ x hx, (begin
  apply dfinsupp.induction x,
  exact add_submonoid.zero_mem _,
  exact λ a b f ha hb hf, add_submonoid.add_mem _
    (add_submonoid.subset_closure $ set.mem_Union.2 ⟨a, set.mem_range_self _⟩) hf
end)

/-- If two additive homomorphisms from `Π₀ i, β i` are equal on each `single a b`, then
they are equal. -/
lemma add_hom_ext {γ : Type w} [add_monoid γ] ⦃f g : (Π₀ i, β i) →+ γ⦄
  (H : ∀ (i : ι) (y : β i), f (single i y) = g (single i y)) :
  f = g :=
begin
  refine add_monoid_hom.eq_of_eq_on_mdense add_closure_Union_range_single (λ f hf, _),
  simp only [set.mem_Union, set.mem_range] at hf,
  rcases hf with ⟨x, y, rfl⟩,
  apply H
end

/-- If two additive homomorphisms from `Π₀ i, β i` are equal on each `single a b`, then
they are equal.

We formulate this using equality of `add_monoid_hom`s so that `ext` tactic can apply a type-specific
extensionality lemma after this one.  E.g., if the fiber `M` is `ℕ` or `ℤ`, then it suffices to
verify `f (single a 1) = g (single a 1)`. -/
@[ext] lemma add_hom_ext' {γ : Type w} [add_monoid γ] ⦃f g : (Π₀ i, β i) →+ γ⦄
  (H : ∀ x, f.comp (single_add_hom β x) = g.comp (single_add_hom β x)) :
  f = g :=
add_hom_ext $ λ x, add_monoid_hom.congr_fun (H x)

end add_monoid

@[simp] lemma mk_add [Π i, add_monoid (β i)] {s : finset ι} {x y : Π i : (↑s : set ι), β i} :
  mk s (x + y) = mk s x + mk s y :=
ext $ λ i, by simp only [add_apply, mk_apply]; split_ifs; [refl, rw zero_add]

@[simp] lemma mk_zero [Π i, has_zero (β i)] {s : finset ι} :
  mk s (0 : Π i : (↑s : set ι), β i.1) = 0 :=
ext $ λ i, by simp only [mk_apply]; split_ifs; refl

@[simp] lemma mk_neg [Π i, add_group (β i)] {s : finset ι} {x : Π i : (↑s : set ι), β i.1} :
  mk s (-x) = -mk s x :=
ext $ λ i, by simp only [neg_apply, mk_apply]; split_ifs; [refl, rw neg_zero]

@[simp] lemma mk_sub [Π i, add_group (β i)] {s : finset ι} {x y : Π i : (↑s : set ι), β i.1} :
  mk s (x - y) = mk s x - mk s y :=
ext $ λ i, by simp only [sub_apply, mk_apply]; split_ifs; [refl, rw sub_zero]

instance [Π i, add_group (β i)] {s : finset ι} : is_add_group_hom (@mk ι β _ _ s) :=
{ map_add := λ _ _, mk_add }

section
variables (γ : Type w) [semiring γ] [Π i, add_comm_monoid (β i)] [Π i, semimodule γ (β i)]
include γ

@[simp] lemma mk_smul {s : finset ι} {c : γ} (x : Π i : (↑s : set ι), β i.1) :
  mk s (c • x) = c • mk s x :=
ext $ λ i, by simp only [smul_apply, mk_apply]; split_ifs; [refl, rw smul_zero]

@[simp] lemma single_smul {i : ι} {c : γ} {x : β i} :
  single i (c • x) = c • single i x :=
ext $ λ i, by simp only [smul_apply, single_apply]; split_ifs; [cases h, rw smul_zero]; refl

variable β
/-- `dfinsupp.mk` as a `linear_map`. -/
def lmk (s : finset ι) : (Π i : (↑s : set ι), β i.1) →ₗ[γ] Π₀ i, β i :=
⟨mk s, λ _ _, mk_add, λ c x, by rw [mk_smul γ x]⟩

/-- `dfinsupp.single` as a `linear_map` -/
def lsingle (i) : β i →ₗ[γ] Π₀ i, β i :=
⟨single i, λ _ _, single_add, λ _ _, single_smul _⟩
variable {β}

/-- Two `R`-linear maps from `Π₀ i, β i` which agree on each `single i x` agree everywhere. -/
lemma lhom_ext {δ : Type*} [add_comm_monoid δ] [semimodule γ δ] ⦃φ ψ : (Π₀ i, β i) →ₗ[γ] δ⦄
  (h : ∀ i x, φ (single i x) = ψ (single i x)) :
  φ = ψ :=
linear_map.to_add_monoid_hom_injective $ add_hom_ext h

/-- Two `R`-linear maps from `Π₀ i, β i` which agree on each `single i x` agree everywhere.

We formulate this fact using equality of linear maps `φ.comp (lsingle a)` and `ψ.comp (lsingle a)`
so that the `ext` tactic can apply a type-specific extensionality lemma to prove equality of these
maps. E.g., if `M = R`, then it suffices to verify `φ (single a 1) = ψ (single a 1)`. -/
@[ext] lemma lhom_ext' {δ : Type*} [add_comm_monoid δ] [semimodule γ δ] ⦃φ ψ : (Π₀ i, β i) →ₗ[γ] δ⦄
  (h : ∀ i, φ.comp (lsingle β γ i) = ψ.comp (lsingle β γ i)) :
  φ = ψ :=
lhom_ext γ $ λ i, linear_map.congr_fun (h i)

@[simp] lemma lmk_apply {s : finset ι} {x} : lmk β γ s x = mk s x := rfl

@[simp] lemma lsingle_apply {i : ι} {x : β i} : lsingle β γ i x = single i x := rfl
end

section support_basic

variables [Π i, has_zero (β i)] [Π i (x : β i), decidable (x ≠ 0)]

/-- Set `{i | f x ≠ 0}` as a `finset`. -/
def support (f : Π₀ i, β i) : finset ι :=
quotient.lift_on f (λ x, x.2.to_finset.filter $ λ i, x.1 i ≠ 0) $
begin
  intros x y Hxy,
  ext i, split,
  { intro H,
    rcases finset.mem_filter.1 H with ⟨h1, h2⟩,
    rw Hxy i at h2,
    exact finset.mem_filter.2 ⟨multiset.mem_to_finset.2 $ (y.3 i).resolve_right h2, h2⟩ },
  { intro H,
    rcases finset.mem_filter.1 H with ⟨h1, h2⟩,
    rw ← Hxy i at h2,
    exact finset.mem_filter.2 ⟨multiset.mem_to_finset.2 $ (x.3 i).resolve_right h2, h2⟩ },
end

@[simp] theorem support_mk_subset {s : finset ι} {x : Π i : (↑s : set ι), β i.1} :
  (mk s x).support ⊆ s :=
λ i H, multiset.mem_to_finset.1 (finset.mem_filter.1 H).1

@[simp] theorem mem_support_to_fun (f : Π₀ i, β i) (i) : i ∈ f.support ↔ f i ≠ 0 :=
begin
  refine quotient.induction_on f (λ x, _),
  dsimp only [support, quotient.lift_on_beta],
  rw [finset.mem_filter, multiset.mem_to_finset],
  exact and_iff_right_of_imp (x.3 i).resolve_right
end

theorem eq_mk_support (f : Π₀ i, β i) : f = mk f.support (λ i, f i) :=
begin
  change f = mk f.support (λ i, f i.1),
  ext i,
  by_cases h : f i ≠ 0; [skip, rw [not_not] at h];
    simp [h]
end

@[simp] lemma support_zero : (0 : Π₀ i, β i).support = ∅ := rfl

lemma mem_support_iff (f : Π₀ i, β i) : ∀i:ι, i ∈ f.support ↔ f i ≠ 0 :=
f.mem_support_to_fun

@[simp] lemma support_eq_empty {f : Π₀ i, β i} : f.support = ∅ ↔ f = 0 :=
⟨λ H, ext $ by simpa [finset.ext_iff] using H, by simp {contextual:=tt}⟩

instance decidable_zero : decidable_pred (eq (0 : Π₀ i, β i)) :=
λ f, decidable_of_iff _ $ support_eq_empty.trans eq_comm

lemma support_subset_iff {s : set ι} {f : Π₀ i, β i} :
  ↑f.support ⊆ s ↔ (∀i∉s, f i = 0) :=
by simp [set.subset_def];
   exact forall_congr (assume i, not_imp_comm)

lemma support_single_ne_zero {i : ι} {b : β i} (hb : b ≠ 0) : (single i b).support = {i} :=
begin
  ext j, by_cases h : i = j,
  { subst h, simp [hb] },
  simp [ne.symm h, h]
end

lemma support_single_subset {i : ι} {b : β i} : (single i b).support ⊆ {i} :=
support_mk_subset

section map_range_and_zip_with

variables {β₁ : ι → Type v₁} {β₂ : ι → Type v₂}
variables [Π i, has_zero (β₁ i)] [Π i, has_zero (β₂ i)]

lemma map_range_def [Π i (x : β₁ i), decidable (x ≠ 0)]
  {f : Π i, β₁ i → β₂ i} {hf : ∀ i, f i 0 = 0} {g : Π₀ i, β₁ i} :
  map_range f hf g = mk g.support (λ i, f i.1 (g i.1)) :=
begin
  ext i,
  by_cases h : g i ≠ 0; simp at h; simp [h, hf]
end

@[simp] lemma map_range_single {f : Π i, β₁ i → β₂ i} {hf : ∀ i, f i 0 = 0} {i : ι} {b : β₁ i} :
  map_range f hf (single i b) = single i (f i b) :=
dfinsupp.ext $ λ i', by by_cases i = i'; [{subst i', simp}, simp [h, hf]]

variables [Π i (x : β₁ i), decidable (x ≠ 0)] [Π i (x : β₂ i), decidable (x ≠ 0)]

lemma support_map_range {f : Π i, β₁ i → β₂ i} {hf : ∀ i, f i 0 = 0} {g : Π₀ i, β₁ i} :
  (map_range f hf g).support ⊆ g.support :=
by simp [map_range_def]

lemma zip_with_def {f : Π i, β₁ i → β₂ i → β i} {hf : ∀ i, f i 0 0 = 0}
  {g₁ : Π₀ i, β₁ i} {g₂ : Π₀ i, β₂ i} :
  zip_with f hf g₁ g₂ = mk (g₁.support ∪ g₂.support) (λ i, f i.1 (g₁ i.1) (g₂ i.1)) :=
begin
  ext i,
  by_cases h1 : g₁ i ≠ 0; by_cases h2 : g₂ i ≠ 0;
    simp only [not_not, ne.def] at h1 h2; simp [h1, h2, hf]
end

lemma support_zip_with {f : Π i, β₁ i → β₂ i → β i} {hf : ∀ i, f i 0 0 = 0}
  {g₁ : Π₀ i, β₁ i} {g₂ : Π₀ i, β₂ i} :
  (zip_with f hf g₁ g₂).support ⊆ g₁.support ∪ g₂.support :=
by simp [zip_with_def]

end map_range_and_zip_with

lemma erase_def (i : ι) (f : Π₀ i, β i) :
  f.erase i = mk (f.support.erase i) (λ j, f j.1) :=
by { ext j, by_cases h1 : j = i; by_cases h2 : f j ≠ 0; simp at h2; simp [h1, h2] }

@[simp] lemma support_erase (i : ι) (f : Π₀ i, β i) :
  (f.erase i).support = f.support.erase i :=
by { ext j, by_cases h1 : j = i; by_cases h2 : f j ≠ 0; simp at h2; simp [h1, h2] }

section filter_and_subtype_domain

variables {p : ι → Prop} [decidable_pred p]

lemma filter_def (f : Π₀ i, β i) :
  f.filter p = mk (f.support.filter p) (λ i, f i.1) :=
by ext i; by_cases h1 : p i; by_cases h2 : f i ≠ 0;
 simp at h2; simp [h1, h2]

@[simp] lemma support_filter (f : Π₀ i, β i) :
  (f.filter p).support = f.support.filter p :=
by ext i; by_cases h : p i; simp [h]

lemma subtype_domain_def (f : Π₀ i, β i) :
  f.subtype_domain p = mk (f.support.subtype p) (λ i, f i) :=
by ext i; by_cases h1 : p i; by_cases h2 : f i ≠ 0;
try {simp at h2}; dsimp; simp [h1, h2, ← subtype.val_eq_coe]

@[simp] lemma support_subtype_domain {f : Π₀ i, β i} :
  (subtype_domain p f).support = f.support.subtype p :=
by ext i; by_cases h1 : p i; by_cases h2 : f i ≠ 0;
try {simp at h2}; dsimp; simp [h1, h2]

end filter_and_subtype_domain

end support_basic

lemma support_add [Π i, add_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)] {g₁ g₂ : Π₀ i, β i} :
  (g₁ + g₂).support ⊆ g₁.support ∪ g₂.support :=
support_zip_with

@[simp] lemma support_neg [Π i, add_group (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  {f : Π₀ i, β i} :
  support (-f) = support f :=
by ext i; simp

lemma support_smul {γ : Type w} [semiring γ] [Π i, add_comm_monoid (β i)] [Π i, semimodule γ (β i)]
  [Π ( i : ι) (x : β i), decidable (x ≠ 0)]
  (b : γ) (v : Π₀ i, β i) : (b • v).support ⊆ v.support :=
support_map_range

instance [Π i, has_zero (β i)] [Π i, decidable_eq (β i)] : decidable_eq (Π₀ i, β i) :=
assume f g, decidable_of_iff (f.support = g.support ∧ (∀i∈f.support, f i = g i))
  ⟨assume ⟨h₁, h₂⟩, ext $ assume i,
      if h : i ∈ f.support then h₂ i h else
        have hf : f i = 0, by rwa [f.mem_support_iff, not_not] at h,
        have hg : g i = 0, by rwa [h₁, g.mem_support_iff, not_not] at h,
        by rw [hf, hg],
    by intro h; subst h; simp⟩

section prod_and_sum

variables {γ : Type w}

-- [to_additive sum] for dfinsupp.prod doesn't work, the equation lemmas are not generated
/-- `sum f g` is the sum of `g i (f i)` over the support of `f`. -/
def sum [Π i, has_zero (β i)] [Π i (x : β i), decidable (x ≠ 0)] [add_comm_monoid γ]
  (f : Π₀ i, β i) (g : Π i, β i → γ) : γ :=
∑ i in f.support, g i (f i)

/-- `prod f g` is the product of `g i (f i)` over the support of `f`. -/
@[to_additive]
def prod [Π i, has_zero (β i)] [Π i (x : β i), decidable (x ≠ 0)] [comm_monoid γ]
  (f : Π₀ i, β i) (g : Π i, β i → γ) : γ :=
∏ i in f.support, g i (f i)

@[to_additive]
lemma prod_map_range_index {β₁ : ι → Type v₁} {β₂ : ι → Type v₂}
  [Π i, has_zero (β₁ i)] [Π i, has_zero (β₂ i)]
  [Π i (x : β₁ i), decidable (x ≠ 0)] [Π i (x : β₂ i), decidable (x ≠ 0)] [comm_monoid γ]
  {f : Π i, β₁ i → β₂ i} {hf : ∀ i, f i 0 = 0} {g : Π₀ i, β₁ i} {h : Π i, β₂ i → γ}
  (h0 : ∀i, h i 0 = 1) :
  (map_range f hf g).prod h = g.prod (λi b, h i (f i b)) :=
begin
  rw [map_range_def],
  refine (finset.prod_subset support_mk_subset _).trans _,
  { intros i h1 h2,
    dsimp, simp [h1] at h2, dsimp at h2,
    simp [h1, h2, h0] },
  { refine finset.prod_congr rfl _,
    intros i h1,
    simp [h1] }
end

@[to_additive]
lemma prod_zero_index [Π i, add_comm_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [comm_monoid γ] {h : Π i, β i → γ} : (0 : Π₀ i, β i).prod h = 1 :=
rfl

@[to_additive]
lemma prod_single_index [Π i, has_zero (β i)] [Π i (x : β i), decidable (x ≠ 0)] [comm_monoid γ]
  {i : ι} {b : β i} {h : Π i, β i → γ} (h_zero : h i 0 = 1) :
  (single i b).prod h = h i b :=
begin
  by_cases h : b ≠ 0,
  { simp [dfinsupp.prod, support_single_ne_zero h] },
  { rw [not_not] at h, simp [h, prod_zero_index, h_zero], refl }
end

@[to_additive]
lemma prod_neg_index [Π i, add_group (β i)] [Π i (x : β i), decidable (x ≠ 0)] [comm_monoid γ]
  {g : Π₀ i, β i} {h : Π i, β i → γ} (h0 : ∀i, h i 0 = 1) :
  (-g).prod h = g.prod (λi b, h i (- b)) :=
prod_map_range_index h0

omit dec
@[simp] lemma sum_apply {ι₁ : Type u₁} [decidable_eq ι₁] {β₁ : ι₁ → Type v₁}
  [Π i₁, has_zero (β₁ i₁)] [Π i (x : β₁ i), decidable (x ≠ 0)]
  [Π i, add_comm_monoid (β i)]
  {f : Π₀ i₁, β₁ i₁} {g : Π i₁, β₁ i₁ → Π₀ i, β i} {i₂ : ι} :
  (f.sum g) i₂ = f.sum (λi₁ b, g i₁ b i₂) :=
(f.support.sum_hom (λf : Π₀ i, β i, f i₂)).symm
include dec

lemma support_sum {ι₁ : Type u₁} [decidable_eq ι₁] {β₁ : ι₁ → Type v₁}
  [Π i₁, has_zero (β₁ i₁)] [Π i (x : β₁ i), decidable (x ≠ 0)]
  [Π i, add_comm_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  {f : Π₀ i₁, β₁ i₁} {g : Π i₁, β₁ i₁ → Π₀ i, β i} :
  (f.sum g).support ⊆ f.support.bind (λi, (g i (f i)).support) :=
have ∀i₁ : ι, f.sum (λ (i : ι₁) (b : β₁ i), (g i b) i₁) ≠ 0 →
    (∃ (i : ι₁), f i ≠ 0 ∧ ¬ (g i (f i)) i₁ = 0),
  from assume i₁ h,
  let ⟨i, hi, ne⟩ := finset.exists_ne_zero_of_sum_ne_zero h in
  ⟨i, (f.mem_support_iff i).mp hi, ne⟩,
by simpa [finset.subset_iff, mem_support_iff, finset.mem_bind, sum_apply] using this

@[simp, to_additive] lemma prod_one [Π i, add_comm_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [comm_monoid γ] {f : Π₀ i, β i} :
  f.prod (λi b, (1 : γ)) = 1 :=
finset.prod_const_one

@[simp, to_additive] lemma prod_mul [Π i, add_comm_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [comm_monoid γ] {f : Π₀ i, β i} {h₁ h₂ : Π i, β i → γ} :
  f.prod (λi b, h₁ i b * h₂ i b) = f.prod h₁ * f.prod h₂ :=
finset.prod_mul_distrib

@[simp, to_additive] lemma prod_inv [Π i, add_comm_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [comm_group γ] {f : Π₀ i, β i} {h : Π i, β i → γ} :
  f.prod (λi b, (h i b)⁻¹) = (f.prod h)⁻¹ :=
f.support.prod_hom (@has_inv.inv γ _)

@[to_additive]
lemma prod_add_index [Π i, add_comm_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [comm_monoid γ] {f g : Π₀ i, β i}
  {h : Π i, β i → γ} (h_zero : ∀i, h i 0 = 1) (h_add : ∀i b₁ b₂, h i (b₁ + b₂) = h i b₁ * h i b₂) :
  (f + g).prod h = f.prod h * g.prod h :=
have f_eq : ∏ i in f.support ∪ g.support, h i (f i) = f.prod h,
  from (finset.prod_subset (finset.subset_union_left _ _) $
    by simp [mem_support_iff, h_zero] {contextual := tt}).symm,
have g_eq : ∏ i in f.support ∪ g.support, h i (g i) = g.prod h,
  from (finset.prod_subset (finset.subset_union_right _ _) $
    by simp [mem_support_iff, h_zero] {contextual := tt}).symm,
calc ∏ i in (f + g).support, h i ((f + g) i) =
      ∏ i in f.support ∪ g.support, h i ((f + g) i) :
    finset.prod_subset support_add $
      by simp [mem_support_iff, h_zero] {contextual := tt}
  ... = (∏ i in f.support ∪ g.support, h i (f i)) *
      (∏ i in f.support ∪ g.support, h i (g i)) :
    by simp [h_add, finset.prod_mul_distrib]
  ... = _ : by rw [f_eq, g_eq]

/--
When summing over an `add_monoid_hom`, the decidability assumption is not needed, and the result is
also an `add_monoid_hom`.
-/
def sum_add_hom [Π i, add_monoid (β i)] [add_comm_monoid γ] (φ : Π i, β i →+ γ) :
  (Π₀ i, β i) →+ γ :=
{ to_fun := (λ f,
    quotient.lift_on f (λ x, ∑ i in x.2.to_finset, φ i (x.1 i)) $ λ x y H,
    begin
      have H1 : x.2.to_finset ∩ y.2.to_finset ⊆ x.2.to_finset, from finset.inter_subset_left _ _,
      have H2 : x.2.to_finset ∩ y.2.to_finset ⊆ y.2.to_finset, from finset.inter_subset_right _ _,
      refine (finset.sum_subset H1 _).symm.trans
          ((finset.sum_congr rfl _).trans (finset.sum_subset H2 _)),
      { intros i H1 H2, rw finset.mem_inter at H2, rw H i,
        simp only [multiset.mem_to_finset] at H1 H2,
        rw [(y.3 i).resolve_left (mt (and.intro H1) H2), add_monoid_hom.map_zero] },
      { intros i H1, rw H i },
      { intros i H1 H2, rw finset.mem_inter at H2, rw ← H i,
        simp only [multiset.mem_to_finset] at H1 H2,
        rw [(x.3 i).resolve_left (mt (λ H3, and.intro H3 H1) H2), add_monoid_hom.map_zero] }
    end),
  map_add' := assume f g,
  begin
    refine quotient.induction_on f (λ x, _),
    refine quotient.induction_on g (λ y, _),
    change ∑ i in _, _ = (∑ i in _, _) + (∑ i in _, _),
    simp only, conv { to_lhs, congr, skip, funext, rw add_monoid_hom.map_add },
    simp only [finset.sum_add_distrib],
    congr' 1,
    { refine (finset.sum_subset _ _).symm,
      { intro i, simp only [multiset.mem_to_finset, multiset.mem_add], exact or.inl },
      { intros i H1 H2, simp only [multiset.mem_to_finset, multiset.mem_add] at H2,
        rw [(x.3 i).resolve_left H2, add_monoid_hom.map_zero] } },
    { refine (finset.sum_subset _ _).symm,
      { intro i, simp only [multiset.mem_to_finset, multiset.mem_add], exact or.inr },
      { intros i H1 H2, simp only [multiset.mem_to_finset, multiset.mem_add] at H2,
        rw [(y.3 i).resolve_left H2, add_monoid_hom.map_zero] } }
  end,
  map_zero' := rfl }

@[simp] lemma sum_add_hom_single [Π i, add_monoid (β i)] [add_comm_monoid γ]
  (φ : Π i, β i →+ γ) (i) (x : β i) : sum_add_hom φ (single i x) = φ i x :=
(add_zero _).trans $ congr_arg (φ i) $ show (if H : i ∈ ({i} : finset _) then x else 0) = x,
from dif_pos $ finset.mem_singleton_self i

@[simp] lemma sum_add_hom_comp_single [Π i, add_comm_monoid (β i)] [add_comm_monoid γ]
  (f : Π i, β i →+ γ) (i : ι) :
  (sum_add_hom f).comp (single_add_hom β i) = f i :=
add_monoid_hom.ext $ λ x, sum_add_hom_single f i x

/-- While we didn't need decidable instances to define it, we do to reduce it to a sum -/
lemma sum_add_hom_apply [Π i, add_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [add_comm_monoid γ] (φ : Π i, β i →+ γ) (f : Π₀ i, β i) :
  sum_add_hom φ f = f.sum (λ x, φ x) :=
begin
  refine quotient.induction_on f (λ x, _),
  change ∑ i in _, _ = (∑ i in finset.filter _ _, _),
  rw [finset.sum_filter, finset.sum_congr rfl],
  intros i _,
  dsimp only,
  split_ifs,
  refl,
  rw [(not_not.mp h), add_monoid_hom.map_zero],
end

/-- The `dfinsupp` version of `finsupp.lift_add_hom`,-/
@[simps apply symm_apply]
def lift_add_hom [Π i, add_monoid (β i)] [add_comm_monoid γ] :
  (Π i, β i →+ γ) ≃+ ((Π₀ i, β i) →+ γ) :=
{ to_fun := sum_add_hom,
  inv_fun := λ F i, F.comp (single_add_hom β i),
  left_inv := λ x, by { ext, simp },
  right_inv := λ ψ, by { ext, simp },
  map_add' := λ F G, by { ext, simp } }

/-- The `dfinsupp` version of `finsupp.lift_add_hom_single_add_hom`,-/
@[simp] lemma lift_add_hom_single_add_hom [Π i, add_comm_monoid (β i)] :
  lift_add_hom (single_add_hom β) = add_monoid_hom.id (Π₀ i, β i) :=
lift_add_hom.to_equiv.apply_eq_iff_eq_symm_apply.2 rfl

/-- The `dfinsupp` version of `finsupp.lift_add_hom_apply_single`,-/
lemma lift_add_hom_apply_single [Π i, add_comm_monoid (β i)] [add_comm_monoid γ]
  (f : Π i, β i →+ γ) (i : ι) (x : β i) :
  lift_add_hom f (single i x) = f i x :=
by simp

/-- The `dfinsupp` version of `finsupp.lift_add_hom_comp_single`,-/
lemma lift_add_hom_comp_single [Π i, add_comm_monoid (β i)] [add_comm_monoid γ]
  (f : Π i, β i →+ γ) (i : ι) :
  (lift_add_hom f).comp (single_add_hom β i) = f i :=
by simp

/-- The `dfinsupp` version of `finsupp.comp_lift_add_hom`,-/
lemma comp_lift_add_hom {δ : Type*} [Π i, add_comm_monoid (β i)] [add_comm_monoid γ]
  [add_comm_monoid δ]
  (g : γ →+ δ) (f : Π i, β i →+ γ) :
  g.comp (lift_add_hom f) = lift_add_hom (λ a, g.comp (f a)) :=
lift_add_hom.symm_apply_eq.1 $ funext $ λ a,
  by rw [lift_add_hom_symm_apply, add_monoid_hom.comp_assoc, lift_add_hom_comp_single]

lemma sum_sub_index [Π i, add_comm_group (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [add_comm_group γ] {f g : Π₀ i, β i}
  {h : Π i, β i → γ} (h_sub : ∀i b₁ b₂, h i (b₁ - b₂) = h i b₁ - h i b₂) :
  (f - g).sum h = f.sum h - g.sum h :=
begin
  have := (lift_add_hom (λ a, add_monoid_hom.of_map_sub (h a) (h_sub a))).map_sub f g,
  rw [lift_add_hom_apply, sum_add_hom_apply, sum_add_hom_apply, sum_add_hom_apply] at this,
  exact this,
end

@[to_additive]
lemma prod_finset_sum_index {γ : Type w} {α : Type x}
  [Π i, add_comm_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [comm_monoid γ]
  {s : finset α} {g : α → Π₀ i, β i}
  {h : Π i, β i → γ} (h_zero : ∀i, h i 0 = 1) (h_add : ∀i b₁ b₂, h i (b₁ + b₂) = h i b₁ * h i b₂) :
  ∏ i in s, (g i).prod h = (∑ i in s, g i).prod h :=
begin
  classical,
  exact finset.induction_on s
  (by simp [prod_zero_index])
  (by simp [prod_add_index, h_zero, h_add] {contextual := tt})
end

@[to_additive]
lemma prod_sum_index  {ι₁ : Type u₁} [decidable_eq ι₁] {β₁ : ι₁ → Type v₁}
  [Π i₁, has_zero (β₁ i₁)] [Π i (x : β₁ i), decidable (x ≠ 0)]
  [Π i, add_comm_monoid (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [comm_monoid γ]
  {f : Π₀ i₁, β₁ i₁} {g : Π i₁, β₁ i₁ → Π₀ i, β i}
  {h : Π i, β i → γ} (h_zero : ∀i, h i 0 = 1) (h_add : ∀i b₁ b₂, h i (b₁ + b₂) = h i b₁ * h i b₂) :
  (f.sum g).prod h = f.prod (λi b, (g i b).prod h) :=
(prod_finset_sum_index h_zero h_add).symm

@[simp] lemma sum_single [Π i, add_comm_monoid (β i)]
  [Π i (x : β i), decidable (x ≠ 0)] {f : Π₀ i, β i} :
  f.sum single = f :=
begin
  have := add_monoid_hom.congr_fun lift_add_hom_single_add_hom f,
  rw [lift_add_hom_apply, sum_add_hom_apply] at this,
  exact this,
end

/-- The `dfinsupp` version of `finsupp.lsum`,-/
@[simps apply symm_apply]
def lsum {R : Type*} [semiring R] [Π i, add_comm_monoid (β i)] [Π i, semimodule R (β i)]
  [add_comm_monoid γ] [semimodule R γ] :
    (Π i, β i →ₗ[R] γ) ≃+ ((Π₀ i, β i) →ₗ[R] γ) :=
{ to_fun := λ F, {
    to_fun := sum_add_hom (λ i, (F i).to_add_monoid_hom),
    map_add' := (lift_add_hom (λ i, (F i).to_add_monoid_hom)).map_add,
    map_smul' := λ c f, by {
      apply dfinsupp.induction f,
      { rw [smul_zero, add_monoid_hom.map_zero, smul_zero] },
      { intros a b f ha hb hf,
        rw [smul_add, add_monoid_hom.map_add, add_monoid_hom.map_add, smul_add, hf, ←single_smul,
          sum_add_hom_single, sum_add_hom_single, linear_map.to_add_monoid_hom_coe,
          linear_map.map_smul], } } },
  inv_fun := λ F i, F.comp (lsingle β R i),
  left_inv := λ F, by { ext x y, simp },
  right_inv := λ F, by { ext x y, simp },
  map_add' := λ F G, by { ext x y, simp } }

@[to_additive]
lemma prod_subtype_domain_index [Π i, has_zero (β i)] [Π i (x : β i), decidable (x ≠ 0)]
  [comm_monoid γ] {v : Π₀ i, β i} {p : ι → Prop} [decidable_pred p]
  {h : Π i, β i → γ} (hp : ∀ x ∈ v.support, p x) :
  (v.subtype_domain p).prod (λi b, h i b) = v.prod h :=
finset.prod_bij (λp _, p)
  (by simp) (by simp)
  (assume ⟨a₀, ha₀⟩ ⟨a₁, ha₁⟩, by simp)
  (λ i hi, ⟨⟨i, hp i hi⟩, by simpa using hi, rfl⟩)

omit dec
lemma subtype_domain_sum [Π i, add_comm_monoid (β i)]
  {s : finset γ} {h : γ → Π₀ i, β i} {p : ι → Prop} [decidable_pred p] :
  (∑ c in s, h c).subtype_domain p = ∑ c in s, (h c).subtype_domain p :=
eq.symm (s.sum_hom _)

lemma subtype_domain_finsupp_sum {δ : γ → Type x} [decidable_eq γ]
  [Π c, has_zero (δ c)] [Π c (x : δ c), decidable (x ≠ 0)]
  [Π i, add_comm_monoid (β i)]
  {p : ι → Prop} [decidable_pred p]
  {s : Π₀ c, δ c} {h : Π c, δ c → Π₀ i, β i} :
  (s.sum h).subtype_domain p = s.sum (λc d, (h c d).subtype_domain p) :=
subtype_domain_sum

end prod_and_sum

end dfinsupp
