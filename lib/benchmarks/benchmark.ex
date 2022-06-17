defmodule Benchmark do
  def run do
    args = %{
      input_path: "videos/input.h264",
      output_path: "videos/output.h264"
    }

    args_6x_ffmpeg = add_scaler(args, 320, 180, :ffmpeg)
    args_6x_nx = add_scaler(args, 320, 180, :nx)

    Benchee.run(
      %{
        "1920x1080 to 320x180 - FFmpeg" => fn -> ScalePipeline.run(args_6x_ffmpeg) end,
        "1920x1080 to 320x180 - Nx" => fn -> ScalePipeline.run(args_6x_nx) end
      },
      time: 10
    )
  end

  defp add_scaler(args, output_width, output_height, :ffmpeg) do
    Map.put(
      args,
      :scaler,
      %Membrane.FFmpeg.SWScale.Scaler{output_width: output_width, output_height: output_height}
    )
  end

  defp add_scaler(args, output_width, output_height, :nx) do
    Map.put(
      args,
      :scaler,
      %Membrane.Nx.VideoScaler{output_width: output_width, output_height: output_height}
    )
  end

  defp add_scaler(args, output_width, output_height, :only_nx) do
    Map.put(
      args,
      :scaler,
      %Membrane.Nx.VideoScaler{output_width: output_width, output_height: output_height, use_exla: false}
    )
  end
end
