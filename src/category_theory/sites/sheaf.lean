/-
Copyright (c) 2020 Bhavik Mehta, E. W. Ayers. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bhavik Mehta, E. W. Ayers
-/

import category_theory.sites.grothendieck
import category_theory.sites.pretopology
import category_theory.full_subcategory
import category_theory.types
import tactic.equiv_rw

universes v u
namespace category_theory

open category_theory category limits sieve classical

variables {C : Type u} [category.{v} C]

namespace sheaf
namespace grothendieck_topology

variables {P : Cᵒᵖ ⥤ Type v}
variables {X Y : C} {S : sieve X} {R : presieve X}
variables (J J₂ : grothendieck_topology C)

/--
A family of elements for a presheaf `P` given a collection of arrows `R` with fixed codomain `X`
consists of an element of `P Y` for every `f : Y ⟶ X` in `R`.
A presheaf is a sheaf (resp, separated) if every *consistent* family of elements has exactly one
(resp, at most one) amalgamation.
-/
def family_of_elements (P : Cᵒᵖ ⥤ Type v) (R : presieve X) :=
Π ⦃Y : C⦄ (f : Y ⟶ X), R f → P.obj (opposite.op Y)

/--
A family of elements for a presheaf on the arrow set `R₂` can be restricted to a smaller collection
of arrows `R₁`.
-/
def family_of_elements.restrict {R₁ R₂ : presieve X} (h : R₁ ≤ R₂) :
  family_of_elements P R₂ → family_of_elements P R₁ :=
λ x Y f hf, x f (h _ hf)

/--
A family of elements for the arrow set `R` is consistent if for any `f₁ : Y₁ ⟶ X` and `f₂ : Y₂ ⟶ X`
in `R`, and any `g₁ : Z ⟶ Y₁` and `g₂ : Z ⟶ Y₂`, if the square `g₁ ≫ f₁ = g₂ ≫ f₂` commutes then
the elements of `P Z` obtained by restricting the element of `P Y₁` along `g₁` and restricting
the element of `P Y₂` along `g₂` are the same.
-/
def family_of_elements.consistent (x : family_of_elements P R) : Prop :=
∀ ⦃Y₁ Y₂ Z⦄ (g₁ : Z ⟶ Y₁) (g₂ : Z ⟶ Y₂) ⦃f₁ : Y₁ ⟶ X⦄ ⦃f₂ : Y₂ ⟶ X⦄
  (h₁ : R f₁) (h₂ : R f₂), g₁ ≫ f₁ = g₂ ≫ f₂ → P.map g₁.op (x f₁ h₁) = P.map g₂.op (x f₂ h₂)

def family_of_elements.pullback_consistent (x : family_of_elements P R) [has_pullbacks C] : Prop :=
∀ ⦃Y₁ Y₂⦄ ⦃f₁ : Y₁ ⟶ X⦄ ⦃f₂ : Y₂ ⟶ X⦄ (h₁ : R f₁) (h₂ : R f₂),
  P.map (pullback.fst : pullback f₁ f₂ ⟶ _).op (x f₁ h₁) = P.map pullback.snd.op (x f₂ h₂)

lemma is_pullback_consistent_iff (x : family_of_elements P S) [has_pullbacks C] :
  x.consistent ↔ x.pullback_consistent :=
begin
  split,
  { intros t Y₁ Y₂ f₁ f₂ hf₁ hf₂,
    apply t,
    apply pullback.condition },
  { intros t Y₁ Y₂ Z g₁ g₂ f₁ f₂ hf₁ hf₂ comm,
    rw [←pullback.lift_fst _ _ comm, op_comp, functor_to_types.map_comp_apply, t hf₁ hf₂,
        ←functor_to_types.map_comp_apply, ←op_comp, pullback.lift_snd] }
end

/-- The restriction of a consistent family is consistent. -/
lemma family_of_elements.consistent.restrict {R₁ R₂ : presieve X} (h : R₁ ≤ R₂)
  {x : family_of_elements P R₂} : x.consistent → (x.restrict h).consistent :=
λ q Y₁ Y₂ Z g₁ g₂ f₁ f₂ h₁ h₂ comm, q g₁ g₂ (h _ h₁) (h _ h₂) comm

/-- Extend a family of elements to the sieve generated by an arrow set. -/
noncomputable def family_of_elements.sieve_extend (x : family_of_elements P R) :
  family_of_elements P (generate R) :=
λ Z f hf, P.map (some (some_spec hf)).op (x _ (some_spec (some_spec (some_spec hf))).1)

/-- The extension of a consistent family to the generated sieve is consistent. -/
lemma family_of_elements.consistent.sieve_extend (x : family_of_elements P R) (hx : x.consistent) :
  x.sieve_extend.consistent :=
