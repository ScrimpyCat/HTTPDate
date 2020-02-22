defmodule HTTPDate.MixProject do
    use Mix.Project

    def project do
        [
            app: :http_date,
            description: "RFC 7231 HTTP date parsing/formatting library",
            version: "0.1.0",
            elixir: "~> 1.5",
            start_permanent: Mix.env() == :prod,
            deps: deps(),
            dialyzer: [plt_add_deps: :transitive],
            package: package()
        ]
    end

    def application do
        [extra_applications: [:logger]]
    end

    defp deps do
        if(Version.compare(System.version, "1.7.0") == :lt, do: [{ :earmark, "~> 0.1", only: :dev }, { :ex_doc, "~> 0.7", only: :dev }], else: [{ :ex_doc, "~> 0.19", only: :dev, runtime: false }])
    end

    defp package do
        [
            maintainers: ["Stefan Johnson"],
            licenses: ["BSD 2-Clause"],
            links: %{ "GitHub" => "https://github.com/ScrimpyCat/HTTPDate" }
        ]
    end
end
