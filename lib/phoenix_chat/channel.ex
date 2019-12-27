defmodule PhoenixChat.Channel do
  use GenServer
  alias PhoenixChat.Chat
  alias PhoenixChat.Chat.ChangeTopic
  alias PhoenixChat.Chat.Join
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message
  alias PhoenixChat.Chat.User

  defmodule State do
    defstruct [
      :backlog,
      :topic,
      :users
    ]
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def get_topic(pid) do
    GenServer.call(pid, :get_topic)
  end

  def get_users(pid) do
    GenServer.call(pid, :get_users)
  end

  def get_backlog(pid) do
    GenServer.call(pid, :get_backlog)
  end

  @impl true
  def init(chan) do
    :ok = Chat.subscribe_chan(chan)

    {:ok,
     %State{
       backlog: [],
       topic: "",
       users: %{}
     }}
  end

  @impl true
  def handle_call(:get_topic, _from, %State{topic: topic} = state) do
    {:reply, {:ok, topic}, state}
  end

  @impl true
  def handle_call(:get_users, _from, %State{users: users} = state) do
    {:reply, {:ok, users}, state}
  end

  @impl true
  def handle_call(:get_backlog, _from, %State{backlog: backlog} = state) do
    {:reply, {:ok, backlog}, state}
  end

  @impl true
  def handle_info(%ChangeTopic{} = change_topic, %State{backlog: backlog} = state) do
    %ChangeTopic{
      topic: topic
    } = change_topic

    {:noreply, %State{state | backlog: [change_topic | backlog], topic: topic}}
  end

  @impl true
  def handle_info(%Join{sender: user} = msg, %State{} = state) do
    %State{
      backlog: backlog,
      users: users
    } = state

    %User{
      user: user,
      nick: nick
    } = user

    {:noreply, %State{state | backlog: [msg | backlog], users: Map.put(users, user, nick)}}
  end

  @impl true
  def handle_info(%Leave{sender: user} = msg, %State{} = state) do
    %State{
      backlog: backlog,
      users: users
    } = state

    %User{
      user: user
    } = user

    {:noreply, %State{state | backlog: [msg | backlog], users: Map.delete(users, user)}}
  end

  @impl true
  def handle_info(%Message{} = msg, %State{} = state) do
    %State{
      backlog: backlog
    } = state

    {:noreply, %State{state | backlog: [msg | backlog]}}
  end
end
