defmodule Benchmark do
  def run do
    args = %{
      input_path: "videos/input.h264",
      output_path: "videos/output.h264"
    }

    args_ffmpeg = add_scaler(args, 1280, 720, :ffmpeg)
    args_nx = add_scaler(args, 1280, 720, :nx)

    Benchee.run(
      %{
        "1920x1080 to 1280x720 - FFmpeg" => fn -> ScalePipeline.run(args_ffmpeg) end,
        "1920x1080 to 1280x720 - Nx" => fn -> ScalePipeline.run(args_nx) end
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
      %Membrane.Nx.VideoScaler{
        output_width: output_width,
        output_height: output_height,
        use_exla: false
      }
    )
  end
end
