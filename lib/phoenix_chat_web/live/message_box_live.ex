defmodule PhoenixChatWeb.MessageBoxLive do
  use Phoenix.LiveView, container: {:div, class: "col h-100"}

  alias PhoenixChat.Chat
  alias PhoenixChat.Chat.ChangeTopic
  alias PhoenixChat.Chat.Join
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message
  alias PhoenixChatWeb.MessageBoxView

  def mount(_session, socket) do
    user = %PhoenixChat.Chat.User{user: "foo", nick: "foo"}
    PhoenixChat.Chat.join_chan("#test", user)

    socket =
      socket
      |> assign(messages: [])
      |> assign(user: user)
      |> assign(chan: "#test")

    {:ok, socket}
  end

  def render(assigns) do
    MessageBoxView.render("message_box.html", assigns)
  end

  def handle_event("enter_message", %{"code" => "Enter", "value" => text} = _event, socket) do
    %{
      chan: chan,
      user: user
    } = socket.assigns

    Message.new(user, chan, text)
    |> Chat.send_message()

    {:noreply, socket}
  end

  def handle_event("enter_message", _event, socket) do
    {:noreply, socket}
  end

  def handle_info(%ChangeTopic{} = _change, socket) do
    {:noreply, socket}
  end

  def handle_info(%Join{} = _join, socket) do
    {:noreply, socket}
  end

  def handle_info(%Leave{} = _leave, socket) do
    {:noreply, socket}
  end

  def handle_info(%Message{} = message, socket) do
    {:noreply, assign(socket, messages: [message])}
  end
end