begin
  intros Y₁ Y₂ Z g₁ g₂ f₁ f₂ h₁ h₂ comm,
  rw [←(some_spec (some_spec (some_spec h₁))).2, ←(some_spec (some_spec (some_spec h₂))).2,
      ←assoc, ←assoc] at comm,
  dsimp [family_of_elements.sieve_extend],
  rw [← functor_to_types.map_comp_apply, ← functor_to_types.map_comp_apply],
  apply hx _ _ _ _ comm,
end

/-- The extension of a family agrees with the original family. -/
lemma extend_agrees {x : family_of_elements P R} (t : x.consistent) {f : Y ⟶ X} (hf : R f) :
  x.sieve_extend f ⟨_, 𝟙 _, f, hf, id_comp _⟩ = x f hf :=
begin
  have h : (generate R) f := ⟨_, _, _, hf, id_comp _⟩,
  change P.map (some (some_spec h)).op (x _ _) = x f hf,
  rw t (some (some_spec h)) (𝟙 _) _ hf _,
  { simp },
  simp_rw [id_comp],
  apply (some_spec (some_spec (some_spec h))).2,
end

/-- The restriction of an extension is the original. -/
@[simp]
lemma restrict_extend {x : family_of_elements P R} (t : x.consistent) :
  x.sieve_extend.restrict (le_generate R) = x :=
begin
  ext Y f hf,
  exact extend_agrees t hf,
end

/--
If the arrow set for a family of elements is actually a sieve (i.e. it is downward closed) then the
consistency condition can be simplified.
This is an equivalent condition, see `is_sieve_consistent_iff`.
-/
def family_of_elements.sieve_consistent (x : family_of_elements P S) : Prop :=
∀ ⦃Y Z⦄ (f : Y ⟶ X) (g : Z ⟶ Y) (hf), x (g ≫ f) (S.downward_closed hf g) = P.map g.op (x f hf)

lemma is_sieve_consistent_iff (x : family_of_elements P S) :
  x.consistent ↔ x.sieve_consistent :=
begin
  split,
  { intros h Y Z f g hf,
    simpa using h (𝟙 _) g (S.downward_closed hf g) hf (id_comp _) },
  { intros h Y₁ Y₂ Z g₁ g₂ f₁ f₂ h₁ h₂ k,
    simp_rw [← h f₁ g₁ h₁, k, h f₂ g₂ h₂] }
end

lemma family_of_elements.consistent.to_sieve_consistent {x : family_of_elements P S}
  (t : x.consistent) : x.sieve_consistent :=
(is_sieve_consistent_iff x).1 t

lemma restrict_inj {x₁ x₂ : family_of_elements P (generate R)}
  (t₁ : x₁.consistent) (t₂ : x₂.consistent) :
  x₁.restrict (le_generate R) = x₂.restrict (le_generate R) → x₁ = x₂ :=
begin
  intro h,
  ext Z f ⟨Y, f, g, hg, rfl⟩,
  rw is_sieve_consistent_iff at t₁ t₂,
  erw [t₁ g f ⟨_, _, g, hg, id_comp _⟩, t₂ g f ⟨_, _, g, hg, id_comp _⟩],
  congr' 1,
  apply congr_fun (congr_fun (congr_fun h _) g) hg,
end

@[simp]
lemma extend_restrict {x : family_of_elements P (generate R)} (t : x.consistent) :
  (x.restrict (le_generate R)).sieve_extend = x :=
begin
  apply restrict_inj,
  { exact (t.restrict (le_generate R)).sieve_extend _ },
  { exact t },
  rw restrict_extend,
  exact t.restrict (le_generate R),
end

def is_amalgamation_for (x : family_of_elements P R)
  (t : P.obj (opposite.op X)) : Prop :=
∀ ⦃Y : C⦄ (f : Y ⟶ X) (h : R f), P.map f.op t = x f h

lemma is_consistent_of_exists_amalgamation (x : family_of_elements P R)
  (h : ∃ t, is_amalgamation_for x t) : x.consistent :=
begin
  cases h with t ht,
  intros Y₁ Y₂ Z g₁ g₂ f₁ f₂ h₁ h₂ comm,
  rw [←ht _ h₁, ←ht _ h₂, ←functor_to_types.map_comp_apply, ←op_comp, comm],
  simp,
end

lemma is_amalgamation_for_restrict {R₁ R₂ : presieve X} (h : R₁ ≤ R₂)
  (x : family_of_elements P R₂) (t : P.obj (opposite.op X)) (ht : is_amalgamation_for x t) :
  is_amalgamation_for (x.restrict h) t :=
λ Y f hf, ht f (h Y hf)

lemma is_amalgamation_for_extend {R : presieve X}
  (x : family_of_elements P R) (t : P.obj (opposite.op X)) (ht : is_amalgamation_for x t) :
  is_amalgamation_for x.sieve_extend t :=
