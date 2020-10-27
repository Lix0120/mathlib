/-
Copyright (c) 2020 Kevin Lacker, Keeley Hoek, Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kevin Lacker, Keeley Hoek, Scott Morrison
-/

import tactic.rewrite_search.common
import tactic.rewrite_search.hook

/-!
# Types used in rewrite search.
-/

universes u v

open tactic

namespace tactic.rewrite_search

structure bfs_state :=
(curr_depth : ℕ)
(queue      : list (option ℕ))

meta structure edge :=
(f t   : ℕ)
(proof : tactic expr)
(how   : how)

namespace edge
variables (e : edge)

meta def other (r : ℕ) : option ℕ :=
  if e.f = r then e.t else
  if e.t = r then e.f else
  none

meta instance has_to_format : has_to_format edge := ⟨λ e, format!"{e.f}->{e.t}"⟩

end edge

def invalid_index : ℕ := 0xFFFFFFFF

structure rewrite_iter :=
(orig : ℕ)
(front : ℕ)

meta structure vertex :=
(id       : ℕ)
(exp      : expr)
(pp       : string)
(tokens   : list ℕ)
(root     : bool)
(visited  : bool)
(s        : side)
(parent   : option edge)
(rw_prog  : option rewrite_progress)
(rws      : buffer rewrite)
(rw_front : ℕ)
(adj      : buffer edge)

namespace vertex

meta def same_side (a b : vertex) : bool := a.s = b.s
meta def to_string (v : vertex) : string := v.s.to_string ++ v.pp

meta def create (id : ℕ) (e : expr) (pp : string) (token_refs : list ℕ) (root : bool) (s : side) : vertex :=
⟨ id, e, pp, token_refs, root, ff, s, none, none, buffer.nil, 0, buffer.nil ⟩

meta def null : vertex := vertex.create invalid_index (default expr) "__NULLEXPR" [] ff side.L

meta instance inhabited : inhabited vertex := ⟨null⟩
meta instance has_to_format : has_to_format vertex := ⟨λ v, v.pp⟩

end vertex

def pair := sided_pair ℕ
def pair.null : pair := ⟨invalid_index, invalid_index⟩
instance pair.has_to_string : has_to_string pair := ⟨sided_pair.to_string⟩

structure token :=
(id   : ℕ)
(str  : string)
(freq : sided_pair ℕ)

namespace token

def inc (t : token) (s : side) : token := {t with freq := t.freq.set s $ (t.freq.get s) + 1}

def null : token := ⟨ invalid_index, "__NULLTOKEN", 0, 0 ⟩

instance inhabited : inhabited token := ⟨null⟩

end token

meta def token_finder (tstr : string) (left : token) (right : option token) : option token :=
match right with
| some t := some t
| none   := if left.str = tstr then some left else none
end

meta def find_token (tokens : buffer token) (tstr : string) : option token :=
tokens.foldl none (token_finder tstr) 

meta def find_or_create_token (tokens : buffer token) (s : side) (tstr : string) : buffer token × token :=
match find_token tokens tstr with
| none := do
  let t : token := ⟨tokens.size, tstr, ⟨0, 0⟩⟩,
  let t := t.inc s in (tokens.push_back t, t)
| (some t) := do
  let t := t.inc s in (tokens.write' t.id t, t)
end

meta inductive status
| continue : status
| repeat : status
| done : edge → status
| abort : string → status

meta structure search_state :=
(conf         : config)
(rs           : list (expr × bool))
(strat_state  : bfs_state)
(tokens       : buffer token)
(vertices     : buffer vertex)
(solving_edge : option edge)

def LHS_VERTEX_ID : ℕ := 0
def RHS_VERTEX_ID : ℕ := 1

namespace search_state
variables (g : search_state)

meta def mutate_strat (new_state : bfs_state) : search_state :=
{ g with strat_state := new_state }

meta def set_vertex (v : vertex) : search_state × vertex :=
({ g with vertices := g.vertices.write' v.id v }, v)

meta def lookup_pair (p : pair) : tactic (vertex × vertex) :=
return (g.vertices.read' p.l, g.vertices.read' p.r)

meta def get_endpoints (e : edge) : tactic (vertex × vertex) :=
return (g.vertices.read' e.f, g.vertices.read' e.t)

end search_state

meta structure proof_unit :=
(proof : expr)
(side : side)
(steps : list how)

meta inductive search_result
| success (proof : expr) (units : list proof_unit) : search_result
| failure (message : string) : search_result

end tactic.rewrite_search