defmodule Gateway.Router do
  use Gateway, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/champions", Gateway.Champions do
    pipe_through :api
  end

  scope "/curse", Gateway.Controllers.CurseOfMirra do
    pipe_through :api

    scope "/users" do
      put "/:user_id/currency", CurrencyController, :modify_currency
      get "/:user_id/claim_daily_reward", UserController, :claim_daily_reward
      get "/:user_id/get_daily_reward_status", UserController, :get_daily_reward_status

      scope "/items" do
        put "/:user_id/:item_id/:unit_id/equip", ItemController, :equip
      end
    end
  end

  scope "/arena", Gateway.Controllers.Arena do
    pipe_through :api

    post "/match/:match_id", MatchResultsController, :create
  end

  scope "/", Gateway do
    pipe_through :api

    get "/auth/:provider/token/:token_id", Controllers.AuthController, :validate_token

    put "/users/:user_id", Controllers.UserController, :update
  end

  # Other scopes may use custom stacks.
  # scope "/api", Gateway do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:gateway, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Gateway.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
