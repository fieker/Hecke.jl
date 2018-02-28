mutable struct NfRelOrdFracIdlSet{T, S}
  order::NfRelOrd{T, S}

  function NfRelOrdFracIdlSet{T, S}(O::NfRelOrd{T, S}) where {T, S}
    a = new(O)
    return a
  end
end

mutable struct NfRelOrdFracIdl{T, S}
  order::NfRelOrd{T, S}
  parent::NfRelOrdFracIdlSet{T, S}
  num::NfRelOrdIdl{T, S}
  den_abs::NfOrdElem # used if T == nf_elem
  den_rel::NfRelOrdElem # used otherwise

  norm
  has_norm::Bool

  function NfRelOrdFracIdl{T, S}(O::NfRelOrd{T, S}) where {T, S}
    z = new{T, S}()
    z.order = O
    z.parent = NfRelOrdFracIdlSet{T, S}(O)
    z.has_norm = false
    return z
  end

  function NfRelOrdFracIdl{nf_elem, S}(O::NfRelOrd{nf_elem, S}, a::NfRelOrdIdl{nf_elem, S}, d::NfOrdElem) where S
    z = NfRelOrdFracIdl{nf_elem, S}(O)
    z.num = a
    z.den_abs = d
    return z
  end

  function NfRelOrdFracIdl{T, S}(O::NfRelOrd{T, S}, a::NfRelOrdIdl{T, S}, d::NfRelOrdElem) where {T, S}
    z = NfRelOrdFracIdl{T, S}(O)
    z.num = a
    z.den_rel = d
    return z
  end
end

################################################################################
#
#  Basic field access
#
################################################################################

doc"""
***
    order(a::NfRelOrdFracIdl) -> NfRelOrd

> Returns the order of $a$.
"""
order(a::NfRelOrdFracIdl) = a.order

doc"""
***
    nf(a::NfRelOrdFracIdl) -> RelativeExtension

> Returns the number field, of which $a$ is an fractional ideal.
"""
nf(a::NfRelOrdFracIdl) = nf(order(a))

################################################################################
#
#  Parent
#
################################################################################

parent(a::NfRelOrdFracIdl) = a.parent

################################################################################
#
#  Numerator and denominator
#
################################################################################

numerator(a::NfRelOrdFracIdl) = a.num

denominator(a::NfRelOrdFracIdl{nf_elem, S}) where {S} = deepcopy(a.den_abs)

denominator(a::NfRelOrdFracIdl{T, S}) where {S, T} = deepcopy(a.den_rel)

################################################################################
#
#  String I/O
#
################################################################################

function show(io::IO, s::NfRelOrdFracIdlSet)
  print(io, "Set of fractional ideals of ")
  print(io, s.order)
end

function show(io::IO, a::NfRelOrdFracIdl)
  compact = get(io, :compact, false)
  if compact
    print(io, "Fractional ideal with basis pseudo-matrix\n")
    showcompact(io, basis_pmat(numerator(a), Val{false}))
    print(io, "\nand denominator ", denominator(a))
  else
    print(io, "Fractional ideal of\n")
    showcompact(order(a))
    print(io, "\nwith basis pseudo-matrix\n")
    showcompact(io, basis_pmat(numerator(a), Val{false}))
    print(io, "\nand denominator ", denominator(a))
  end
end

################################################################################
#
#  Construction
#
################################################################################

doc"""
***
    frac_ideal(O::NfRelOrd, a::NfRelOrdIdl, d::NfOrdElem) -> NfRelOrdFracIdl
    frac_ideal(O::NfRelOrd, a::NfRelOrdIdl, d::NfRelOrdElem) -> NfRelOrdFracIdl

> Creates the fractional ideal $a/d$ of $\mathcal O$.
"""
function frac_ideal(O::NfRelOrd{nf_elem, S}, a::NfRelOrdIdl{nf_elem, S}, d::NfOrdElem) where S
  return NfRelOrdFracIdl{nf_elem, S}(O, a, d)
end

function frac_ideal(O::NfRelOrd{T, S}, a::NfRelOrdIdl{T, S}, d::NfRelOrdElem{T}) where {T, S}
  return NfRelOrdFracIdl{T, S}(O, a, d)
end

