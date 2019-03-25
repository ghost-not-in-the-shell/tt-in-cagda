
----------------------------------------------------------------------------
--
-- A higher inductive type for a simply typed lambda caculus
-- 
-- Inspired by: Type Theory in Type Theory using Quotient Inductive Types
--              by Thorsten Altenkirch and Ambrus Kaposi
-- See: http://www.cs.nott.ac.uk/~psztxa/publ/tt-in-tt.pdf
-- 
----------------------------------------------------------------------------

{-# OPTIONS --cubical --safe #-}
module STLC.Base where

open import Cubical.Core.Everything renaming (_,_ to <_,_>)
open import Cubical.Foundations.Function

_≡⟨⟩_ : ∀ {ℓ} {A : Set ℓ} {z : A} (x : A) → x ≡ z → x ≡ z
_ ≡⟨⟩ eq = eq
infixr 2 _≡⟨⟩_

open import Foundations.BiinvertibleEquiv

infixl 6 _,_ _,*_
infixr 7 _∘*_
infixr 3 ↑_



-----------------
-- Declarations
-----------------

-- (Total terms are those which step to a value in finite time, while partial terms may not.
--  Thus, the thing which is total/partial here is the evaluation function!)
data Totality : Set where
  Total : Totality
  Partl : Totality


-- We will mutually inductively define:

-- The type of contexts
data Ctx : Set

-- The type of transformations / generalized substitutions from a context Γ to Δ
[_]_~>_ : Totality → Ctx → Ctx → Set

total_~>_ : Ctx → Ctx → Set
total_~>_ = [ Total ]_~>_
_~>_ : Ctx → Ctx → Set
_~>_ = [ Partl ]_~>_

-- The type of types
data Type : Set

-- The type of judgements x : τ ⊣ Γ ("x has type τ in context Γ")
data [_]_⊣_ : Totality → Type → Ctx → Set

total_⊣_ : Type → Ctx → Set
total_⊣_ = [ Total ]_⊣_
_⊣_ : Type → Ctx → Set
_⊣_ = [ Partl ]_⊣_

variable
  Γ Δ Ε Ζ : Ctx
  τ σ ρ : Type
  x y z : τ ⊣ Γ
  k : Totality



---------------------------------
-- Contexts and Transformations
---------------------------------

data Ctx where
  ε : Ctx
  _,_ : Ctx → Type → Ctx

append : Ctx → Ctx → Ctx
append Γ ε = Γ
append Γ (Δ , x) = append Γ Δ , x

-- A proof that a type is in a context is an index at which it appears
data _∈_ : Type → Ctx → Set where
  zero : τ ∈ (Γ , τ)
  suc  : τ ∈ Γ → τ ∈ (Γ , σ)

∈-Rec : ∀ {ℓ} (P : ∀ τ Γ → Set ℓ)
        → (∀ {τ Γ} → P τ (Γ , τ))
        → (∀ {σ τ Γ} → P τ Γ → P τ (Γ , σ))
        → ∀ {τ Γ} → τ ∈ Γ → P τ Γ
∈-Rec P z s zero = z
∈-Rec P z s (suc i) = s (∈-Rec P z s i)


-- Transformations Γ ~> Δ are maps from elements of Γ to terms τ ⊣ Δ
[ k ] Γ ~> Δ = ∀ τ (i : τ ∈ Γ) → ([ k ] τ ⊣ Δ)

~>Ext : {f g : [ k ] Γ ~> Δ} → (∀ τ i → f τ i ≡ g τ i) → f ≡ g
~>Ext eq j = λ τ i → eq τ i j

-- ~> has a list structure on its first argument

ε* : [ k ] ε ~> Δ
ε* τ ()

_,*_ : ([ k ] Γ ~> Δ) → (x : [ k ] τ ⊣ Δ) → [ k ] (Γ , τ) ~> Δ
(f ,* x) τ zero = x
(f ,* x) τ (suc i) = f τ i

head* : ([ k ] (Γ , τ) ~> Δ) → [ k ] τ ⊣ Δ
head* f = f _ zero

tail* : ([ k ] (Γ , τ) ~> Δ) → [ k ] Γ ~> Δ
tail* f τ i = f τ (suc i)

-- ~> also forms a category (using var and sub from _⊣_, which has yet to be defined)

id* : [ k ] Γ ~> Γ
-- id* τ i = var i

_∘*_ : ([ k ] Δ ~> Ε) → ([ k ] Γ ~> Δ) → [ k ] Γ ~> Ε
-- (g ∘* f) τ i = sub g (f τ i)

-- Some useful derived notions:

wkn : [ k ] Γ ~> (Γ , τ)
wkn = tail* id*

↑_ : (f : [ k ] Γ ~> Δ) → [ k ] (Γ , τ) ~> (Δ , τ)
↑ f = (wkn ∘* f) ,* head* id*

⟨_⟩ : (x : [ k ] τ ⊣ Γ) → [ k ] (Γ , τ) ~> Γ
⟨ x ⟩ = id* ,* x



--------------------
-- Types and Terms
--------------------

data Type where
  _⇒_ : Type → Type → Type
  Nat : Type

-- ...
unlamʳ unlamˡ : (f : [ k ] (σ ⇒ τ) ⊣ Γ) → [ k ] τ ⊣ (Γ , σ)
-- unlamʳ y = apʳ (sub wkn y) (var zero)
-- unlamˡ y = apˡ (sub wkn y) (var zero)

data [_]_⊣_ where

  -- permit arbitrary substutions on contexts
  sub : (f : [ k ] Γ ~> Δ) (x : [ k ] τ ⊣ Γ) → [ k ] τ ⊣ Δ

  -- sub is a functor on (~>, id*, ∘*)
  sub-id* : (x : [ k ] τ ⊣ Γ) → sub id* x ≡ x
  sub-∘*  : (g : [ k ] Δ ~> Ε) (f : [ k ] Γ ~> Δ) (x : [ k ] τ ⊣ Γ)
            → sub (g ∘* f) x ≡ sub g (sub f x)

  -- variables as de Bruijn indices
  var : (i : τ ∈ Γ) → [ k ] τ ⊣ Γ

  -- function type intro
  lam : (x : [ k ] τ ⊣ (Γ , σ)) → [ k ] (σ ⇒ τ) ⊣ Γ

  -- function type elim (left) and β
  apˡ    : (y : [ k ] (σ ⇒ τ) ⊣ Γ) (z : [ k ] σ ⊣ Γ) → [ k ] τ ⊣ Γ
  lam-βˡ : (x : [ k ] τ ⊣ (Γ , σ)) (z : [ k ] σ ⊣ Γ) → apˡ (lam x) z ≡ sub ⟨ z ⟩ x

  -- function type elim (right) and η
  apʳ        : (y : [ k ] (σ ⇒ τ) ⊣ Γ) (z : [ k ] σ ⊣ Γ) → [ k ] τ ⊣ Γ
  lam-ηʳ     : (y : [ k ] (σ ⇒ τ) ⊣ Γ) → lam (unlamʳ y) ≡ y -- recall that unlamʳ y = apʳ (sub wkn y) (var zero)
  apʳ-unlamˡ : (y : [ k ] (σ ⇒ τ) ⊣ Γ) (z : [ k ] σ ⊣ Γ) → apʳ y z ≡ sub ⟨ z ⟩ (unlamˡ y)

  -- fix intro and β (not total!)
  fix   : (y : (τ ⇒ τ) ⊣ Γ) → τ ⊣ Γ
  fix-β : (y : (τ ⇒ τ) ⊣ Γ) → fix y ≡ apˡ y (fix y)

  -- natural number intro and elim
  zero : [ k ] Nat ⊣ Γ
  suc  : (n : [ k ] Nat ⊣ Γ) → [ k ] Nat ⊣ Γ
  recNat : (z : [ k ] τ ⊣ Γ) (s : [ k ] τ ⊣ (Γ , Nat , τ)) (n : [ k ] Nat ⊣ Γ) → [ k ] τ ⊣ Γ

  -- natural number β
  recNat-zero : (z : [ k ] τ ⊣ Γ) (s : [ k ] τ ⊣ (Γ , Nat , τ))
                → recNat z s zero ≡ z
  recNat-suc  : (z : [ k ] τ ⊣ Γ) (s : [ k ] τ ⊣ (Γ , Nat , τ)) (n : [ k ] Nat ⊣ Γ)
                → recNat z s (suc n) ≡ sub (id* ,* n ,* recNat z s n) s

  -- computation rules for substititon
  sub-var : (f : [ k ] Γ ~> Δ) (i : τ ∈ Γ) → sub f (var i) ≡ f τ i
  sub-lam : (f : [ k ] Γ ~> Δ) (x : [ k ] τ ⊣ (Γ , σ))
            → sub f (lam x) ≡ lam (sub (↑ f) x)
  -- sub-ap will be derivable using lam-β and lam-η!
  sub-zero : (f : [ k ] Γ ~> Δ) → sub f zero ≡ zero
  sub-suc  : (f : [ k ] Γ ~> Δ) (n : [ k ] Nat ⊣ Γ) → sub f (suc n) ≡ suc (sub f n)
  sub-recNat : (f : [ k ] Γ ~> Δ) (z : [ k ] τ ⊣ Γ) (s : [ k ] τ ⊣ (Γ , Nat , τ)) (n : [ k ] Nat ⊣ Γ)
               → sub f (recNat z s n) ≡ recNat (sub f z) (sub (↑ ↑ f) s) (sub f n)

-- Skipped definitions now that everything is is scope:
id* τ i = var i
(g ∘* f) τ i = sub g (f τ i)
unlamˡ y = apˡ (sub wkn y) (var zero)
unlamʳ y = apʳ (sub wkn y) (var zero)



---------------------
-- First Properties
---------------------

-- the list structure on ~> behaves as one would expect:

ε*-η : ∀ (f : [ k ] ε ~> Δ) → f ≡ ε*
ε*-η f = ~>Ext t'
  where t' : ∀ τ i → f τ i ≡ ε* τ i
        t' τ ()

,*-η : ∀ (f : [ k ] (Γ , τ) ~> Δ) → (tail* f ,* head* f) ≡ f
,*-η f = ~>Ext t'
  where t' : ∀ τ i → (tail* f ,* head* f) τ i ≡ f τ i
        t' τ zero = refl
        t' τ (suc i) = refl

∘*-,* : ∀ (g : [ k ] Δ ~> Ε) (f : [ k ] Γ ~> Δ) (x : [ k ] τ ⊣ Δ)
        → g ∘* (f ,* x) ≡ (g ∘* f) ,* (sub g x)
∘*-,* g f x = ~>Ext t'
  where t' : ∀ τ i → (g ∘* (f ,* x)) τ i ≡ ((g ∘* f) ,* (sub g x)) τ i
        t' τ zero = refl
        t' τ (suc i) = refl

-- the categorial structure on ~> behaves as one would expect -- using the sub laws from _⊣_!

id*-l : ∀ (f : [ k ] Γ ~> Δ) → id* ∘* f ≡ f
id*-l f = ~>Ext (λ τ i → sub-id* (f τ i))

id*-r : ∀ (f : [ k ] Γ ~> Δ) → f ∘* id* ≡ f
id*-r f = ~>Ext (λ τ i → sub-var f i)

assoc : ∀ (h : [ k ] Ε ~> Ζ) (g : [ k ] Δ ~> Ε) (f : [ k ] Γ ~> Δ)
        → (h ∘* g) ∘* f ≡ h ∘* (g ∘* f)
assoc h g f = ~>Ext (λ τ i → sub-∘* h g (f τ i))

-- Some more facts:

,*-wkn : ∀ (f : [ k ] Γ ~> Δ) (x : [ k ] τ ⊣ Δ) → (f ,* x) ∘* wkn ≡ f
,*-wkn f x = ~>Ext (λ τ i → sub-var (f ,* x) (suc i))

⟨⟩-↑ : ∀ (x : [ k ] τ ⊣ Δ) (f : [ k ] Γ ~> Δ) → ⟨ x ⟩ ∘* (↑ f) ≡ f ,* x
⟨⟩-↑ x f =  (id* ,* x) ∘* ((wkn ∘* f) ,* var zero)                  ≡⟨ ∘*-,* (id* ,* x) (wkn ∘* f) (var zero) ⟩
          ((id* ,* x) ∘* (wkn ∘* f)) ,* sub (id* ,* x) (var zero)  ≡⟨ cong (((id* ,* x) ∘* (wkn ∘* f)) ,*_) (sub-var (id* ,* x) zero) ⟩
          ((id* ,* x) ∘* (wkn ∘* f)) ,* x                          ≡⟨ cong (_,* x) (sym (assoc (id* ,* x) wkn f)) ⟩
          (((id* ,* x) ∘* wkn) ∘* f) ,* x                          ≡⟨ cong (λ z → (z ∘* f) ,* x) (,*-wkn id* (x)) ⟩
                          (id* ∘* f) ,* x                          ≡⟨ cong (_,* x) (id*-l f) ⟩
                                   f ,* x                          ∎

-- Variables can be expressed entirely in terms of head*, tail*, id*! (recall head* id* ≡ var zero, tail* id* ≡ wkn)
-- In particular: var i ≡ sub (wkn ∘* ... ∘* wkn) (var zero)
var-≡ : ∀ {τ Γ} (i : τ ∈ Γ) → var i ≡ (∈-Rec _⊣_ (head* id*) (sub (tail* id*)) i)
var-≡ zero = refl
var-≡ (suc i) = (sym (sub-var wkn i)) ∙ (cong (sub (tail* id*)) (var-≡ i))



--------------------------------------
-- apˡ vs. apʳ vs. unlamʳ vs. unlamˡ
--------------------------------------

-- The goal of this section is to show that apˡ ≡ apʳ! We start with some equalities:

-- using lam-βˡ, we can derive an equality for apˡ analgous to apʳ-unlamˡ
apˡ-unlamʳ : (y : [ k ] (σ ⇒ τ) ⊣ Γ) (z : [ k ] σ ⊣ Γ) → apˡ y z ≡ sub ⟨ z ⟩ (unlamʳ y)
apˡ-unlamʳ y z =
  apˡ y z                   ≡⟨ cong (λ x → apˡ x z) (sym (lam-ηʳ y)) ⟩
  apˡ (lam (unlamʳ y)) z    ≡⟨ lam-βˡ (unlamʳ y) z ⟩
  sub ⟨ z ⟩ (unlamʳ y) ∎

-- we can also derive an equality for unlamˡ analgous to to lam-ηʳ
unlam-βˡ : (x : [ k ] τ ⊣ (Γ , σ)) → unlamˡ (lam x) ≡ x
unlam-βˡ x = 
  apˡ (sub wkn (lam x)) (var zero)      ≡⟨ cong (λ z → apˡ z (var zero)) (sub-lam wkn x) ⟩
  apˡ (lam (sub (↑ wkn) x)) (var zero)  ≡⟨ lam-βˡ _ (var zero) ⟩
  sub ⟨ var zero ⟩ (sub (↑ wkn) x)       ≡⟨ sym (sub-∘* ⟨ var zero ⟩ (↑ wkn) x) ⟩
  sub (⟨ var zero ⟩ ∘* (↑ wkn)) x        ≡⟨ cong (λ z → sub z x) (⟨⟩-↑ (var zero) wkn) ⟩
  sub (wkn ,* var zero) x               ≡⟨ cong (λ z → sub z x) (,*-η id*) ⟩
  sub id* x                             ≡⟨ sub-id* x ⟩
  x                                     ∎

-- perhaps a more apt name:
unlam-ηʳ : (x : [ k ] (σ ⇒ τ) ⊣ Γ) → lam (unlamʳ x) ≡ x
unlam-ηʳ = lam-ηʳ


-- lam with unlamˡ and unlamʳ define a bi-invertible equivalence:
lam-biinvequiv : BiinvEquiv ([ k ] τ ⊣ (Γ , σ)) ([ k ] (σ ⇒ τ) ⊣ Γ)
lam-biinvequiv = record { fun = lam ; invr = unlamʳ ; invr-rightInv = unlam-ηʳ
                                    ; invl = unlamˡ ; invl-leftInv  = unlam-βˡ }

-- ...thus:
unlam-uniq : ∀ (y : [ k ] (σ ⇒ τ) ⊣ Γ) → unlamʳ y ≡ unlamˡ y
unlam-uniq = BiinvEquiv.invr≡invl lam-biinvequiv

-- ...and therefore our ap's are indistinguishable!
ap-uniq : ∀ (y : [ k ] (σ ⇒ τ) ⊣ Γ) (z : [ k ] σ ⊣ Γ) → apˡ y z ≡ apʳ y z
ap-uniq y z = apˡ-unlamʳ y z ∙ cong (sub ⟨ z ⟩) (unlam-uniq y) ∙ sym (apʳ-unlamˡ y z)

-- We can also derive substitution rules for unlam and ap:

unlam-sub : (f : [ k ] Γ ~> Δ) (y : [ k ] (σ ⇒ τ) ⊣ Γ)
            → sub (↑ f) (unlamʳ y) ≡ unlamˡ (sub f y)
unlam-sub {σ} f y =
               sub (↑ f) (unlamʳ y)    ≡⟨ sym (unlam-βˡ _) ⟩
  unlamˡ (lam (sub (↑ f) (unlamʳ y)))  ≡⟨ cong unlamˡ (sym (sub-lam f (unlamʳ y))) ⟩
  unlamˡ (sub f (lam (unlamʳ y))    )  ≡⟨ cong (unlamˡ ∘ sub f) (unlam-ηʳ y) ⟩
  unlamˡ (sub f y                   )  ∎

ap-sub : (f : [ k ] Γ ~> Δ) (y : [ k ] (σ ⇒ τ) ⊣ Γ) (z : [ k ] σ ⊣ Γ)
         → sub f (apˡ y z) ≡ apʳ (sub f y) (sub f z)
ap-sub f y z =
  sub f (apˡ y z)                         ≡⟨ cong (sub f) (apˡ-unlamʳ y z) ⟩
  sub f (sub ⟨ z ⟩ (unlamʳ y))             ≡⟨ sym (sub-∘* f ⟨ z ⟩ (unlamʳ y)) ⟩
  sub (f ∘* ⟨ z ⟩) (unlamʳ y)              ≡⟨ cong (λ x → sub x (unlamʳ y)) (∘*-,* f id* z) ⟩
  sub ((f ∘* id*) ,* sub f z) (unlamʳ y)  ≡⟨ cong (λ x → sub (x ,* sub f z) (unlamʳ y)) (id*-r f) ⟩
  sub (f ,* sub f z) (unlamʳ y)           ≡⟨ cong (λ x → sub x (unlamʳ y)) (sym (⟨⟩-↑ (sub f z) f)) ⟩
  sub (⟨ sub f z ⟩ ∘* (↑ f)) (unlamʳ y)    ≡⟨ sub-∘* (id* ,* (sub f z)) (↑ f) (unlamʳ y) ⟩
  sub ⟨ sub f z ⟩ (sub (↑ f) (unlamʳ y))   ≡⟨ cong (sub (id* ,* (sub f z))) (unlam-sub f y) ⟩
  sub ⟨ sub f z ⟩ (unlamˡ (sub f y))       ≡⟨ sym (apʳ-unlamˡ (sub f y) (sub f z)) ⟩
  apʳ (sub f y) (sub f z)                 ∎
