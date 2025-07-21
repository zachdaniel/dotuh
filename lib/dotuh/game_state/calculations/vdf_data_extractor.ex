defmodule Dotuh.GameState.Calculations.VdfDataExtractor do
  use Ash.Resource.Calculation

  @impl true
  def init(opts) do
    if opts[:vdf_file] && opts[:vdf_path] do
      {:ok, opts}
    else
      {:error, "VdfDataExtractor requires :vdf_file and :vdf_path options"}
    end
  end

  @impl true
  def calculate(records, opts, _context) do
    vdf_file = opts[:vdf_file]
    vdf_path = opts[:vdf_path]

    # Load and cache the VDF data
    vdf_data = load_vdf_data(vdf_file)

    Enum.map(records, fn record ->
      # Build the path by resolving atoms to record field values
      actual_path = build_path(vdf_path, record)
      extract_data(vdf_data, actual_path)
    end)
  end

  defp load_vdf_data(vdf_file) do
    data_path = Path.join([File.cwd!(), "dota_data", "dota", "scripts", "npc", vdf_file])

    case Dotuh.SimpleVdfParser.parse_file(data_path) do
      {:ok, data} ->
        # Return the data as-is - don't wrap it
        data

      {:error, _error} ->
        %{}
    end
  end

  defp build_path(json_path, record) when is_list(json_path) do
    Enum.map(json_path, fn
      segment when is_binary(segment) -> segment
      segment when is_atom(segment) -> Map.get(record, segment)
    end)
  end

  defp extract_data(json_data, path_segments) do
    get_nested_value(json_data, path_segments)
  end

  defp get_nested_value(data, []) do
    data
  end

  defp get_nested_value(data, [key | rest]) when is_map(data) and not is_nil(key) do
    case Map.get(data, to_string(key)) do
      nil -> nil
      value -> get_nested_value(value, rest)
    end
  end

  defp get_nested_value(_data, _path) do
    nil
  end
end