begin
  intros Y f hf,
  dsimp [family_of_elements.sieve_extend],
  rw [←ht _, ←functor_to_types.map_comp_apply, ←op_comp, (some_spec (some_spec (some_spec hf))).2],
end

def is_separated_for (P : Cᵒᵖ ⥤ Type v) (R : presieve X) : Prop :=
∀ (x : family_of_elements P R) (t₁ t₂),
  is_amalgamation_for x t₁ → is_amalgamation_for x t₂ → t₁ = t₂

lemma is_separated_for.ext {R : presieve X} (hR : is_separated_for P R)
  {t₁ t₂ : P.obj (opposite.op X)} (h : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : R f), P.map f.op t₁ = P.map f.op t₂) :
t₁ = t₂ :=
hR (λ Y f hf, P.map f.op t₂) t₁ t₂ (λ Y f hf, h hf) (λ Y f hf, rfl)

lemma is_separated_for_iff_generate :
  is_separated_for P R ↔ is_separated_for P (generate R) :=
begin
  split,
  { intros h x t₁ t₂ ht₁ ht₂,
    apply h (x.restrict (le_generate R)) t₁ t₂ _ _,
    { exact is_amalgamation_for_restrict _ x t₁ ht₁ },
    { exact is_amalgamation_for_restrict _ x t₂ ht₂ } },
  { intros h x t₁ t₂ ht₁ ht₂,
    apply h (x.sieve_extend),
    { exact is_amalgamation_for_extend x t₁ ht₁ },
    { exact is_amalgamation_for_extend x t₂ ht₂ } }
end

lemma is_separated_for_top (P : Cᵒᵖ ⥤ Type v) : is_separated_for P (⊤ : presieve X) :=
λ x t₁ t₂ h₁ h₂,
begin
  have q₁ := h₁ (𝟙 X) trivial,
  have q₂ := h₂ (𝟙 X) trivial,
  simp only [op_id, functor_to_types.map_id_apply] at q₁ q₂,
  rw [q₁, q₂],
end

def is_sheaf_for (P : Cᵒᵖ ⥤ Type v) (R : presieve X) : Prop :=
∀ (x : family_of_elements P R), x.consistent → ∃! t, is_amalgamation_for x t

def is_yoneda_extension (f : S.functor ⟶ P) (g : yoneda.obj X ⟶ P) : Prop :=
S.functor_inclusion ≫ g = f

def yoneda_sheaf_condition (P : Cᵒᵖ ⥤ Type v) (S : sieve X) : Prop :=
∀ (f : S.functor ⟶ P), ∃! g, is_yoneda_extension f g

