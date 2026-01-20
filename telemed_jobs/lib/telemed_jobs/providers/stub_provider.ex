defmodule TelemedJobs.Providers.StubProvider do
  @moduledoc """
  Stub notification provider for development and testing.

  Logs notifications instead of actually sending them.
  """
  @behaviour TelemedJobs.Providers.NotificationProvider

  require Logger

  @impl true
  def send_sms(phone_number, message, _opts) do
    Logger.info("📱 [STUB SMS] To: #{phone_number}, Message: #{message}")
    delivery_id = "stub_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"
    {:ok, delivery_id}
  end

  @impl true
  def send_email(to, subject, body, _opts) do
    Logger.info("📧 [STUB EMAIL] To: #{to}, Subject: #{subject}")
    Logger.debug("Email body: #{body}")
    delivery_id = "stub_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"
    {:ok, delivery_id}
  end
end
