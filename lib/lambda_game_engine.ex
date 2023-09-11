defmodule LambdaGameEngine do
  @moduledoc """
  Documentation for `LambdaGameEngine`.
  """

  use Rustler, otp_app: :lambda_game_engine, crate: :lambda_game_engine

  ## Utility functions that are meant ONLY for local development
  if Mix.env() == :dev do
    def local_config(path \\ "priv/config.json") do
      {:ok, config} = File.read(path)
      parse_config(config)
    end
  end

  # When loading a NIF module, dummy clauses for all NIF function are required.
  # NIF dummies usually just error out when called when the NIF is not loaded, as that should never normally happen.
  @spec parse_config(binary()) :: map()
  def parse_config(_data), do: :erlang.nif_error(:nif_not_loaded)
end
