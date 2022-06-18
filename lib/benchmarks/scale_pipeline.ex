defmodule ScalePipeline do
  use Membrane.Pipeline

  def run(args) do
    args = Map.put(args, :return_pid, self())

    {:ok, pid} = ScalePipeline.start_link(args)
    ScalePipeline.play(pid)

    receive do
      :finished -> :ok
    end
  end

  @impl true
  def handle_init(args) do
    children = [
      file_src: %Membrane.File.Source{location: args.input_path},
      parser: Membrane.H264.FFmpeg.Parser,
      decoder: Membrane.H264.FFmpeg.Decoder,
      scaler: args.scaler,
      encoder: Membrane.H264.FFmpeg.Encoder,
      file_sink: %Membrane.File.Sink{location: args.output_path}
    ]

    links = [
      link(:file_src)
      |> to(:parser)
      |> to(:decoder)
      |> to(:scaler)
      |> to(:encoder)
      |> to(:file_sink)
    ]

    {{:ok,
      spec: %ParentSpec{children: children, links: links, crash_group: {:group, :temporary}}},
     %{return_pid: args.return_pid}}
  end

  @impl true
  def handle_element_end_of_stream({:file_sink, :input}, _cts, %{return_pid: pid} = state) do
    send(pid, :finished)
    {:ok, state}
  end

  @impl true
  def handle_element_end_of_stream(_element, _cts, state) do
    {:ok, state}
  end

  @impl true
  def handle_crash_group_down(_crash_group_id, _ctx, %{return_pid: pid} = state) do
    send(pid, :finished)
    {:ok, state}
  end
end
