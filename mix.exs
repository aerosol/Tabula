defmodule Tabula.Mixfile do
  use Mix.Project

  @version "2.2.0"

  def project do
    [app: :tabula,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: "Pretty printer for maps/structs collections",
      package: package(),
      deps: deps(),
      docs: [source_ref: "#{@version}",
             source_url: "https://github.com/aerosol/Tabula",
             main: "readme",
             extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:earmark, "~> 0.2.1", only: :dev},
      {:ex_doc, "~> 0.12.0", only: :dev}]
  end

  defp package do
    [maintainers: ["Adam Rutkowski"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/aerosol/Tabula"}]
  end
end
