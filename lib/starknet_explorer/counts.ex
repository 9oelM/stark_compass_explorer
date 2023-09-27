defmodule StarknetExplorer.Counts do
  use Ecto.Schema
  alias StarknetExplorer.Events
  alias StarknetExplorer.Message
  alias StarknetExplorer.Transaction
  alias StarknetExplorer.{Counts, BlockUtils}
  alias StarknetExplorer.Repo

  @primary_key {:network, :string, autogenerate: false}
  schema "counts" do
    field :blocks, :integer
    field :transactions, :integer
    field :messages, :integer
    field :events, :integer
  end

  def insert_or_update(network) do
    {:ok, blocks} = BlockUtils.block_height(network)
    transactions = Transaction.get_total_count(network)
    messages = Message.get_total_count(network)
    events = Events.get_total_count(network)

    case Repo.get_by(Counts, network: Atom.to_string(network)) do
      # Count exists, let's use it
      %Counts{} = count ->
        count

      # Count not found, we build one
      nil ->
        %Counts{
          network: Atom.to_string(network)
        }
    end
    |> Ecto.Changeset.change(
      blocks: blocks,
      transactions: transactions,
      messages: messages,
      events: events
    )
    |> Repo.insert_or_update()
  end
end
