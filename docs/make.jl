using Documenter
using Flux
using NNlib # σ
using Zygote

include("contrib/html_writer.jl")

makedocs(
    sitename = "🦉",
    authors = "초보똥",
    clean = false,
    build = joinpath(@__DIR__, "local" in ARGS ? "build_local" : "build"),
    modules=[Flux, NNlib, Zygote],
    pages = Any[
        "Home" => "index.md",
        "Flux ✅" => [
            "Flux 홈" => "Flux/index.md",
            "모델 만들기" =>
              ["기본적인 것" => "Flux/models/basics.md",
               "순환(Recurrence)" => "Flux/models/recurrence.md",
               "정규화(Regularisation)" => "Flux/models/regularisation.md",
               "모델 참조(Model Reference)" => "Flux/models/layers.md"],
            "모델 훈련시키기" =>
              ["최적화" => "Flux/training/optimisers.md",
               "훈련시키기" => "Flux/training/training.md"],
            "원-핫 인코딩" => "Flux/data/onehot.md",
            "GPU 지원" => "Flux/gpu.md",
            "저장 & 불러오기" => "Flux/saving.md",
            "커뮤니티" => "Flux/community.md"
        ],
        "DataFlow ✅" => [
            "DataFlow 버티스(vertices)" => "DataFlow/vertices.md",
        ],
        "Zygote ⏳" => [
            "Home" => "Zygote/index.md",
            "Custom Adjoints" => "Zygote/adjoints.md",
            "Utilities" => "Zygote/utils.md",
            "Complex Differentiation" => "Zygote/complex.md",
            "Flux" => "Zygote/flux.md",
            "Profiling" => "Zygote/profiling.md",
            "Internals" => "Zygote/internals.md",
            "Glossary" => "Zygote/glossary.md"
        ],
    ],
    format = Documenter.HTML(assets = ["assets/custom.css"], prettyurls = !("local" in ARGS))
)
