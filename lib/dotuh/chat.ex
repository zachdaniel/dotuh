defmodule Dotuh.Chat do
  use Ash.Domain, otp_app: :dotuh, extensions: [AshPhoenix]

  resources do
    resource Dotuh.Chat.Conversation do
      define :create_conversation, action: :create
      define :get_conversation, action: :read, get_by: [:id]
      define :list_conversations, action: :read
    end

    resource Dotuh.Chat.Message do
      define :message_history,
        action: :for_conversation,
        args: [:conversation_id],
        default_options: [query: [sort: [inserted_at: :desc]]]

      define :create_message, action: :create
    end
  end
end