example {α : Sort*} {p q : α → Prop} : (∀ (x : {a // p a}), q x.1) ↔ ∀ a, p a → q a :=
begin
  simpa only [subtype.forall, subtype.val_eq_coe],
end

def nat_trans_equiv_consistent_family :
  (S.functor ⟶ P) ≃ {x : family_of_elements P S // x.consistent} :=
{ to_fun := λ α,
  begin
    refine ⟨λ Y f hf, _, _⟩,
    { apply α.app (opposite.op Y) ⟨_, hf⟩ },
    { rw is_sieve_consistent_iff,
      intros Y Z f g hf,
      dsimp,
      rw ← functor_to_types.naturality _ _ α g.op,
      refl }
  end,
  inv_fun := λ t,
  { app := λ Y f, t.1 _ f.2,
    naturality' := λ Y Z g,
    begin
      ext ⟨f, hf⟩,
      apply t.2.to_sieve_consistent _,
    end },
  left_inv := λ α,
  begin
    ext X ⟨_, _⟩,
    refl
  end,
  right_inv :=
  begin
    rintro ⟨x, hx⟩,
    refl,
  end }

def yoneda_equiv {F : Cᵒᵖ ⥤ Type v} : (yoneda.obj X ⟶ F) ≃ F.obj (opposite.op X) :=
(yoneda_sections X F).to_equiv.trans equiv.ulift

lemma extension_iff_amalgamation (x : S.functor ⟶ P) (g : yoneda.obj X ⟶ P) :
  is_yoneda_extension x g ↔ is_amalgamation_for (nat_trans_equiv_consistent_family x).1 (yoneda_equiv g) :=
begin
  dsimp [is_amalgamation_for, yoneda_equiv, yoneda_lemma, nat_trans_equiv_consistent_family,
         is_yoneda_extension],
  split,
  { rintro rfl,
    intros Y f hf,
    rw ← functor_to_types.naturality _ _ g,
    dsimp,
    simp },
  { intro h,
    ext Y ⟨f, hf⟩,
    have : _ = x.app Y _ := h f hf,
    rw [← this, ← functor_to_types.naturality _ _ g],
    dsimp, simp },
end

lemma equiv.exists_unique_congr {α β : Type*} (p : β → Prop) (e : α ≃ β) :
  (∃! (y : β), p y) ↔ ∃! (x : α), p (e x) :=
begin
  split,
  { rintro ⟨b, hb₁, hb₂⟩,
    exact ⟨e.symm b, by simpa using hb₁, λ x hx, by simp [←hb₂ (e x) hx]⟩ },
  { rintro ⟨a, ha₁, ha₂⟩,
    refine ⟨e a, ha₁, λ y hy, _⟩,
    rw ← equiv.symm_apply_eq,
    apply ha₂,
    simpa using hy },
end

lemma yoneda_condition_iff_sheaf_condition :
  is_sheaf_for P S ↔ yoneda_sheaf_condition P S :=
begin
  rw [is_sheaf_for, yoneda_sheaf_condition],
  simp_rw [extension_iff_amalgamation],
  rw equiv.forall_congr_left' nat_trans_equiv_consistent_family,
  rw subtype.forall,
  apply ball_congr,
  intros x hx,
  rw ← equiv.exists_unique_congr _ _,
  simp,
end

lemma separated_for_and_exists_amalgamation_iff_sheaf_for :
  is_separated_for P R ∧ (∀ (x : family_of_elements P R), x.consistent → ∃ t, is_amalgamation_for x t) ↔ is_sheaf_for P R :=
begin
  rw [is_separated_for, ←forall_and_distrib],
  apply forall_congr,
  intro x,
  split,
  { intros z hx, exact exists_unique_of_exists_of_unique (z.2 hx) z.1 },
  { intros h,
    refine ⟨_, (exists_of_exists_unique ∘ h)⟩,
    intros t₁ t₂ ht₁ ht₂,
    apply (h _).unique ht₁ ht₂,
    exact is_consistent_of_exists_amalgamation x ⟨_, ht₂⟩ }
end

lemma is_separated_for.is_sheaf_for (t : is_separated_for P R) :
  (∀ (x : family_of_elements P R), x.consistent → ∃ t, is_amalgamation_for x t) →
  is_sheaf_for P R :=
begin
  rw ← separated_for_and_exists_amalgamation_iff_sheaf_for,
  apply and.intro t,
end

noncomputable def is_sheaf_for.amalgamate
  (t : is_sheaf_for P R) (x : family_of_elements P R) (hx : x.consistent) :
  P.obj (opposite.op X) :=
classical.some ((t x hx).exists)

lemma is_sheaf_for.is_amalgamation_for
  (t : is_sheaf_for P R) {x : family_of_elements P R} (hx : x.consistent) :
  is_amalgamation_for x (t.amalgamate x hx) :=
classical.some_spec ((t x hx).exists)

@[simp]
lemma is_sheaf_for.valid_glue
  (t : is_sheaf_for P R) {x : family_of_elements P R} (hx : x.consistent) (f : Y ⟶ X) (Hf : R f) :
  P.map f.op (t.amalgamate x hx) = x f Hf :=
classical.some_spec ((t x hx).exists) f Hf

lemma is_sheaf_for.is_separated_for : is_sheaf_for P R → is_separated_for P R :=
λ q, (separated_for_and_exists_amalgamation_iff_sheaf_for.2 q).1

/-- C2.1.3 in Elephant -/
lemma is_sheaf_for_iff_generate :
  is_sheaf_for P R ↔ is_sheaf_for P (generate R) :=
begin
  rw ← separated_for_and_exists_amalgamation_iff_sheaf_for,
  rw ← separated_for_and_exists_amalgamation_iff_sheaf_for,
  rw ← is_separated_for_iff_generate,
  apply and_congr (iff.refl _),
  split,
  { intros q x hx,
    apply exists_imp_exists _ (q _ (hx.restrict (le_generate R))),
    intros t ht,
    simpa [hx] using is_amalgamation_for_extend _ _ ht },
  { intros q x hx,
    apply exists_imp_exists _ (q _ (hx.sieve_extend _)),
    intros t ht,
    simpa [hx] using is_amalgamation_for_restrict (le_generate R) _ _ ht },
end

/--
Every presheaf is a sheaf for the family {𝟙 X}.

Elephant: C2.1.5(i)
-/
lemma is_sheaf_for_singleton_iso (P : Cᵒᵖ ⥤ Type v) :
  is_sheaf_for P (presieve.singleton (𝟙 X)) :=
begin
  intros x hx,
  refine ⟨x _ (presieve.singleton_self _), _, _⟩,
  { rintro _ _ ⟨rfl, rfl⟩,
    simp },
  { intros t ht,
    simpa using ht _ (presieve.singleton_self _) }
end

/--
Every presheaf is a sheaf for the maximal sieve.

Elephant: C2.1.5(ii)
-/
lemma is_sheaf_for_top_sieve (P : Cᵒᵖ ⥤ Type v) :
  is_sheaf_for P ((⊤ : sieve X) : presieve X) :=
begin
  rw ← generate_of_singleton_split_epi (𝟙 X),
  rw ← is_sheaf_for_iff_generate,
  apply is_sheaf_for_singleton_iso,
end

/--
If a family of arrows `R` on `X` has a subsieve `S` such that:
* `P` is a sheaf for `S`.
* For every `f` in `R`, `P` is separated for the pullback of `S` along `f`
then `P` is a sheaf for `R`.
-/
lemma is_sheaf_for_subsieve_aux (P : Cᵒᵖ ⥤ Type v) {S : sieve X} {R : presieve X}
  (h : (S : presieve X) ≤ R)
  (hS : is_sheaf_for P S)
  (trans : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄, R f → is_separated_for P (S.pullback f)) :
  is_sheaf_for P R :=
begin
  rw ← separated_for_and_exists_amalgamation_iff_sheaf_for,
  refine ⟨_, _⟩,
  { intros x t₁ t₂ ht₁ ht₂,
    exact hS.is_separated_for _ _ _ (is_amalgamation_for_restrict h x t₁ ht₁)
                                    (is_amalgamation_for_restrict h x t₂ ht₂) },
  { intros x hx,
    use hS.amalgamate _ (hx.restrict h),
    intros W j hj,
    apply (trans hj).ext,
    intros Y f hf,
    rw [←functor_to_types.map_comp_apply, ←op_comp,
        hS.valid_glue (hx.restrict h) _ hf, family_of_elements.restrict,
        ←hx (𝟙 _) f _ _ (id_comp _)],
    simp },
end

lemma is_sheaf_for_subsieve (P : Cᵒᵖ ⥤ Type v) {S : sieve X} {R : presieve X}
  (h : (S : presieve X) ≤ R)
  (trans : Π ⦃Y⦄ (f : Y ⟶ X), is_sheaf_for P (S.pullback f)) :
  is_sheaf_for P R :=
is_sheaf_for_subsieve_aux P h (by simpa using trans (𝟙 _)) (λ Y f hf, (trans f).is_separated_for)

lemma is_sheaf_for_bind (P : Cᵒᵖ ⥤ Type v) (U : sieve X)
  (B : Π ⦃Y⦄ ⦃f : Y ⟶ X⦄, U f → sieve Y)
  (hU : is_sheaf_for P U)
  (hB : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : U f), is_sheaf_for P (B hf))
  (hB' : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : U f) ⦃Z⦄ (g : Z ⟶ Y), is_separated_for P ((B hf).pullback g)) :
  is_sheaf_for P (sieve.bind U B) :=
begin
  intros s hs,
  let y : Π ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : U f), family_of_elements P (B hf) :=
    λ Y f hf Z g hg, s _ (presieve.bind_comp _ _ hg),
  have hy : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : U f), (y hf).consistent,
  { intros Y f H Y₁ Y₂ Z g₁ g₂ f₁ f₂ hf₁ hf₂ comm,
    apply hs,
    apply reassoc_of comm },
  let t : family_of_elements P U,
  { intros Y f hf,
    apply (hB hf).amalgamate (y hf) (hy hf) },
  have ht : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : U f), is_amalgamation_for (y hf) (t f hf),
  { intros Y f hf,
    apply (hB hf).is_amalgamation_for _ },
  have hT : t.consistent,
  { rw is_sieve_consistent_iff,
    intros Z W f h hf,
    apply (hB (U.downward_closed hf h)).is_separated_for.ext,
    intros Y l hl,
    apply (hB' hf (l ≫ h)).ext,
    intros M m hm,
    have : (bind ⇑U B) (m ≫ l ≫ h ≫ f),
    { have : bind U B _ := presieve.bind_comp f hf hm,
      simpa using this },
    transitivity s (m ≫ l ≫ h ≫ f) this,
    { have := ht (U.downward_closed hf h) _ ((B _).downward_closed hl m),
      rw [op_comp, functor_to_types.map_comp_apply] at this,
      rw this,
      change s _ _ = s _ _,
      simp },
    { have : s _ _ = _ := (ht hf _ hm).symm,
      simp only [assoc] at this,
      rw this,
      simp } },
  refine ⟨hU.amalgamate t hT, _, _⟩,
  { rintro Z _ ⟨Y, f, g, hg, hf, rfl⟩,
    rw [op_comp, functor_to_types.map_comp_apply, is_sheaf_for.valid_glue _ _ _ hg],
    apply ht hg _ hf },
  { intros y hy,
    apply hU.is_separated_for.ext,
    intros Y f hf,
    apply (hB hf).is_separated_for.ext,
    intros Z g hg,
    rw [←functor_to_types.map_comp_apply, ←op_comp, hy _ (presieve.bind_comp _ _ hg),
        hU.valid_glue _ _ hf, ht hf _ hg] }
end

lemma is_sheaf_for_trans (P : Cᵒᵖ ⥤ Type v) (R S : sieve X)
  (hR : is_sheaf_for P R)
  (hR' : ∀ ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : S f), is_separated_for P (R.pullback f))
  (hS : Π ⦃Y⦄ ⦃f : Y ⟶ X⦄ (hf : R f), is_sheaf_for P (S.pullback f)) :
  is_sheaf_for P S :=
begin
  have : (bind ⇑R (λ (Y : C) (f : Y ⟶ X) (hf : R f), pullback f S) : presieve X) ≤ S,
  { rintros Z f ⟨W, f, g, hg, (hf : S _), rfl⟩,
    apply hf },
  apply is_sheaf_for_subsieve_aux P this,
  apply is_sheaf_for_bind _ _ _ hR hS,
  { intros Y f hf Z g,
    dsimp,
    rw ← pullback_comp,
    apply (hS (R.downward_closed hf _)).is_separated_for },
  { intros Y f hf,
    have : (sieve.pullback f (bind R (λ T (k : T ⟶ X) (hf : R k), pullback k S))) = R.pullback f,
    { ext Z g,
      split,
      { rintro ⟨W, k, l, hl, _, comm⟩,
        rw [mem_pullback, ← comm],
        simp [hl] },
      { intro a,
        refine ⟨Z, 𝟙 Z, _, a, _⟩,
        simp [hf] } },
    rw this,
    apply hR' hf },
end

/-- Construct the finest Grothendieck topology for which the given presheaf is a sheaf. -/
def finest_topology_single (P : Cᵒᵖ ⥤ Type v) : grothendieck_topology C :=
{ sieves := λ X S, ∀ Y (f : Y ⟶ X), is_sheaf_for P (S.pullback f),
  top_mem' := λ X Y f,
  begin
    rw sieve.pullback_top,
    exact is_sheaf_for_top_sieve P,
  end,
  pullback_stable' := λ X Y S f hS Z g,
  begin
    rw ← pullback_comp,
    apply hS,
  end,
  transitive' := λ X S hS R hR Z g,
  begin
    refine is_sheaf_for_trans P (pullback g S) _ (hS Z g) _ _,
    { intros Y f hf,
      rw ← pullback_comp,
      apply (hS _ _).is_separated_for },
    { intros Y f hf,
      have := hR hf _ (𝟙 _),
      rw [pullback_id, pullback_comp] at this,
      apply this },
  end }

/-- Construct the finest Grothendieck topology for which the given presheaves are sheaves. -/
def finest_topology (Ps : set (Cᵒᵖ ⥤ Type v)) : grothendieck_topology C :=
Inf (finest_topology_single '' Ps)

/-- A presheaf is separated if it is separated for every sieve in the topology. -/
def is_separated (P : Cᵒᵖ ⥤ Type v) : Prop :=
∀ {X} (S : sieve X), S ∈ J X → is_separated_for P S

/-- A presheaf is a sheaf if it is a sheaf for every sieve in the topology. -/
def is_sheaf (P : Cᵒᵖ ⥤ Type v) : Prop :=
∀ {X} (S : sieve X), S ∈ J X → is_sheaf_for P S

def is_sheaf_for_coarser_topology (P : Cᵒᵖ ⥤ Type v) {J₁ J₂ : grothendieck_topology C} (h : J₁ ≤ J₂) :
  is_sheaf J₂ P → is_sheaf J₁ P :=
λ t X S hS, t S (h _ hS)

lemma sheaf_for_finest_topology (Ps : set (Cᵒᵖ ⥤ Type v)) :
  P ∈ Ps → is_sheaf (finest_topology Ps) P :=
begin
  intros h X S hS,
  simpa using hS _ ⟨⟨_, _, ⟨_, h, rfl⟩, rfl⟩, rfl⟩ _ (𝟙 _),
end

lemma is_finest_topology (Ps : set (Cᵒᵖ ⥤ Type v)) (J : grothendieck_topology C)
  (hJ : ∀ P ∈ Ps, is_sheaf J P) : J ≤ finest_topology Ps :=
begin
  intros X S hS,
  rintro _ ⟨⟨_, _, ⟨P, hP, rfl⟩, rfl⟩, rfl⟩,
  intros Y f,
  exact hJ P hP (S.pullback f) (J.pullback_stable f hS),
end

def canonical_topology : grothendieck_topology C :=
finest_topology (set.range yoneda.obj)

lemma separated_of_sheaf (P : Cᵒᵖ ⥤ Type v) (h : is_sheaf J P) : is_separated J P :=
λ X S hS, (h S hS).is_separated_for

#exit

def matching_family (P : Cᵒᵖ ⥤ Type v) (S : sieve X) : Type (max u v) :=
S.functor ⟶ P

def amalgamation {P : Cᵒᵖ ⥤ Type v} {S : sieve X} (γ : matching_family P S) :=
{α : yoneda.obj X ⟶ P // S.functor_inclusion ≫ α = γ}

@[derive subsingleton]
def sheaf_condition_at (S : sieve X) (P : Cᵒᵖ ⥤ Type v) : Type (max u v) :=
Π (γ : matching_family P S), unique (amalgamation γ)

def sheaf_condition_at_top (P : Cᵒᵖ ⥤ Type v) : sheaf_condition_at (⊤ : sieve X) P :=
λ γ,
begin
  refine ⟨⟨⟨inv (⊤:sieve X).functor_inclusion ≫ γ, _⟩⟩, _⟩,
  { simp },
  { rintro ⟨a, ha⟩,
    apply subtype.ext,
    simp [ha] }
end

@[derive subsingleton]
def sheaf_condition (P : Cᵒᵖ ⥤ Type v) : Type (max u v) :=
Π (X : C) (S ∈ J X), sheaf_condition_at S P

def canonical_map (P : Cᵒᵖ ⥤ Type v) (S : sieve X) : (yoneda.obj X ⟶ P) → (S.functor ⟶ P) :=
λ f, S.functor_inclusion ≫ f

def sheaf_condition2 (P : Cᵒᵖ ⥤ Type v) : Prop :=
∀ X (S : sieve X), S ∈ J X → function.bijective (canonical_map P S)

-- noncomputable def sheaf_condition2_equiv (P : Cᵒᵖ ⥤ Type v) : sheaf_condition J P ≃ sheaf_condition2 J P :=
-- { to_fun := λ t X S hS,
--   begin
--     split,
--     { intros α₁ α₂ hα,
--       exact subtype.ext_iff.1 (((t X S _ hS).2 ⟨α₁, hα⟩).trans ((t X S _ hS).2 ⟨α₂, rfl⟩).symm) },
--     { intros γ,
--       exact ⟨_, (t X S γ hS).1.1.2⟩ }
--   end,
--   inv_fun := λ t X S γ hS,
--   begin
--     specialize t X S hS,
--     rw function.bijective_iff_has_inverse at t,
--     choose t ht₁ ht₂ using t,
--     refine ⟨⟨⟨t γ, ht₂ γ⟩⟩, λ a, _⟩,
--     cases a with a ha,
--     apply subtype.ext,
--     dsimp,
--     rw [← ht₁ a, ← ha],
--     refl,
--   end

-- }

def matching_family' (P : Cᵒᵖ ⥤ Type v) {c : C} (S : sieve c) :=
{x : Π {d : C} {f : d ⟶ c}, S.arrows f → P.obj (opposite.op d) //
 ∀ {d e : C} (f : d ⟶ c) (g : e ⟶ d) (h : S.arrows f), x (S.downward_closed h g) = P.map g.op (x h)}

def amalgamation' {P : Cᵒᵖ ⥤ Type v} {c : C} {S : sieve c} (γ : matching_family' P S) :=
{y : P.obj (opposite.op c) // ∀ {d : C} (f : d ⟶ c) (hf : S.arrows f), P.map f.op y = γ.1 hf}

@[derive subsingleton]
def sheaf_condition' (P : Cᵒᵖ ⥤ Type v) : Type (max u v) :=
Π (c : C) (S : sieve c) (γ : matching_family' P S), S ∈ J c → unique (amalgamation' γ)

def matching_family'_equiv_matching_family (P : Cᵒᵖ ⥤ Type v) :
  matching_family' P S ≃ matching_family P S :=
{ to_fun := λ x, ⟨λ _ t, x.1 t.2, λ c c' f, funext $ λ t, x.2 _ _ t.2⟩,
  inv_fun := λ x, ⟨λ d f hf, x.app _ ⟨f, hf⟩, λ d d' f g h, congr_fun (x.2 g.op) ⟨f, h⟩⟩,
  left_inv := λ _, subtype.ext $ funext $ λ _, funext $ λ _, funext $ λ _, rfl,
  right_inv := λ _, by { ext _ ⟨_, _⟩, refl } }

def amalgamation'_equiv_amalgamation (P : Cᵒᵖ ⥤ Type v) (x : matching_family' P S) :
  amalgamation (matching_family'_equiv_matching_family P x) ≃ (amalgamation' x) :=
{ to_fun := λ γ,
  { val := γ.1.app _ (𝟙 X),
    property := λ d f hf,
    begin
      have := congr_fun (γ.1.naturality f.op) (𝟙 _),
      dsimp at this,
      erw ← this,
      rw comp_id,
      have q := congr_arg (λ t, nat_trans.app t (opposite.op d)) γ.2,
      dsimp at q,
      have := congr_fun q ⟨f, hf⟩,
      exact this,
    end },
  inv_fun := λ γ,
  { val :=
    { app := λ c f, P.map f.op γ.1,
      naturality' := λ c c' f, funext $ λ g, functor_to_types.map_comp_apply P g.op f γ.1 },
    property :=
    begin
      ext c ⟨f, hf⟩,
      apply γ.2,
    end },
  left_inv :=
  begin
    rintro ⟨γ₁, γ₂⟩,
    ext d f,
    dsimp,
    rw ← functor_to_types.naturality _ _ γ₁ f.op (𝟙 X),
    dsimp,
    simp,
  end,
  right_inv :=
  begin
    intro γ,
    ext1,
    apply functor_to_types.map_id_apply,
  end }

def sheaf'_equiv_sheaf (P : Cᵒᵖ ⥤ Type v) :
  sheaf_condition J P ≅ sheaf_condition' J P :=
{ hom :=
  begin
    intros h c S γ hS,
    apply equiv.unique (amalgamation'_equiv_amalgamation _ _).symm,
    apply h _ _ hS,
  end,
  inv :=
  begin
    intros h c S hS γ,
    haveI := h _ _ ((matching_family'_equiv_matching_family P).symm γ) hS,
    have := equiv.unique (amalgamation'_equiv_amalgamation P ((matching_family'_equiv_matching_family P).symm γ)),
    simpa using this,
  end }

def finest_topology_sieves (P : Cᵒᵖ ⥤ Type v) : Π (X : C), set (sieve X) :=
λ X S, ∀ Y (f : Y ⟶ X), nonempty (sheaf_condition_at (S.pullback f) P)

def aux_map {Z : C} (S : sieve X) (α : Z ⟶ Y) (f : Y ⟶ X) :
  (S.pullback (α ≫ f)).functor ⟶ (S.pullback f).functor :=
{ app := λ T z, ⟨z.1 ≫ α, by simpa using z.2⟩ }.

def finest_topology (F : Cᵒᵖ ⥤ Type v) : grothendieck_topology C :=
{ sieves := finest_topology_sieves F,
  top_mem' := λ X Y f,
  begin
    rw pullback_top,
    refine ⟨sheaf_condition_at_top _⟩,
  end,
  pullback_stable' := λ X Y S f hS Z g,
  begin
    rw ← pullback_comp,
    apply hS _,
  end,
  transitive' := λ U S hS S' t,
  begin
    intros W f,
    cases hS _ f with hfS,
    refine ⟨λ φ, _⟩,
    let ψ : (S.pullback f).functor ⟶ F,
    { refine ⟨_, _⟩,
      { intros V α,
        have q := t α.2 _ (𝟙 _),
        rw pullback_id at q,
        apply (classical.choice q (aux_map S' α.1 f ≫ φ)).1.1.1.app _ (𝟙 _) },
      { intros V₁ V₂ k,
        sorry,
        -- ext1 α,
        -- dsimp,
        -- have q₁ := t α.2 _ (𝟙 _),
        -- rw pullback_id at q₁,
        -- let z₁ := (classical.choice q₁ (aux_map S' α.1 f ≫ φ)).1.1.1,
        -- have := k.unop ≫ α.1,
        -- -- have q₂ := t (S.downward_closed α.2 k.unop) _ (𝟙 _),
        -- -- rw pullback_id at q₂,
        -- have q₂ : nonempty (sheaf_condition_at (pullback (((pullback f S).functor.map k α).1 ≫ f) S') F),
        --   dsimp [sieve.functor],
        --   rw assoc,
        --   have q₂ := t (S.downward_closed α.2 k.unop) _ (𝟙 _),
        --   rw pullback_id at q₂,
        --   apply q₂,
        -- let z₂ := (classical.choice q₂ (aux_map S' ((S.pullback f).functor.map k α).1 f ≫ φ)).1.1.1,
        -- change z₂.app V₂ (𝟙 _) = F.map k (z₁.app V₁ (𝟙 _)),
        -- have := (classical.choice q₂ (aux_map S' ((S.pullback f).functor.map k α).1 f ≫ φ)).1.1.2,
      }
    },
    refine ⟨⟨⟨(classical.choice (hS _ f) ψ).1.1.1, _⟩⟩, _⟩,
    have := (classical.choice (hS _ f) ψ).1.1.2,
  end
}

variables (C J)

structure Sheaf :=
(P : Cᵒᵖ ⥤ Type v)
(sheaf_cond : sheaf_condition J P)

instance : category (Sheaf C J) := induced_category.category Sheaf.P

end grothendieck_topology
end sheaf

end category_theory
