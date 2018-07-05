defmodule Game.Message do
  @moduledoc """
  Player or NPC message, something said
  """

  defstruct [:type, :sender, :message, :formatted, from_gossip: false]

  alias Data.User
  alias Game.Format

  @type t :: %{
          type: :user | :npc,
          sender: User.t(),
          message: String.t(),
          formatted: String.t()
        }

  def new(user, message), do: say(user, message)

  def say(user, parsed_message) do
    parsed_message = format(parsed_message)

    %__MODULE__{
      type: :user,
      sender: user,
      message: parsed_message.message,
      formatted: Format.say({:user, user}, parsed_message)
    }
  end

  def say_to(user, character, parsed_message) do
    parsed_message = format(parsed_message)

    %__MODULE__{
      type: :user,
      sender: user,
      message: parsed_message.message,
      formatted: Format.say_to({:user, user}, character, parsed_message)
    }
  end

  def emote(user, message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.emote({:user, user}, message)
    }
  end

  def broadcast(user, channel, parsed_message) do
    parsed_message = format(parsed_message)

    %__MODULE__{
      type: :user,
      sender: user,
      message: parsed_message.message,
      formatted: Format.channel_say(channel, {:user, user}, parsed_message)
    }
  end

  def tell(user, message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.tell({:user, user}, message)
    }
  end

  def whisper(user, message) do
    message = format(message)

    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.whisper({:user, user}, message)
    }
  end

  def gossip_broadcast(channel, payload) do
    name = "#{Map.get(payload, "name", "")}@#{Map.get(payload, "game", "")}"
    message = Map.get(payload, "message", "")
    user = %{name: name}

    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.channel_say(channel, {:user, user}, %{message: message}),
      from_gossip: true,
    }
  end

  def npc(npc, message), do: npc_say(npc, message)

  def npc_say(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.say({:npc, npc}, %{message: message})
    }
  end

  def npc_emote(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.emote({:npc, npc}, message)
    }
  end

  def npc_tell(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.tell({:npc, npc}, message)
    }
  end

  @doc """
  Capitalize and punctuate a message before sending it out
  """
  @spec format(ParsedMessage.t()) :: ParsedMessage.t()
  def format(parsed_message) when is_map(parsed_message) do
    %{parsed_message | message: format(parsed_message.message)}
  end

  @spec format(String.t()) :: String.t()
  def format(message) do
    message
    |> capitalize_first_letter()
    |> maybe_punctuate()
  end

  defp capitalize_first_letter(string) do
    [letter | rest] = String.graphemes(string)
    letter = String.upcase(letter)
    Enum.join([letter | rest])
  end

  defp maybe_punctuate(message) do
    case Regex.match?(~r/[^\w]$/, message) do
      true ->
        message

      false ->
        "#{message}."
    end
  end
end
