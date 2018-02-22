using Documenter, 🦉

makedocs(
    modules = [🦉],
    clean = false,
    format = :html,
    sitename = "🦉",
    authors = "WooKyoung Noh",
    pages = Any[
        "Home" => "index.md",
        "Flux" => [
            "Flux 홈" => "Flux/index.md",
            "모델 만들기" =>
              ["기본적인 것" => "Flux/models/basics.md",
               "순환(Recurrence)" => "Flux/models/recurrence.md",
               "정규화(Regularisation)" => "Flux/models/regularisation.md",
               "모델 참조(Model Reference)" => "Flux/models/layers.md"],
            "Training Models" =>
              ["Optimisers" => "Flux/training/optimisers.md",
               "Training" => "Flux/training/training.md"],
            "One-Hot Encoding" => "Flux/data/onehot.md",
            "GPU Support" => "Flux/gpu.md",
            "Community" => "Flux/community.md"],
    ],
    html_prettyurls = !("local" in ARGS),
)
