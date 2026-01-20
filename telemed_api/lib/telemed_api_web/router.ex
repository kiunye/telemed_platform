defmodule TelemedApiWeb.Router do
  use TelemedApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug TelemedApiWeb.Plugs.CorrelationId
  end

  pipeline :authenticate do
    plug TelemedApiWeb.Plugs.Authenticate
  end

  scope "/api/v1", TelemedApiWeb do
    pipe_through :api

    # Public auth endpoints
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh

    # Protected endpoints (require authentication)
    scope "/" do
      pipe_through [:authenticate]

      get "/auth/me", AuthController, :me
      post "/auth/logout", AuthController, :logout

      # Appointments
      get "/appointments/availability", AppointmentsController, :search_availability
      get "/appointments", AppointmentsController, :index
      post "/appointments", AppointmentsController, :create
      get "/appointments/:id", AppointmentsController, :show
      patch "/appointments/:id/reschedule", AppointmentsController, :reschedule
      post "/appointments/:id/cancel", AppointmentsController, :cancel
    end
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:telemed_api, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
