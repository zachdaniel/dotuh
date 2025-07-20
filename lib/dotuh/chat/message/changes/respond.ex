defmodule Dotuh.Chat.Message.Changes.Respond do
  use Ash.Resource.Change
  require Ash.Query

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI

  @impl true
  def change(changeset, _opts, context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      message = changeset.data

      messages =
        Dotuh.Chat.Message
        |> Ash.Query.filter(conversation_id == ^message.conversation_id)
        |> Ash.Query.filter(id != ^message.id)
        |> Ash.Query.select([:text, :source, :tool_calls, :tool_results])
        |> Ash.Query.sort(inserted_at: :asc)
        |> Ash.read!()
        |> Enum.concat([%{source: :user, text: message.text}])

      # Get the current active game to fetch game notes and hero information
      current_game =
        case Dotuh.GameState.Game
             |> Ash.Query.filter(active == true)
             |> Ash.Query.sort(inserted_at: :desc)
             |> Ash.Query.limit(1)
             |> Ash.Query.load([:game_notes, :heroes])
             |> Ash.read_one() do
          {:ok, game} -> game
          _ -> nil
        end

      # Get game notes if there's an active game
      game_notes_text =
        case current_game do
          nil ->
            ""

          game ->
            case game.game_notes do
              [] ->
                ""

              notes ->
                formatted_notes =
                  Enum.map(notes, fn note ->
                    "- [#{note.game_time}s] #{note.note}"
                  end)

                "\n\nGAME NOTES - Current game observations and context:\n" <>
                  Enum.join(formatted_notes, "\n")
            end
        end

      # Get hero information if there's an active game
      heroes_text =
        case current_game do
          nil ->
            ""

          game ->
            case game.heroes do
              [] ->
                ""

              heroes ->
                radiant_heroes = Enum.filter(heroes, fn h -> h.team == "radiant" end)
                dire_heroes = Enum.filter(heroes, fn h -> h.team == "dire" end)

                current_player =
                  Enum.find(heroes, fn h -> h.is_current_player end)

                radiant_names = Enum.map(radiant_heroes, & &1.name) |> Enum.join(", ")
                dire_names = Enum.map(dire_heroes, & &1.name) |> Enum.join(", ")

                player_team =
                  case current_player do
                    nil -> ""
                    player -> "\nYou are playing #{player.name} on #{player.team} team."
                  end

                "\n\nCURRENT HEROES:\n" <>
                  "Radiant: #{radiant_names}\n" <>
                  "Dire: #{dire_names}" <>
                  player_team
            end
        end

      # Get all active player notes to include in context
      player_notes =
        case Dotuh.GameState.PlayerNote |> Ash.read() do
          {:ok, notes} -> notes
          _ -> []
        end

      player_notes_text =
        case player_notes do
          [] ->
            ""

          notes ->
            formatted_notes =
              Enum.map(notes, fn note ->
                "- #{note.player_name} (#{note.priority}): #{note.note_text}"
              end)

            "\n\nPLAYER NOTES - Use these observations to provide better coaching:\n" <>
              Enum.join(formatted_notes, "\n")
        end

      system_prompt =
        LangChain.Message.new_system!("""
        You are a helpful Dota 2 AI coach chat bot.
        Your job is to use the tools at your disposal to assist the user with Dota 2 gameplay.
        You have access to real-time game state data and can provide strategic advice based on the current match situation.

        REMEMBER: The user is actively playing a game while using you, so you must be as concise as possible.
        The focus is on providing actionable advice, not on providing as detailed information as possible.

        Your responses may be spoken aloud as well, another reason to stay concise.

        BE CONCISE, in a way a human coach might be. For example:

        > What does Black King Bar do?
        ---
        > It makes you immune to spells when you use it, with a shorter duration each time you use it.

        If the user asks a specific question, provide a specific answer. For example:

        > How long is its cool down?
        > 95 seconds

        IMPORTANT NOTE MANAGEMENT:
        - Actively use add_game_note when the user mentions situational observations ("I keep getting ganked", "they're grouping up")
        - Use add_player_note when you notice or the user mentions specific player patterns ("Pudge player is very aggressive", "their carry farms jungle early")
        - Remove outdated notes with destroy_game_note or destroy_player_note when patterns change
        - Review player notes before giving advice to provide personalized coaching

        LOCATION AWARENESS & ALERTS:
        - Monitor hero movements with get_recent_hero_movements to spot rotations and ganks
        - Alert about significant enemy movements: "Enemy spotted in Roshan pit" or "Missing mid hero last seen in river"
        - Use get_location_activity to check if enemies are in key areas before recommending actions
        - Provide location-based warnings: "Be careful, enemy was spotted in your jungle recently"
        - Keep alerts terse and actionable for active gameplay
        - Always use "enemy <hero>" and "allied <hero>" when talking about heroes
        #{player_notes_text}
        #{game_notes_text}
        #{heroes_text}
        """)

      message_chain = message_chain(messages)

      new_message_id = Ash.UUID.generate()

      %{
        llm: ChatOpenAI.new!(%{model: "gpt-4o", stream: true}),
        custom_context: Map.new(Ash.Context.to_opts(context)),
        verbose: true
      }
      |> LLMChain.new!()
      |> LLMChain.add_message(system_prompt)
      |> LLMChain.add_messages(message_chain)
      # add the names of tools you want available in your conversation here.
      # i.e tools: [:lookup_weather]
      |> AshAi.setup_ash_ai(
        otp_app: :dotuh,
        tools: [
          :get_current_game_state,
          :add_game_note,
          :get_game_notes,
          :get_recent_game_notes,
          :destroy_game_note,
          :add_player_note,
          :get_player_notes,
          :get_all_player_notes,
          :destroy_player_note,
          :get_recent_hero_movements,
          :get_hero_location_history,
          :get_location_activity,
          :query_hero_data,
          :query_item_data,
          :query_ability_data,
          :search_heroes,
          :search_items,
          :list_heroes,
          :list_items,
          :list_abilities,
          :query_hero_abilities
        ],
        actor: context.actor
      )
      |> LLMChain.add_callback(%{
        on_llm_new_delta: fn _model, data ->
          if data.content && data.content != "" do
            Dotuh.Chat.Message
            |> Ash.Changeset.for_create(
              :upsert_response,
              %{
                id: new_message_id,
                response_to_id: message.id,
                conversation_id: message.conversation_id,
                text: data.content
              },
              actor: %AshAi{}
            )
            |> Ash.create!()
          end
        end,
        on_message_processed: fn _chain, data ->
          if (data.tool_calls && Enum.any?(data.tool_calls)) ||
               (data.tool_results && Enum.any?(data.tool_results)) ||
               data.content not in [nil, ""] do
            Dotuh.Chat.Message
            |> Ash.Changeset.for_create(
              :upsert_response,
              %{
                id: new_message_id,
                response_to_id: message.id,
                conversation_id: message.conversation_id,
                complete: true,
                tool_calls:
                  data.tool_calls &&
                    Enum.map(
                      data.tool_calls,
                      &Map.take(&1, [:status, :type, :call_id, :name, :arguments, :index])
                    ),
                tool_results:
                  data.tool_results &&
                    Enum.map(
                      data.tool_results,
                      &Map.take(&1, [
                        :type,
                        :tool_call_id,
                        :name,
                        :content,
                        :display_text,
                        :is_error,
                        :options
                      ])
                    ),
                text: data.content || ""
              },
              actor: %AshAi{}
            )
            |> Ash.create!()
          end
        end
      })
      |> LLMChain.run(mode: :while_needs_response)

      changeset
    end)
  end

  defp message_chain(messages) do
    Enum.flat_map(messages, fn
      %{source: :agent} = message ->
        langchain_message =
          LangChain.Message.new_assistant!(%{
            content: message.text,
            tool_calls:
              message.tool_calls &&
                Enum.map(
                  message.tool_calls,
                  &LangChain.Message.ToolCall.new!(
                    Map.take(&1, ["status", "type", "call_id", "name", "arguments", "index"])
                  )
                )
          })

        if message.tool_results && !Enum.empty?(message.tool_results) do
          [
            langchain_message,
            LangChain.Message.new_tool_result!(%{
              tool_results:
                Enum.map(
                  message.tool_results,
                  &LangChain.Message.ToolResult.new!(
                    Map.take(&1, [
                      "type",
                      "tool_call_id",
                      "name",
                      "content",
                      "display_text",
                      "is_error",
                      "options"
                    ])
                  )
                )
            })
          ]
        else
          [langchain_message]
        end

      %{source: :user, text: text} ->
        [LangChain.Message.new_user!(text)]
    end)
  end
end
