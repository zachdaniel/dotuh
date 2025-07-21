defmodule DotuhWeb.ChatLive do
  use Elixir.DotuhWeb, :live_view

  def render(assigns) do
    ~H"""
      <div class="drawer md:drawer-open bg-base-200 h-screen overflow-hidden" id="chat-container" phx-hook="AudioController" style="height: calc(var(--vh, 1vh) * 100);">
      <!-- Hidden audio element for TTS playback -->
      <audio id="tts-audio" preload="none" style="display: none;"></audio>
      <input id="ash-ai-drawer" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col h-full">
        <div class="navbar bg-base-300 w-full px-2 py-2 flex-shrink-0">
          <div class="flex-none md:hidden">
            <label for="ash-ai-drawer" aria-label="open sidebar" class="btn btn-square btn-ghost btn-sm">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block h-5 w-5 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                >
                </path>
              </svg>
            </label>
          </div>
          <img
            src="https://github.com/ash-project/ash_ai/blob/main/logos/ash_ai.png?raw=true"
            alt="Logo"
            class="h-8 md:h-12"
            height="32"
          />
          <div class="mx-2 flex-1 px-2">
            <p :if={@conversation} class="text-sm md:text-base font-medium truncate">{build_conversation_title_string(@conversation.title)}</p>
            <p class="text-xs text-base-content/70">Dota 2 AI Coach</p>
          </div>
        </div>
        <div class="flex-1 flex flex-col min-h-0 bg-base-200">
          <!-- Audio playback hint -->
          <div class="bg-info/10 text-info text-xs px-3 py-2 text-center border-b border-info/20 md:px-4 flex-shrink-0">
            <.icon name="hero-speaker-wave" class="w-3 h-3 inline mr-1" />
            <span class="hidden sm:inline">Tap on messages with audio to play/stop</span>
            <span class="sm:hidden">Tap messages to play audio</span>
          </div>
          <div
            id="message-container"
            phx-update="stream"
            class="flex-1 overflow-y-auto px-3 py-2 flex flex-col-reverse md:px-4 md:py-3 min-h-0"
          >
            <%= for {id, message} <- @streams.messages do %>
              <div
                id={id}
                class={[
                  "chat mb-2",
                  message.source == :user && "chat-end",
                  message.source == :agent && "chat-start"
                ]}
              >
                <div :if={message.source == :agent} class="chat-image avatar">
                  <div class="w-8 md:w-10 rounded-full bg-base-300 p-1">
                    <img
                      src="https://github.com/ash-project/ash_ai/blob/main/logos/ash_ai.png?raw=true"
                      alt="Logo"
                    />
                  </div>
                </div>
                <div :if={message.source == :user} class="chat-image avatar avatar-placeholder">
                  <div class="w-8 md:w-10 rounded-full bg-base-300">
                    <.icon name="hero-user-solid" class="block w-4 h-4 md:w-5 md:h-5" />
                  </div>
                </div>
                <div 
                  class={[
                    "chat-bubble relative text-sm md:text-base max-w-xs md:max-w-md", 
                    message.audio_path && "cursor-pointer hover:bg-opacity-80 transition-all"
                  ]}
                  onclick={if message.audio_path do
                    "const audio = document.getElementById('tts-audio'); if (audio.src.endsWith('#{Path.basename(message.audio_path)}') && !audio.paused) { audio.pause(); audio.currentTime = 0; } else { audio.src = '#{message.audio_path}'; audio.play(); }"
                  end}
                  title={if message.audio_path, do: "Tap to play message, tap again to stop", else: nil}
                >
                  {to_markdown(message.text)}
                  <%= if message.audio_path do %>
                    <div class="absolute bottom-1 right-2 opacity-60">
                      <.icon name="hero-speaker-wave" class="w-3 h-3" />
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        <!-- Speech input controls -->
        <div id="speech-controls" phx-update="ignore" class="px-3 py-3 border-t bg-base-300 flex items-center justify-center gap-3 md:px-4 md:gap-4 flex-shrink-0">
          <button 
            type="button" 
            id="speech-button"
            class="btn btn-circle btn-primary btn-lg shadow-lg flex-shrink-0"
            title="Click to speak"
          >
            <.icon name="hero-microphone" class="w-6 h-6 md:w-8 md:h-8" />
          </button>
          <button 
            type="button" 
            id="stop-audio-button"
            class="btn btn-circle btn-error btn-lg shadow-lg flex-shrink-0"
            title="Stop playing audio"
            style="display: none;"
            onclick="document.getElementById('tts-audio').pause(); document.getElementById('tts-audio').currentTime = 0;"
          >
            <.icon name="hero-stop" class="w-6 h-6 md:w-8 md:h-8" />
          </button>
        </div>
        <div class="p-3 border-t md:p-4 flex-shrink-0">
          <.form
            :let={form}
            for={@message_form}
            phx-change="validate_message"
            phx-debounce="blur"
            phx-submit="send_message"
            phx-hook="SpeechRecognition"
            id="chat-form"
            class="flex items-center gap-2 md:gap-4"
          >
            <div class="flex-1">
              <input
                name={form[:text].name}
                value={form[:text].value}
                type="text"
                phx-mounted={JS.focus()}
                placeholder="Type your message..."
                class="input input-primary w-full mb-0 text-sm md:text-base"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm md:btn-md rounded-full flex-shrink-0">
              <.icon name="hero-paper-airplane" class="w-4 h-4 md:w-5 md:h-5" /> 
              <span class="hidden sm:inline">Send</span>
            </button>
          </.form>
        </div>
      </div>

      <div class="drawer-side border-r bg-base-300 w-72 md:min-w-72">
        <label for="ash-ai-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
        <div class="py-4 px-4 md:px-6 h-full bg-base-300">
          <.header class="text-lg md:text-xl">
            Conversations
          </.header>
          <div class="mb-4">
            <.link navigate={~p"/chat"} class="btn btn-primary w-full mb-2">
              <div class="rounded-full bg-primary-content text-primary w-5 h-5 flex items-center justify-center">
                <.icon name="hero-plus" class="w-3 h-3" />
              </div>
              <span>New Chat</span>
            </.link>
          </div>
          <ul class="flex flex-col-reverse" phx-update="stream" id="conversations-list">
            <%= for {id, conversation} <- @streams.conversations do %>
              <li id={id}>
                <.link
                  href={~p"/chat/#{conversation.id}"}
                  phx-value-id={conversation.id}
                  class={"block py-2 px-2 md:px-3 transition border-l-4 mb-2 text-sm md:text-base rounded-r #{if @conversation && @conversation.id == conversation.id, do: "border-primary font-medium bg-primary/10", else: "border-transparent hover:bg-base-200"}"}
                >
                  <div class="truncate">
                    {build_conversation_title_string(conversation.title)}
                  </div>
                </.link>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  def build_conversation_title_string(title) do
    cond do
      title == nil -> "Untitled conversation"
      is_binary(title) && String.length(title) > 25 -> String.slice(title, 0, 25) <> "..."
      is_binary(title) && String.length(title) <= 25 -> title
    end
  end

  def mount(_params, _session, socket) do
    DotuhWeb.Endpoint.subscribe("chat:conversations")

    socket =
      socket
      |> assign(:page_title, "Chat")
      |> stream(
        :conversations,
        Dotuh.Chat.list_conversations!()
      )
      |> assign(:messages, [])

    {:ok, socket}
  end

  def handle_params(%{"conversation_id" => conversation_id}, _, socket) do
    conversation =
      Dotuh.Chat.get_conversation!(conversation_id)

    cond do
      socket.assigns[:conversation] && socket.assigns[:conversation].id == conversation.id ->
        :ok

      socket.assigns[:conversation] ->
        DotuhWeb.Endpoint.unsubscribe("chat:messages:#{socket.assigns.conversation.id}")
        DotuhWeb.Endpoint.unsubscribe("chat:#{socket.assigns.conversation.id}")
        DotuhWeb.Endpoint.subscribe("chat:messages:#{conversation.id}")
        DotuhWeb.Endpoint.subscribe("chat:#{conversation.id}")

      true ->
        DotuhWeb.Endpoint.subscribe("chat:messages:#{conversation.id}")
        DotuhWeb.Endpoint.subscribe("chat:#{conversation.id}")
    end

    socket
    |> assign(:conversation, conversation)
    |> stream(:messages, Dotuh.Chat.message_history!(conversation.id, stream?: true))
    |> assign_message_form()
    |> then(&{:noreply, &1})
  end

  def handle_params(_, _, socket) do
    if socket.assigns[:conversation] do
      DotuhWeb.Endpoint.unsubscribe("chat:messages:#{socket.assigns.conversation.id}")
      DotuhWeb.Endpoint.unsubscribe("chat:#{socket.assigns.conversation.id}")
    end

    socket
    |> assign(:conversation, nil)
    |> stream(:messages, [])
    |> assign_message_form()
    |> then(&{:noreply, &1})
  end

  def handle_event("validate_message", %{"form" => params}, socket) do
    {:noreply,
     assign(socket, :message_form, AshPhoenix.Form.validate(socket.assigns.message_form, params))}
  end

  def handle_event("send_message", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.message_form, params: params) do
      {:ok, message} ->
        if socket.assigns.conversation do
          socket
          |> assign_message_form()
          |> stream_insert(:messages, message, at: 0)
          |> then(&{:noreply, &1})
        else
          {:noreply,
           socket
           |> push_navigate(to: ~p"/chat/#{message.conversation_id}")}
        end

      {:error, form} ->
        {:noreply, assign(socket, :message_form, form)}
    end
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "chat:messages:" <> conversation_id,
          payload: message
        },
        socket
      ) do
    if socket.assigns.conversation && socket.assigns.conversation.id == conversation_id do
      {:noreply, stream_insert(socket, :messages, message, at: 0)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "chat:conversations",
          payload: conversation
        },
        socket
      ) do
    socket =
      if socket.assigns.conversation && socket.assigns.conversation.id == conversation.id do
        assign(socket, :conversation, conversation)
      else
        socket
      end

    {:noreply, stream_insert(socket, :conversations, conversation)}
  end


  defp assign_message_form(socket) do
    form =
      if socket.assigns.conversation do
        Dotuh.Chat.form_to_create_message(
          private_arguments: %{conversation_id: socket.assigns.conversation.id}
        )
        |> to_form()
      else
        Dotuh.Chat.form_to_create_message()
        |> to_form()
      end

    assign(
      socket,
      :message_form,
      form
    )
  end

  defp to_markdown(text) do
    # Note that you must pass the "unsafe: true" option to first generate the raw HTML
    # in order to sanitize it. https://hexdocs.pm/mdex/MDEx.html#module-sanitize
    MDEx.to_html(text,
      extension: [
        strikethrough: true,
        tagfilter: true,
        table: true,
        autolink: true,
        tasklist: true,
        footnotes: true,
        shortcodes: true
      ],
      parse: [
        smart: true,
        relaxed_tasklist_matching: true,
        relaxed_autolinks: true
      ],
      render: [
        github_pre_lang: true,
        unsafe: true
      ],
      sanitize: MDEx.default_sanitize_options()
    )
    |> case do
      {:ok, html} ->
        html
        |> Phoenix.HTML.raw()

      {:error, _} ->
        text
    end
  end
end
