defmodule PhoenixChat.Chat do
  alias Phoenix.PubSub
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message
  alias PhoenixChat.Chat.Join

  def subscribe_chan(chan) do
    PubSub.subscribe(:chans, chan)
  end

  def unsubscribe_chan(chan) do
    PubSub.unsubscribe(:chans, chan)
  end

  def broadcast(term, chan) do
    PubSub.broadcast(:chans, chan, term)
  end

  def join_chan(chan, user) do
    user
    |> Join.new(chan)
    |> broadcast(chan)

    subscribe_chan(chan)
  end

  def leave_chan(chan, user) do
    user
    |> Leave.new(chan)
    |> broadcast(chan)

    unsubscribe_chan(chan)
  end

  def send_message(%Message{destination: chan} = message) do
    PubSub.broadcast(:chans, chan, message)
  end
end
