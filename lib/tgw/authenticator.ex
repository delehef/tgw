defmodule Tgw.Rpc.Authenticator do
  require Logger
  def init(_), do: []

  def decode_token(headers) do
    with {:has_token, bearer_str} when not is_nil(bearer_str) <-
           {:has_token, Map.get(headers, "authorization")},
         token_str <- Enum.at(String.split(bearer_str, " "), 1),
         {:decode_token, {:ok, token_json}} <-
           {:decode_token, Base.decode64(token_str, padding: false, ignore: :whitespace)},
         {:ok, token} <- Jason.decode(token_json) do
      {:ok, token}
    else
      {:has_token, nil} ->
        Logger.error("authentication token not found")
        {:error, :token_not_found}

      {:decode_token, _} ->
        Logger.error("token is not valid base64")
        {:error, :token_invalide_base64}

      msg ->
        {:error, :token_failed_to_decode}
        Logger.error("failed to decode authentication info: #{msg}")
    end
  end

  def call(req, stream, next, _opts) do
    with headers when is_map(headers) <- GRPC.Stream.get_headers(stream),
         {:ok, token} <- decode_token(headers) do
      # TODO: actually validate
      next.(req, stream)
    else
      {:error, _} ->
        raise GRPC.RPCError, status: :permission_denied

      msg ->
        Logger.error("failed to decode authentication info: #{msg}")
        raise GRPC.RPCError, status: :permission_denied
    end
  end
end
