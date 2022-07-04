defmodule Membrane.Nx.VideoScaler.Scaler do
  import Nx.Defn

  @black_luminance 0
  @black_chrominance 128

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
    |> then(&{:ok, &1})
  end

  defp prepare_opts(%{
         width: width,
         height: height,
         output_width: output_width,
         output_height: output_height
       }) do
    input_ratio = width / height
    output_ratio = output_width / output_height

    {scaled_width, scaled_height} =
      if input_ratio <= output_ratio do
        scaled_height = output_height
        scaled_width = floor(output_height * input_ratio)

        scaled_height = div(scaled_height, 2) * 2
        scaled_width = div(scaled_width, 2) * 2

        scaled_width =
          if rem(output_width - scaled_width, 4) != 0 do
            scaled_width - 2
          else
            scaled_width
          end

        {scaled_width, scaled_height}
      else
        scaled_height = floor(output_width / input_ratio)
        scaled_width = output_width

        scaled_width = div(scaled_width, 2) * 2
        scaled_height = div(scaled_height, 2) * 2

        scaled_height =
          if rem(output_height - scaled_height, 4) != 0 do
            scaled_height - 2
          else
            scaled_height
          end

        {scaled_width, scaled_height}
      end

    [
      width: width,
      height: height,
      scaled_width: scaled_width,
      scaled_height: scaled_height,
      output_width: output_width,
      output_height: output_height
    ]
  end

  defnp do_scale(payload, opts \\ []) do
    payload
    |> separate_color_components(opts)
    |> resize_components(opts)
    |> add_paddings(opts)
    |> concatenate_color_components()
  end

  defnp separate_color_components(frame, opts \\ []) do
    # Some operations requires scalars instead of tensors, so the keyword is needed to provide
    # them. It requires default values, however they are not used
    opts =
      keyword!(opts,
        width: 640,
        height: 640,
        scaled_width: 640,
        scaled_height: 640,
        output_width: 640,
        output_height: 640
      )

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
    opts =
      keyword!(opts,
        width: 640,
        height: 640,
        scaled_width: 640,
        scaled_height: 640,
        output_width: 640,
        output_height: 640
      )

    y =
      billinear_resize(y,
        width: opts[:width],
        height: opts[:height],
        output_width: opts[:scaled_width],
        output_height: opts[:scaled_height]
      )

    chrominance_width = round_number(opts[:width] / 2)
    chrominance_height = round_number(opts[:height] / 2)

    chrominance_output_width = round_number(opts[:scaled_width] / 2)
    chrominance_output_height = round_number(opts[:scaled_height] / 2)

    u =
      billinear_resize(u,
        width: chrominance_width,
        height: chrominance_height,
        output_width: chrominance_output_width,
        output_height: chrominance_output_height
      )

    v =
      billinear_resize(v,
        width: chrominance_width,
        height: chrominance_height,
        output_width: chrominance_output_width,
        output_height: chrominance_output_height
      )

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
      (x_ratio * x)
      |> Nx.floor()
      |> Nx.as_type({:u, 32})

    y_low =
      (y_ratio * y)
      |> Nx.floor()
      |> Nx.as_type({:u, 32})

    x_high =
      (x_ratio * x)
      |> Nx.ceil()
      |> Nx.min(width - 1)
      |> Nx.as_type({:u, 32})

    y_high =
      (y_ratio * y)
      |> Nx.ceil()
      |> Nx.min(height - 1)
      |> Nx.as_type({:u, 32})

    x_weight = x_ratio * x - x_low
    y_weight = y_ratio * y - y_low

    a = Nx.gather(tensor, Nx.reshape(y_low * width + x_low, {:auto, 1}))
    b = Nx.gather(tensor, Nx.reshape(y_low * width + x_high, {:auto, 1}))
    c = Nx.gather(tensor, Nx.reshape(y_high * width + x_low, {:auto, 1}))
    d = Nx.gather(tensor, Nx.reshape(y_high * width + x_high, {:auto, 1}))

    (a * (1 - x_weight) * (1 - y_weight) + b * x_weight * (1 - y_weight) +
       c * (1 - x_weight) * y_weight + d * x_weight * y_weight)
    |> Nx.floor()
    |> Nx.as_type({:u, 8})
  end

  defnp add_paddings({y, u, v}, opts \\ []) do
    opts =
      keyword!(opts,
        width: 640,
        height: 640,
        scaled_width: 640,
        scaled_height: 640,
        output_width: 640,
        output_height: 640
      )

    scaled_width = opts[:scaled_width]
    scaled_height = opts[:scaled_height]
    output_width = opts[:output_width]
    output_height = opts[:output_height]

    # Paddigns offsets have to lists, but returning list from `if` clause results in compilation
    # error. Returning tuple and making a list later is a workaround.
    {padding_offset_luminance_y, padding_offset_luminance_x} =
      if scaled_height == output_height do
        {0, round_number((output_width - scaled_width) / 2)}
      else
        {round_number((output_height - scaled_height) / 2), 0}
      end

    paddign_offset_luminance = [padding_offset_luminance_y, padding_offset_luminance_x]

    {padding_offset_chrominance_y, padding_offset_chrominance_x} =
      if scaled_height == output_height do
        {0, round_number((output_width - scaled_width) / 4)}
      else
        {round_number((output_height - scaled_height) / 4), 0}
      end

    padding_offset_chrominance = [padding_offset_chrominance_y, padding_offset_chrominance_x]

    y = Nx.reshape(y, {scaled_height, scaled_width})

    padded_y =
      @black_luminance
      |> Nx.broadcast({output_height, output_width})
      |> Nx.as_type({:u, 8})
      |> Nx.put_slice(paddign_offset_luminance, y)
      |> Nx.reshape({output_width * output_height})

    scaled_width_chrominance = round_number(scaled_width / 2)
    scaled_height_chrominance = round_number(scaled_height / 2)

    output_width_chrominance = round_number(output_width / 2)
    output_height_chrominance = round_number(output_height / 2)

    output_shape_chrominance = {round_number(output_width * output_height / 4)}

    u = Nx.reshape(u, {scaled_height_chrominance, scaled_width_chrominance})

    padded_u =
      @black_chrominance
      |> Nx.broadcast({output_height_chrominance, output_width_chrominance})
      |> Nx.as_type({:u, 8})
      |> Nx.put_slice(padding_offset_chrominance, u)
      |> Nx.reshape(output_shape_chrominance)

    v = Nx.reshape(v, {scaled_height_chrominance, scaled_width_chrominance})

    padded_v =
      @black_chrominance
      |> Nx.broadcast({output_height_chrominance, output_width_chrominance})
      |> Nx.as_type({:u, 8})
      |> Nx.put_slice(padding_offset_chrominance, v)
      |> Nx.reshape(output_shape_chrominance)

    {padded_y, padded_u, padded_v}
  end

  defnp concatenate_color_components({y, u, v}) do
    Nx.concatenate([y, u, v])
  end

  defnp round_number(value) do
    transform(value, &floor/1)
  end
end