function frac_ideal(O::NfRelOrd{T, S}, x::RelativeElement{T}) where {T, S}
  d = degree(O)
  pb = pseudo_basis(O, Val{false})
  M = zero_matrix(base_ring(nf(O)), d, d)
  for i = 1:d
    elem_to_mat_row!(M, i, pb[i][1]*x)
  end
  M = M*basis_mat_inv(O, Val{false})
  PM = PseudoMatrix(M, [ deepcopy(pb[i][2]) for i = 1:d ])
  PM = pseudo_hnf(PM, :lowerleft)
  OO = order(pb[1][2])
  den = OO(1)
  return NfRelOrdFracIdl{T, S}(O, NfRelOrdIdl{T, S}(O, PM), den)
end

*(O::NfRelOrd{T, S}, x::RelativeElement{T}) where {T, S} = frac_ideal(O, x)

*(x::RelativeElement{T}, O::NfRelOrd{T, S}) where {T, S} = frac_ideal(O, x)

################################################################################
#
#  Deepcopy
#
################################################################################

function Base.deepcopy_internal(a::NfRelOrdFracIdl{T, S}, dict::ObjectIdDict) where {T, S}
  z = NfRelOrdFracIdl{T, S}(a.order)
  for x in fieldnames(a)
    if x != :order && x != :parent && isdefined(a, x)
      setfield!(z, x, Base.deepcopy_internal(getfield(a, x), dict))
    end
  end
  z.order = a.order
  z.parent = a.parent
  return z
end

################################################################################
#
#  Equality
#
################################################################################

doc"""
***
    ==(a::NfOrdRelFracIdl, b::NfRelOrdFracIdl) -> Bool

> Returns whether $a$ and $b$ are equal.
"""
function ==(a::NfRelOrdFracIdl, b::NfRelOrdFracIdl)
  order(a) != order(b) && return false
  return denominator(a) == denominator(b) && numerator(a) == numerator(b)
end

################################################################################
#
#  Norm
#
################################################################################

function assure_has_norm(a::NfRelOrdFracIdl)
  if a.has_norm
    return nothing
  end
  n = norm(numerator(a))
  d = denominator(a)^degree(order(a))
  a.norm = n*inv(nf(parent(denominator(a)))(d))
  a.has_norm = true
  return nothing
end

doc"""
***
    norm(a::NfRelOrdFracIdl{T, S}) -> S

> Returns the norm of $a$
"""
function norm(a::NfRelOrdFracIdl, copy::Type{Val{T}} = Val{true}) where T
  assure_has_norm(a)
  if copy == Val{true}
    return deepcopy(a.norm)
  else
    return a.norm
  end
end

################################################################################
#
#  Ideal addition
#
################################################################################

doc"""
***
    +(a::NfRelOrdFracIdl, b::NfRelOrdFracIdl) -> NfRelOrdFracIdl

> Returns $a + b$.
"""
function +(a::NfRelOrdFracIdl{T, S}, b::NfRelOrdFracIdl{T, S}) where {T, S}
  K = nf(parent(denominator(a)))
  da = K(denominator(a))
  db = K(denominator(b))
  d = divexact(da*db, gcd(da, db))
  ma = divexact(d, da)
  mb = divexact(d, db)
  c = ma*numerator(a) + mb*numerator(b)
  return NfRelOrdFracIdl{T, S}(order(a), c, parent(denominator(a))(d))
end

################################################################################
#
#  Ideal multiplication
#
################################################################################

doc"""
***
      *(a::NfRelOrdFracIdl, b::NfRelOrdFracIdl)

> Returns $a \cdot b$.
"""
function *(a::NfRelOrdFracIdl{T, S}, b::NfRelOrdFracIdl{T, S}) where {T, S}
  return NfRelOrdFracIdl{T, S}(order(a), numerator(a)*numerator(b), denominator(a)*denominator(b))
end

################################################################################
#
#  Ad hoc multiplication
#
################################################################################

function *(a::NfRelOrdFracIdl{T, S}, b::RelativeElement{T}) where {T, S}
  c = b*order(a)
  return c*a
end

*(b::RelativeElement{T}, a::NfRelOrdFracIdl{T, S}) where {T, S} = a*b

################################################################################
#
#  Inverse
#
################################################################################

doc"""
***
      inv(a::NfRelOrdFracIdl) -> NfRelOrdFracIdl

> Returns the fractional ideal $b$ such that $ab = O$ where $O$ is the ambient 
> order of $a$.
"""
function inv(a::NfRelOrdFracIdl{T, S}) where {T, S}
  b = inv(a.num)
  return NfRelOrdFracIdl{T, S}(order(a), b*denominator(a), order(a)(1))
end