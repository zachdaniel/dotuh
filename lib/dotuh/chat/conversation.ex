defmodule Dotuh.Chat.Conversation do
  use Ash.Resource,
    otp_app: :dotuh,
    domain: Dotuh.Chat,
    extensions: [AshOban],
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  oban do
    triggers do
      trigger :name_conversation do
        action :generate_name
        queue :conversations
        lock_for_update? false
        worker_module_name Dotuh.Chat.Message.Workers.NameConversation
        scheduler_module_name Dotuh.Chat.Message.Schedulers.NameConversation
        where expr(needs_title)
      end
    end
  end

  postgres do
    table "conversations"
    repo Dotuh.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:title]
    end

    update :generate_name do
      accept []
      transaction? false
      require_atomic? false
      change Dotuh.Chat.Conversation.Changes.GenerateName
    end
  end

  pub_sub do
    module DotuhWeb.Endpoint
    prefix "chat"

    publish_all :create, ["conversations"] do
      transform & &1.data
    end

    publish_all :update, ["conversations"] do
      transform & &1.data
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :title, :string do
      public? true
    end

    timestamps()
  end

  relationships do
    has_many :messages, Dotuh.Chat.Message do
      public? true
    end
  end

  calculations do
    calculate :needs_title, :boolean do
      calculation expr(
                    is_nil(title) and
                      (count(messages) > 3 or
                         (count(messages) > 1 and inserted_at < ago(10, :minute)))
                  )
    end
  end
end
