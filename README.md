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

Benchmarks were performed using Benchee with following configuration:

<img width="436" alt="Screenshot 2022-06-17 at 16 47 59" src="https://user-images.githubusercontent.com/25062706/174323628-c4a2c225-3ce8-4384-a044-87227a5250c8.png">

<details>
<summary markdown="span">Results</summary>
  
<img width="712" alt="to_1280x720" src="https://user-images.githubusercontent.com/25062706/174324133-23224147-9bfe-4752-8519-f62416481ba6.png">
<img width="708" alt="to_960x540" src="https://user-images.githubusercontent.com/25062706/174324141-bdcbf59f-90ae-41f7-9c62-08477eb797db.png">
<img width="704" alt="to_640x360" src="https://user-images.githubusercontent.com/25062706/174324149-aff59b5d-be68-470b-8f6d-be886562f407.png">
<img width="708" alt="to_480x270" src="https://user-images.githubusercontent.com/25062706/174324155-94f0b366-66c0-4624-8387-0253e348777d.png">
<img width="706" alt="to_320x180" src="https://user-images.githubusercontent.com/25062706/174324164-483594ab-c7f0-4912-a146-23ce9456c71c.png">

</details>

![charts](https://user-images.githubusercontent.com/25062706/174325216-fbd78c78-9eb2-4719-aebd-f47ab8907fd2.png)

## Copyright and License


Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_template_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_nx_video_scaler_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
