defmodule Membrane.Nx.VideoScaler do
  use Membrane.Filter

  alias Membrane.{Buffer, RawVideo}
  alias Membrane.Nx.VideoScaler.Scaler

  def_options output_width: [
                type: :int,
                description: "Width of the scaled video."
              ],
              output_height: [
                type: :int,
                description: "Height of the scaled video."
              ],
              use_exla: [
                type: :boolean,
                description: "Whether EXLA compiler should be used.",
                default: true
              ]

  def_input_pad :input,
    demand_unit: :buffers,
    demand_mode: :auto,
    caps: {RawVideo, pixel_format: :I420, aligned: true}

  def_output_pad :output,
    demand_mode: :auto,
    caps: {RawVideo, pixel_format: :I420, aligned: true}

  @impl true
  def handle_init(options) do
    state = Map.from_struct(options)

    {:ok, state}
  end

  @impl true
  def handle_process(:input, %Buffer{payload: payload} = buffer, _context, state) do
    case Scaler.scale(payload, state) do
      {:ok, frame} ->
        buffer = [buffer: {:output, %{buffer | payload: frame}}]
        {{:ok, buffer}, state}

      {:error, reason} ->
        {{:error, reason}, state}
    end
  end

  @impl true
  def handle_caps(:input, %RawVideo{width: width, height: height} = caps, _context, state) do
    caps = %{caps | width: state.output_width, height: state.output_height}
    state = Map.merge(state, %{width: width, height: height})

    {{:ok, caps: {:output, caps}}, state}
  end

  @impl true
  def handle_end_of_stream(:input, _context, state) do
    {{:ok, end_of_stream: :output, notify: {:end_of_stream, :input}}, state}
  end
end
