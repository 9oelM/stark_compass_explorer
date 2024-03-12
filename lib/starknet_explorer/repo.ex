defmodule StarknetExplorer.Repo do
  adapter = Ecto.Adapters.Postgres

  use Ecto.Repo,
    otp_app: :starknet_explorer,
    adapter: adapter

  use Scrivener, page_size: 30
end
