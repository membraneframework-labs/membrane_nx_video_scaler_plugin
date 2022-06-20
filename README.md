# Membrane NX Video Scaler Plugin

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
  
<img width="717" alt="to_1280x720" src="https://user-images.githubusercontent.com/25062706/174434869-3c4b2ae1-a89a-4fd6-b7be-6b32628e2d39.png">
 
![to_960x540](https://user-images.githubusercontent.com/25062706/174434927-bb2098f7-d5ef-42c9-86c4-aef4adecb53d.png)
  
![to_640x360](https://user-images.githubusercontent.com/25062706/174434937-10c6b2bc-8d70-4fad-83c6-b820466ddde8.png)
  
![to_480x270](https://user-images.githubusercontent.com/25062706/174434939-82b8ad56-61b4-4fd9-ac0f-7d4c8a5920fa.png)
  
![to_320x180](https://user-images.githubusercontent.com/25062706/174434941-b32725da-27b8-483d-b59b-9d9d4353d321.png)
  
![to_640x480](https://user-images.githubusercontent.com/25062706/174434943-8c302401-6852-49ad-8b2c-8abaf757e5e3.png)

</details>

![charts](https://user-images.githubusercontent.com/25062706/174434889-024e6931-1807-4933-a081-0e565fdc9249.png)

## Copyright and License


Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_template_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_nx_video_scaler_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
