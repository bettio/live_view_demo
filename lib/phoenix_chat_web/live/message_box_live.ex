defmodule PhoenixChatWeb.MessageBoxLive do
  use Phoenix.LiveView, container: {:section, class: "row h-100"}

  alias PhoenixChat.Channels
  alias PhoenixChat.Chat
  alias PhoenixChat.Chat.ChangeTopic
  alias PhoenixChat.Chat.Join
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message
  alias PhoenixChat.Chat.User
  alias PhoenixChatWeb.MessageBoxView

  def mount(_session, socket) do
    random_id = UUID.uuid1()

    user = %User{
      user: "#{random_id}-live",
      nick: "user#{random_id}"
    }

    types = %{text: :string}
    initial_message =
      {%{}, types}
      |> Ecto.Changeset.cast(%{text: ""}, Map.keys(types))

    socket =
      socket
      |> assign(messages: [])
      |> assign(user: user)
      |> assign(chan: "")
      |> assign(chan_topic: "")
      |> assign(chan_users: [])
      |> assign(joined_chans: [])
      |> assign(user_message: initial_message)

    {:ok, socket}
  end

  def render(assigns) do
    MessageBoxView.render("message_box.html", assigns)
  end

  defp handle_command("LEAVE " <> leave_chan, socket) do
    chan_name = String.trim(leave_chan)

    Chat.leave_chan(chan_name, socket.assigns[:user])

    joined_chans =
      socket.assigns[:joined_chans]
      |> List.delete(chan_name)

    socket =
      socket
      |> assign(chan: "")
      |> assign(chan_topic: "")
      |> assign(chan_users: [])
      |> assign(joined_chans: joined_chans)
      |> assign(input_reset_id: UUID.uuid1())

    {:noreply, socket}
  end

  defp handle_command("JOIN " <> join_chan, socket) do
    chan_name = String.trim(join_chan)
    Chat.join_chan(chan_name, socket.assigns[:user])

    socket =
      socket
      |> assign(joined_chans: [chan_name | socket.assigns[:joined_chans]])
      |> change_active_chan(chan_name)
      |> assign(input_reset_id: UUID.uuid1())

    {:noreply, socket}
  end

  def handle_event("enter_message", %{"code" => "Enter", "value" => "/" <> cmd} = _evt, socket) do
    cmd
    |> String.upcase()
    |> handle_command(socket)
  end

  def handle_event("enter_message", %{"form_params" => form_params} = _event, socket) do
    %{
      chan: chan,
      user: user
    } = socket.assigns

    types = %{text: :string}
    user_message_changeset =
      {%{}, types}
      |> Ecto.Changeset.cast(form_params, Map.keys(types))

    {:ok, user_message} =
      Ecto.Changeset.apply_action(user_message_changeset, :insert)

    Message.new(user, chan, user_message.text)
      |> Chat.send_message()

    {:noreply, socket}
  end

  def handle_event("enter_message", _event, socket) do
    {:noreply, socket}
  end

  def handle_event("change_chan", %{"chan" => chan} = _event, socket) do
    {:noreply, change_active_chan(socket, chan)}
  end

  defp change_active_chan(socket, chan_name) do
    {:ok, chan} = Channels.fetch(chan_name)
    chan_topic = PhoenixChat.Channel.get_topic(chan)
    users_map = PhoenixChat.Channel.get_users(chan)
    chan_users = Map.values(users_map)

    socket
    |> assign(chan: chan_name)
    |> assign(chan_topic: chan_topic)
    |> assign(chan_users: chan_users)
  end

  def handle_info(%ChangeTopic{topic: new_topic} = change_topic, socket) do
    active_chan = socket.assigns[:chan]

    socket =
      if change_topic.channel == active_chan do
        socket
        |> assign(messages: [change_topic])
        |> assign(chan_topic: new_topic)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(%Join{} = join, socket) do
    active_chan = socket.assigns[:chan]

    socket =
      if join.channel == active_chan do
        users_list =
          [join.sender.nick | socket.assigns[:chan_users]]
          |> Enum.sort()
          |> Enum.dedup()

        socket
        |> assign(messages: [join])
        |> assign(chan_users: users_list)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(%Leave{} = leave, socket) do
    active_chan = socket.assigns[:chan]

    socket =
      if leave.channel == active_chan do
        users_list =
          socket.assigns[:chan_users]
          |> List.delete(leave.sender.nick)
          |> Enum.sort()

        socket
        |> assign(messages: [leave])
        |> assign(chan_users: users_list)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(%Message{} = message, socket) do
    active_chan = socket.assigns[:chan]

    socket =
      if message.destination == active_chan do
        assign(socket, messages: [message])
      else
        socket
      end

    {:noreply, socket}
  end
end
