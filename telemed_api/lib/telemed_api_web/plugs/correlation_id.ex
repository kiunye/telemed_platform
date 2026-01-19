defmodule TelemedApiWeb.Plugs.CorrelationId do
  @moduledoc """
  Plug to add request correlation IDs for tracing requests across services.

  Generates a unique ID for each request and adds it to the connection and logs.
  """
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    correlation_id = get_req_header(conn, "x-correlation-id")
    |> List.first()
    |> Kernel.||(generate_correlation_id())

    Logger.metadata(correlation_id: correlation_id)

    conn
    |> put_resp_header("x-correlation-id", correlation_id)
    |> assign(:correlation_id, correlation_id)
  end

  defp generate_correlation_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end
end
