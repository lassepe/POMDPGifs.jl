module POMDPGifs

using Reel
using POMDPs
using POMDPSimulators
using POMDPModelTools
using POMDPPolicies
using ProgressMeter
using Parameters
using Random

export
    GifSimulator,
    makegif

struct SavedGif
    filename::String
end

function Base.show(io::IO, m::MIME"text/html", g::SavedGif)
    println(io, "<img src=\"$(g.filename)\">")
end

@with_kw mutable struct GifSimulator <: Simulator
    filename::String                = tempname()*".gif"
    fps::Int                        = 2
    spec::Union{Nothing, Any}       = nothing
    max_steps::Union{Nothing, Any}  = nothing
    rng::AbstractRNG                = Random.GLOBAL_RNG
    show_progress::Bool             = max_steps != nothing
    render_kwargs                   = NamedTuple()
end

function POMDPs.simulate(s::GifSimulator, m::Union{MDP, POMDP}, p::Policy=RandomPolicy(m, rng=s.rng), args...)

    # run simulation
    sim = HistoryRecorder(rng = s.rng,
                          max_steps = s.max_steps,
                          show_progress = s.show_progress
                         )
    hist = simulate(sim, m, p, args...)

    # deal with the spec
    if s.spec == nothing
        steps = eachstep(hist)
    else
        steps = eachstep(hist, s.spec)
    end

    # create gif
    frames = Frames(MIME("image/png"), fps=2)
    @showprogress 0.1 "Rendering $(length(steps)) steps..." for step in steps
        push!(frames, render(m, step; pairs(s.render_kwargs)...))
    end
    if s.show_progress
        @info "Creating Gif..."
    end
    write(s.filename, frames)
    if s.show_progress
        @info "Done Creating Gif."
    end
    return SavedGif(s.filename)
end

function makegif(args...; kwargs...)
    sim = GifSimulator(;kwargs...)
    return simulate(sim, args...)
end

end # module
