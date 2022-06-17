# Membrane Template Plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_nx_video_scaler_plugin.svg)](https://hex.pm/packages/membrane_nx_video_scaler_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_nx_video_scaler_plugin)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_nx_video_scaler_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_nx_video_scaler_plugin)

This repository contains video scaler written using [Nx](https://github.com/elixir-nx/nx) library.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

## Installation

The package can be installed by adding `membrane_nx_video_scaler_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_nx_video_scaler_plugin, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
defmodule Scaling.Pipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(_) do
     children = [
      file_src: %Membrane.File.Source{location: "/tmp/input.h264"},
      parser: Membrane.H264.FFmpeg.Parser,
      decoder: Membrane.H264.FFmpeg.Decoder,
      scaler: Membrane.Nx.VideoScaler{output_width: 1280, output_height: 720},
      encoder: Membrane.H264.FFmpeg.Encoder,
      file_sink: %Membrane.File.Sink{location: "/tmp/output.h264"}
    ]

    links = [
      link(:file_src)
      |> to(:parser)
      |> to(:decoder)
      |> to(:scaler)
      |> to(:encoder)
      |> to(:file_sink)
    ]

    {{:ok, spec: %ParentSpec{children: children, links: links}, %{}}
  end
end
```

## Benchmarks


## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_template_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_nx_video_scaler_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
