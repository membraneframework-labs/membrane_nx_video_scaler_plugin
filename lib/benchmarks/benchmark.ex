defmodule Benchmark do
  def run do
    args = %{
      input_path: "videos/input.h264",
      output_path: "videos/output.h264"
    }

    args_2x_ffmpeg = add_scaler(args, 960, 540, :ffmpeg)
    args_2x_nx = add_scaler(args, 960, 540, :nx)

    Benchee.run(
      %{
        "1920x1080 to 960x540 - FFmpeg" => fn -> ScalePipeline.run(args_2x_ffmpeg) end,
        "1920x1080 to 960x540 - Nx" => fn -> ScalePipeline.run(args_2x_nx) end
      }
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
