defmodule Game.NPC do
  @moduledoc """
  Server for an NPC
  """

  use GenServer
  use Game.Room

  alias Data.Repo
  alias Data.NPC

  alias Game.Message

  @doc """
  Starts a new NPC server

  Will have a registered name with the return from `Game.NPC.pid/1`.
  """
  def start_link(npc) do
    GenServer.start_link(__MODULE__, npc, name: pid(npc.id))
  end

  @doc """
  Helper for determining an NPCs registered process name
  """
  @spec pid(id :: integer()) :: atom
  def pid(id) do
    {:via, Registry, {Game.NPC.Registry, id}}
  end

  @doc """
  Load all NPCs in the database
  """
  @spec all() :: [map]
  def all() do
    NPC |> Repo.all
  end

  @doc """
  The NPC overheard a message

  Hook to respond to echos
  """
  @spec heard(id :: integer, message :: Message.t) :: :ok
  def heard(id, message) do
    GenServer.cast(pid(id), {:heard, message})
  end

  def init(npc) do
    GenServer.cast(self(), :enter)
    {:ok, %{npc: npc}}
  end

  def handle_cast(:enter, state = %{npc: npc}) do
    @room.enter(npc.room_id, {:npc, npc})
    {:noreply, state}
  end
  def handle_cast({:heard, message}, state = %{npc: npc}) do
    case message.message do
      "Hello" <> _ ->
        npc.room_id |> @room.say(npc, Message.npc(npc, npc |> message))
      _ -> nil
    end
    {:noreply, state}
  end
  def handle_cast({:targeted, player}, state = %{npc: npc}) do
    npc.room_id |> @room.say(npc, Message.npc(npc, "Why are you targeting me, #{player.name}?"))
    {:noreply, state}
  end

  defp message(%{hostile: true}), do: "Die!"
  defp message(%{hostile: false}), do: "How are you?"
end