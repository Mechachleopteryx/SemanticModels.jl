# -*- coding: utf-8 -*-
# + {}
module MonomialRegressions
using SemanticModels.ModelTools

export MonomialRegression, model, show

struct MonomialRegression <: AbstractProblem
    expr
    f
    coefficient
    objective
    interval
end

eval(m::MonomialRegression) = eval(m.expr)

function model(::Type{MonomialRegression}, ex::Expr)
    if ex.head == :block
        return model(MonomialRegression, ex.args[2])
    end

    objective = callsites(ex, :optimize)[end].args[2]
    f = filter(isexpr, findfunc(ex, :f))[1]
    interval = findassign(ex, :a₀)[1]
    ldef = filter(isexpr, findfunc(ex, objective))
    coeff = funcarg(ldef[1])
    return MonomialRegression(ex,
                              f,
                              coeff,
                              objective,
                              interval)
end

function show(io::IO, m::MonomialRegression)
    write(io, "MonomialRegression(\n  f=$(repr(m.f)),\n  objective=$(repr(m.objective)),\n  coefficient=$(repr(m.coefficient)),\n  interval=$(repr(m.interval)))")
end

function (t::Pow)(m::MonomialRegression)
    x = m.f.args[1].args[3]
    replacer(a::Any) = a
    replacer(ex::Expr) = begin
        if ex.head == :call && ex.args[1] == :(^)
            # increment the power
            try
                ex.args[3]+=t.inc
            catch
                @warn "Possible invalid xform"
                @show ex
            end
        end
        return ex
    end
    m.f.args[2] = postwalk(replacer, m.f.args[2])
end
    
end