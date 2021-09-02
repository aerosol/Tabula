defmodule Tabula.Mixfile do
  use Mix.Project

  @version "2.2.4"

  def project do
    [app: :tabula,
      version: @version,
      elixir: "~> 1.11",
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

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [maintainers: ["Adam Rutkowski"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/aerosol/Tabula"}]
  end
end
