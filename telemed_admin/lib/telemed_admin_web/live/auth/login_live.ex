defmodule TelemedAdminWeb.Auth.LoginLive do
  @moduledoc """
  Login page for admin and doctor portals.
  """
  use TelemedAdminWeb, :live_view

  alias TelemedCore.Accounts.Impl.AuthService
  import Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, email: "", password: "", error: nil)}
  end

  @impl true
  def handle_event("login", %{"email" => email, "password" => password}, socket) do
    case AuthService.login(email, password, []) do
      {:ok, user, _access_token, _refresh_token, _session} ->
        # Only allow admin and doctor roles to access admin portal
        if user.role in [:admin, :doctor] do
          {:noreply,
           socket
           |> put_flash(:info, "Logged in successfully")
           |> Phoenix.LiveView.put_session(:user_id, user.id)
           |> redirect(to: "/dashboard")}
        else
          {:noreply,
           assign(socket, error: "Access denied. Admin or doctor role required.")}
        end

      {:error, :user_not_found} ->
        {:noreply, assign(socket, error: "Invalid email or password")}

      {:error, :invalid_password} ->
        {:noreply, assign(socket, error: "Invalid email or password")}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Login failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-neutral-50">
      <div class="max-w-md w-full space-y-8 p-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-semibold text-neutral-900">
            Sign in to your account
          </h2>
        </div>
        <form phx-submit="login" class="mt-8 space-y-6">
          <div class="rounded-md shadow-sm space-y-4">
            <div>
              <label for="email" class="sr-only">Email address</label>
              <input
                id="email"
                name="email"
                type="email"
                required
                class="appearance-none rounded-md relative block w-full px-3 py-2 border border-neutral-300 placeholder-neutral-500 text-neutral-900 focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                placeholder="Email address"
                value={@email}
              />
            </div>
            <div>
              <label for="password" class="sr-only">Password</label>
              <input
                id="password"
                name="password"
                type="password"
                required
                class="appearance-none rounded-md relative block w-full px-3 py-2 border border-neutral-300 placeholder-neutral-500 text-neutral-900 focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                placeholder="Password"
              />
            </div>
          </div>

          <div :if={@error} class="rounded-md bg-error-50 p-4">
            <div class="text-sm text-error-800"><%= @error %></div>
          </div>

          <div>
            <button
              type="submit"
              class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-primary-500 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
            >
              Sign in
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
