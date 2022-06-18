defmodule Membrane.Nx.VideoScaler.Plugin.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/membraneframework-labs/membrane_nx_video_scaler_plugin"

  def project do
    [
      app: :membrane_nx_video_scaler_plugin,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      description: "Plugin for scaling video using Nx",
      package: package(),

      # docs
      name: "Membrane Nx Video Scaler Plugin",
      source_url: @github_url,
      homepage_url: "https://membraneframework.org",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:exla, "~> 0.2"},
      {:membrane_core, "~> 0.10.0"},
      {:nx, "~> 0.2"},
      {:benchee, "~> 1.0", only: :dev},
      {:credo, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:membrane_ffmpeg_swscale_plugin, "~> 0.10.0", only: :dev},
      {:membrane_file_plugin, "~> 0.12.0", only: :dev},
      {:membrane_h264_ffmpeg_plugin, "~> 0.21.1", only: :dev}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.Nx]
    ]
  end
end
