using Documenter, ZMQPoller

makedocs(
    modules = [ZMQPoller],
    sitename = "ZMQPoller.jl",
    authors = "Lucas Bex",
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "API" => "api.md",
    ],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    remotes = nothing
)

deploydocs(
    repo = "github.com/CasBex/ZMQPoller.jl.git",
    target = "build",
)
