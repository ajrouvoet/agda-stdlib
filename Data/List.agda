------------------------------------------------------------------------
-- Lists
------------------------------------------------------------------------

module Data.List where

open import Data.Nat
open import Data.Sum
open import Data.Bool
open import Data.Maybe
open import Data.Product
open import Data.Function

infixr 5 _∷_ _++_

------------------------------------------------------------------------
-- Types

data List (A : Set) : Set where
  []  : List A
  _∷_ : (x : A) (xs : List A) -> List A

{-# BUILTIN LIST List #-}
{-# BUILTIN NIL  []   #-}
{-# BUILTIN CONS _∷_  #-}

infix 4 _∈_

data _∈_ {a : Set} : a -> List a -> Set where
  here  : forall {x}   {xs : List a} -> x ∈ x ∷ xs
  there : forall {x y} {xs : List a} (x∈xs : x ∈ xs) -> x ∈ y ∷ xs

------------------------------------------------------------------------
-- Some operations

-- * Basic functions

[_] : forall {a} -> a -> List a
[ x ] = x ∷ []

_++_ : forall {a} -> List a -> List a -> List a
[]       ++ ys = ys
(x ∷ xs) ++ ys = x ∷ (xs ++ ys)

null : forall {a} -> List a -> Bool
null []       = true
null (x ∷ xs) = false

-- * List transformations

map : forall {a b} -> (a -> b) -> List a -> List b
map f []       = []
map f (x ∷ xs) = f x ∷ map f xs

reverse : forall {a} -> List a -> List a
reverse xs = rev xs []
  where
  rev : forall {a} -> List a -> List a -> List a
  rev []       ys = ys
  rev (x ∷ xs) ys = rev xs (x ∷ ys)

replicate : forall {a} -> (n : ℕ) -> a -> List a
replicate zero    x = []
replicate (suc n) x = x ∷ replicate n x

-- * Reducing lists (folds)

foldr : {a b : Set} -> (a -> b -> b) -> b -> List a -> b
foldr c n []       = n
foldr c n (x ∷ xs) = c x (foldr c n xs)

foldl : {a b : Set} -> (a -> b -> a) -> a -> List b -> a
foldl c n []       = n
foldl c n (x ∷ xs) = foldl c (c n x) xs

-- ** Special folds

concat : forall {a} -> List (List a) -> List a
concat = foldr _++_ []

concatMap : forall {a b} -> (a -> List b) -> List a -> List b
concatMap f = concat ∘ map f

and : List Bool -> Bool
and = foldr _∧_ true

or : List Bool -> Bool
or = foldr _∨_ false

any : forall {a} -> (a -> Bool) -> List a -> Bool
any p = or ∘ map p

all : forall {a} -> (a -> Bool) -> List a -> Bool
all p = and ∘ map p

sum : List ℕ -> ℕ
sum = foldr _+_ 0

product : List ℕ -> ℕ
product = foldr _*_ 1

length : forall {a} -> List a -> ℕ
length = foldr (\_ -> suc) 0

-- * Building lists

-- ** Scans

scanr : forall {a b} -> (a -> b -> b) -> b -> List a -> List b
scanr f e []       = e ∷ []
scanr f e (x ∷ xs) with scanr f e xs
... | []     = []                -- dead branch
... | y ∷ ys = f x y ∷ y ∷ ys

scanl : forall {a b} -> (a -> b -> a) -> a -> List b -> List a
scanl f e []       = e ∷ []
scanl f e (x ∷ xs) = e ∷ scanl f (f e x) xs

-- ** Unfolding

-- Unfold. Uses a measure (a natural number) to ensure termination.

unfold : {A : Set} (B : ℕ -> Set)
         (f : forall {n} -> B (suc n) -> Maybe (A × B n)) ->
         forall {n} -> B n -> List A
unfold B f {n = zero}  s = []
unfold B f {n = suc n} s with f s
... | nothing       = []
... | just (x , s') = x ∷ unfold B f s'

-- downFrom 3 = 2 ∷ 1 ∷ 0 ∷ [].

downFrom : ℕ -> List ℕ
downFrom n = unfold Singleton f (wrap n)
  where
  data Singleton : ℕ -> Set where
    wrap : (n : ℕ) -> Singleton n

  f : forall {n} -> Singleton (suc n) -> Maybe (ℕ × Singleton n)
  f {n} (wrap .(suc n)) = just (n , wrap n)

-- * Sublists

-- ** Extracting sublists

take : forall {a} -> ℕ -> List a -> List a
take zero    xs       = []
take (suc n) []       = []
take (suc n) (x ∷ xs) = x ∷ take n xs

drop : forall {a} -> ℕ -> List a -> List a
drop zero    xs       = xs
drop (suc n) []       = []
drop (suc n) (x ∷ xs) = drop n xs

splitAt : forall {a} -> ℕ -> List a -> (List a × List a)
splitAt zero    xs       = ([] , xs)
splitAt (suc n) []       = ([] , [])
splitAt (suc n) (x ∷ xs) with splitAt n xs
... | (ys , zs) = (x ∷ ys , zs)

takeWhile : forall {a} -> (a -> Bool) -> List a -> List a
takeWhile p []       = []
takeWhile p (x ∷ xs) with p x
... | true  = x ∷ takeWhile p xs
... | false = []

dropWhile : forall {a} -> (a -> Bool) -> List a -> List a
dropWhile p []       = []
dropWhile p (x ∷ xs) with p x
... | true  = dropWhile p xs
... | false = x ∷ xs

span : forall {a} -> (a -> Bool) -> List a -> (List a × List a)
span p []       = ([] , [])
span p (x ∷ xs) with p x
... | true  = map-× (_∷_ x) id (span p xs)
... | false = ([] , x ∷ xs)

break : forall {a} -> (a -> Bool) -> List a -> (List a × List a)
break p = span (not ∘ p)

inits : forall {a} ->  List a -> List (List a)
inits []       = [] ∷ []
inits (x ∷ xs) = [] ∷ map (_∷_ x) (inits xs)

tails : forall {a} -> List a -> List (List a)
tails []       = [] ∷ []
tails (x ∷ xs) = (x ∷ xs) ∷ tails xs

-- * Searching lists

-- ** Searching with a predicate

-- A generalised variant of filter.

gfilter : forall {a b} -> (a -> Maybe b) -> List a -> List b
gfilter p []       = []
gfilter p (x ∷ xs) with p x
... | just y  = y ∷ gfilter p xs
... | nothing =     gfilter p xs

filter : forall {a} -> (a -> Bool) -> List a -> List a
filter p = gfilter (\x -> if p x then just x else nothing)

partition : forall {a} -> (a -> Bool) -> List a -> (List a × List a)
partition p []       = ([] , [])
partition p (x ∷ xs) with p x | partition p xs
... | true  | (ys , zs) = (x ∷ ys , zs)
... | false | (ys , zs) = (ys , x ∷ zs)

-- Possibly the following functions should be called lefts and rights.

inj₁s : forall {a b} -> List (a ⊎ b) -> List a
inj₁s []            = []
inj₁s (inj₁ x ∷ xs) = x ∷ inj₁s xs
inj₁s (inj₂ x ∷ xs) = inj₁s xs

inj₂s : forall {a b} -> List (a ⊎ b) -> List b
inj₂s []            = []
inj₂s (inj₁ x ∷ xs) = inj₂s xs
inj₂s (inj₂ x ∷ xs) = x ∷ inj₂s xs

------------------------------------------------------------------------
-- List monad

open import Category.Monad

ListMonad : RawMonad List
ListMonad = record
  { return = \x -> x ∷ []
  ; _>>=_  = \xs f -> concat (map f xs)
  }

ListMonadZero : RawMonadZero List
ListMonadZero = record
  { monad = ListMonad
  ; ∅     = []
  }

ListMonadPlus : RawMonadPlus List
ListMonadPlus = record
  { monadZero = ListMonadZero
  ; _∣_       = _++_
  }
