defmodule Dotuh.SimpleVdfParser do
  @moduledoc """
  Simple VDF parser using the vendored VDF implementation with bug fixes.
  """

  alias Dotuh.VDF.Reader

  @doc """
  Parse a VDF string and return the result.
  """
  def parse_string(vdf_string) do
    Reader.parse_string(vdf_string)
  end

  @doc """
  Parse a VDF file and return the result.
  """
  def parse_file(file_path) do
    case File.read(file_path) do
      {:ok, content} -> parse_string(content)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Load and parse a VDF file from the dota_data directory.
  """
  def load_vdf_file(filename) do
    file_path = Path.join(["./dota_data/dota/scripts/npc", filename])
    
    case File.read(file_path) do
      {:ok, content} -> 
        case parse_string(content) do
          {:ok, data} -> data
          {:error, _reason} -> %{}
        end
      {:error, _reason} -> %{}
    end
  end
end