defmodule OpentelemetrySentry.MixProject do
  use Mix.Project

  @source_url "https://github.com/scripbox/opentelemetry_exq"
  @version "0.1.0"

  def project do
    [
      app: :opentelemetry_sentry,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:opentelemetry_api, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: """
      Sentry integration for OpenTelemetry
      """,
      maintainers: ["Anantha Kumaran"],
      licenses: ["MIT"],
      files: ~w(lib test) ++ ~w(LICENSE mix.exs README.md),
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      formatters: ["html"],
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end
end
