defmodule TelemedJobs.Providers.NotificationProvider do
  @moduledoc """
  Behaviour for notification providers (SMS, Email).

  Implementations should handle delivery and return status.
  """
  @callback send_sms(phone_number :: String.t(), message :: String.t(), opts :: keyword()) ::
              {:ok, delivery_id :: String.t()} | {:error, reason :: atom()}

  @callback send_email(
              to :: String.t(),
              subject :: String.t(),
              body :: String.t(),
              opts :: keyword()
            ) ::
              {:ok, delivery_id :: String.t()} | {:error, reason :: atom()}
end
