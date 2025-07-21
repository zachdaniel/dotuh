defmodule Dotuh.TTS do
  @moduledoc """
  OpenAI Text-to-Speech integration using Req
  """

  @openai_tts_url "https://api.openai.com/v1/audio/speech"

  @doc """
  Generate speech from text using OpenAI TTS API

  ## Parameters
  - text: The text to convert to speech
  - voice: Voice to use (default: "onyx")
  - speed: Speech speed (default: 1.1)
  - model: TTS model (default: "tts-1")

  ## Returns
  {:ok, audio_binary} or {:error, reason}
  """
  def create_voice(text, opts \\ []) do
    voice = Keyword.get(opts, :voice, "onyx")
    speed = Keyword.get(opts, :speed, 1.1)
    model = Keyword.get(opts, :model, "tts-1")

    case get_api_key() do
      {:ok, api_key} ->
        make_request(text, voice, speed, model, api_key)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generate TTS audio and save to static assets organized by game_id/message_id
  Returns the web path to the audio file
  """
  def create_audio_file(text, game_id, message_id, opts \\ []) do
    case create_voice(text, opts) do
      {:ok, audio_data} ->
        save_to_game_assets(audio_data, game_id, message_id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Legacy function for backwards compatibility
  """
  def create_audio_file(text, opts) when is_list(opts) do
    case create_voice(text, opts) do
      {:ok, audio_data} ->
        save_to_static_assets(audio_data)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generate and play TTS audio with automatic cleanup (for backwards compatibility)
  """
  def speak(text, opts \\ []) do
    case create_voice(text, opts) do
      {:ok, audio_data} ->
        play_audio(audio_data)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_api_key do
    case System.get_env("OPENAI_API_KEY") do
      nil -> {:error, "OPENAI_API_KEY environment variable not set"}
      "" -> {:error, "OPENAI_API_KEY environment variable is empty"}
      key -> {:ok, key}
    end
  end

  defp make_request(text, voice, speed, model, api_key) do
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      model: model,
      input: text,
      voice: voice,
      speed: speed,
      response_format: "mp3"
    }

    case Req.post(@openai_tts_url, headers: headers, json: body) do
      {:ok, %{status: 200, body: audio_data}} ->
        {:ok, audio_data}

      {:ok, %{status: status, body: body}} ->
        error_msg = extract_error_message(body)
        {:error, "OpenAI API error #{status}: #{error_msg}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  rescue
    e ->
      {:error, "Exception during TTS request: #{inspect(e)}"}
  end

  defp extract_error_message(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, %{"error" => %{"message" => message}}} -> message
      _ -> body
    end
  end

  defp extract_error_message(body), do: inspect(body)

  defp save_to_game_assets(audio_data, game_id, message_id) do
    try do
      # Create filename based on message ID
      filename = "#{message_id}.mp3"

      # Create game-specific directory
      game_audio_dir = Path.join([:code.priv_dir(:dotuh), "static", "assets", "audio", game_id])
      File.mkdir_p!(game_audio_dir)

      # Save file
      file_path = Path.join(game_audio_dir, filename)
      File.write!(file_path, audio_data)

      # Return web path
      web_path = "/assets/audio/#{game_id}/#{filename}"
      {:ok, web_path}
    rescue
      e ->
        {:error, "Failed to save audio file: #{inspect(e)}"}
    end
  end

  defp save_to_static_assets(audio_data) do
    try do
      # Create unique filename
      filename = "tts_#{System.unique_integer([:positive])}.mp3"

      # Ensure audio directory exists
      audio_dir = Path.join([:code.priv_dir(:dotuh), "static", "assets", "audio"])
      File.mkdir_p!(audio_dir)

      # Save file
      file_path = Path.join(audio_dir, filename)
      File.write!(file_path, audio_data)

      # Return web path
      web_path = "/assets/audio/#{filename}"
      {:ok, web_path}
    rescue
      e ->
        {:error, "Failed to save audio file: #{inspect(e)}"}
    end
  end

  defp play_audio(audio_data) do
    try do
      # Save to temporary file
      temp_file = "/tmp/dotuh_tts_#{System.unique_integer([:positive])}.mp3"
      File.write!(temp_file, audio_data)

      # Play with afplay (macOS)
      case System.cmd("afplay", [temp_file]) do
        {_output, 0} ->
          File.rm(temp_file)
          :ok

        {_output, exit_code} ->
          File.rm(temp_file)
          {:error, "Audio playback failed with exit code #{exit_code}"}
      end
    rescue
      e ->
        {:error, "Audio playback error: #{inspect(e)}"}
    end
  end

  @doc """
  Clean text for TTS by removing formatting and unwanted content
  """
  def clean_text_for_speech(text) do
    text
    # Remove tool calls and results (they appear in brackets)
    |> String.replace(~r/\[.*?\]/, "")
    # Remove markdown formatting
    # Bold
    |> String.replace(~r/\*\*(.*?)\*\*/, "\\1")
    # Italic  
    |> String.replace(~r/\*(.*?)\*/, "\\1")
    # Code
    |> String.replace(~r/`(.*?)`/, "\\1")
    # Remove extra whitespace
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  @doc """
  Clean up old game audio folders that don't match the current game
  """
  def cleanup_old_game_folders(current_game_id) do
    try do
      audio_dir = Path.join([:code.priv_dir(:dotuh), "static", "assets", "audio"])

      if File.exists?(audio_dir) do
        audio_dir
        |> File.ls!()
        |> Enum.filter(fn name ->
          # Only look at directories, not files
          path = Path.join(audio_dir, name)
          File.dir?(path) && name != current_game_id
        end)
        |> Enum.each(fn game_folder ->
          game_path = Path.join(audio_dir, game_folder)
          File.rm_rf!(game_path)
          IO.puts("🗑️ Cleaned up old game audio folder: #{game_folder}")
        end)
      end

      :ok
    rescue
      e ->
        IO.puts("⚠️ Error cleaning up game folders: #{inspect(e)}")
        :ok
    end
  end

  @doc """
  Clean up old TTS audio files (older than 1 hour) - legacy cleanup
  """
  def cleanup_old_audio_files do
    try do
      audio_dir = Path.join([:code.priv_dir(:dotuh), "static", "assets", "audio"])

      if File.exists?(audio_dir) do
        one_hour_ago = System.system_time(:second) - 3600

        audio_dir
        |> File.ls!()
        |> Enum.filter(&String.starts_with?(&1, "tts_"))
        |> Enum.each(fn filename ->
          file_path = Path.join(audio_dir, filename)

          case File.stat(file_path) do
            {:ok, %{mtime: mtime}} ->
              file_time = :calendar.datetime_to_gregorian_seconds(mtime)
              unix_epoch = :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
              file_timestamp = file_time - unix_epoch

              if file_timestamp < one_hour_ago do
                File.rm(file_path)
              end

            _ ->
              :ok
          end
        end)
      end

      :ok
    rescue
      _e -> :ok
    end
  end
end
