defmodule Membrane.Nx.VideoScaler.Scaler do
  import Nx.Defn

  def scale(payload, state) do
    opts = prepare_opts(state)

    payload
    |> Nx.from_binary({:u, 8})
    |> then(fn payload ->
      if state.use_exla do
        EXLA.jit(&do_scale(&1, opts), [payload])
      else
        do_scale(payload, opts)
      end
    end)
    |> Nx.to_binary()
    |> then(& {:ok, &1})
  end

  defp prepare_opts(%{width: width, height: height, output_width: output_width, output_height: output_height}) do
    [
      width: width,
      height: height,
      output_width: output_width,
      output_height: output_height
    ]
  end

  defnp do_scale(payload, opts \\ []) do
    payload
    |> separate_color_components(opts)
    |> resize_components(opts)
    |> concatenate_color_components()
  end

  defnp separate_color_components(frame, opts \\ []) do
    opts = keyword!(opts, width: 640, height: 640, output_width: 640, output_height: 640)

    width = opts[:width]
    height = opts[:height]

    first_v_value_index = round_number(width * height * 5 / 4)
    frame_length = round_number(width * height * 3 / 2)

    y = frame[0..(width * height - 1)]
    u = frame[(width * height)..(first_v_value_index - 1)]
    v = frame[first_v_value_index..(frame_length - 1)]

    {y, u, v}
  end

  defnp resize_components({y, u, v}, opts \\ []) do
    opts = keyword!(opts, width: 640, height: 640, output_width: 640, output_height: 640)

    y = billinear_resize(y, [width: opts[:width], height: opts[:height], output_width: opts[:output_width], output_height: opts[:output_height]])

    chrominance_width = round_number(opts[:width] / 2)
    chrominance_height = round_number(opts[:height] / 2)

    chrominance_output_width = round_number(opts[:output_width] / 2)
    chrominance_output_height = round_number(opts[:output_height] / 2)

    u = billinear_resize(u, [width: chrominance_width, height: chrominance_height, output_width: chrominance_output_width, output_height: chrominance_output_height])
    v = billinear_resize(v, [width: chrominance_width, height: chrominance_height, output_width: chrominance_output_width, output_height: chrominance_output_height])

    {y, u, v}
  end

  defnp billinear_resize(tensor, opts \\ []) do
    opts = keyword!(opts, width: 640, height: 640, output_width: 640, output_height: 640)

    width = opts[:width]
    height = opts[:height]
    output_width = opts[:output_width]
    output_height = opts[:output_height]

    x_ratio = (width - 1) / (output_width - 1)
    y_ratio = (height - 1) / (output_height - 1)

    x =
      {output_width * output_height}
      |> Nx.iota()
      |> Nx.remainder(output_width)

    y =
      {output_width * output_height}
      |> Nx.iota()
      |> Nx.quotient(output_width)

    x_low =
      x_ratio * x
      |> Nx.floor()
      |> Nx.as_type({:u, 32})

    y_low =
      y_ratio * y
      |> Nx.floor()
      |> Nx.as_type({:u, 32})

    x_high =
      x_ratio * x
      |> Nx.ceil()
      |> Nx.min(width - 1)
      |> Nx.as_type({:u, 32})

    y_high =
      y_ratio * y
      |> Nx.ceil()
      |> Nx.min(height - 1)
      |> Nx.as_type({:u, 32})

    x_weight = (x_ratio * x) - x_low
    y_weight = (y_ratio * y) - y_low

    a = Nx.gather(tensor, Nx.reshape(y_low * width + x_low, {:auto, 1}))
    b = Nx.gather(tensor, Nx.reshape(y_low * width + x_high, {:auto, 1}))
    c = Nx.gather(tensor, Nx.reshape(y_high * width + x_low, {:auto, 1}))
    d = Nx.gather(tensor, Nx.reshape(y_high * width + x_high, {:auto, 1}))

    a * (1 - x_weight) * (1 - y_weight) + b * x_weight * (1 - y_weight) + c * (1 - x_weight) * y_weight + d * x_weight * y_weight
    |> Nx.floor()
    |> Nx.as_type({:u, 8})
  end

  defnp concatenate_color_components({y, u, v}) do
    Nx.concatenate([y, u, v])
  end

  defnp round_number(value) do
    transform(value, &floor/1)
  end
end
