using Documenter, Owl

makedocs(
    build = joinpath(@__DIR__, "local" in ARGS ? "build_local" : "build"),
    modules = [Owl],
    clean = false,
    format = :html,
    sitename = "🦉",
    authors = "초보똥",
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
        "DataFlow" => [
            "DataFlow 버티스(vertices)" => "DataFlow/vertices.md",
        ],
        "MacroTools" => [
            "MacroTools README" => "MacroTools/README.md",
        ],
        "FluxJS" => [
            "FluxJS README" => "FluxJS/README.md",
        ],
        "GSoC" => [
            "Application Guidelines" => "soc/guidelines/index.md",
            "Data Science & Machine Learning" => "soc/projects/ml.md",
        ],
    ],
    html_prettyurls = !("local" in ARGS),
)
