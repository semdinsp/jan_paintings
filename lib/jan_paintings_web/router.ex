defmodule JanPaintingsWeb.Router do
  use JanPaintingsWeb, :router

  import JanPaintingsWeb.UserAuth
  import CustomerContact.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JanPaintingsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    # Site-wide password while the site is private; delete this line to remove it.
    plug JanPaintingsWeb.Plugs.BasicAuth
  end

  # Crawler files (sitemap, robots, llms.txt): no session, same optional password.
  pipeline :crawler_files do
    plug JanPaintingsWeb.Plugs.BasicAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Campaign email links (open pixel, click redirect, unsubscribe) and the
  # Amazon SNS webhook. Outside every pipeline: no CSRF check (signed tokens
  # and AWS signatures authorize them) and no site password, so links in
  # emails work while the site is private.
  forward "/cc", CustomerContact.Web.PublicPlug

  scope "/", JanPaintingsWeb do
    pipe_through :crawler_files

    get "/sitemap.xml", SEOController, :sitemap
    get "/robots.txt", SEOController, :robots
    get "/llms.txt", SEOController, :llms
  end

  scope "/", JanPaintingsWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about
    post "/about", PageController, :create_message
    post "/mailing-list", PageController, :subscribe
    get "/terms-of-sale", PageController, :terms
    get "/contact", PageController, :contact_redirect

    live_session :public, on_mount: [{JanPaintingsWeb.UserAuth, :mount_current_scope}] do
      live "/prints", PrintLive.Index, :index
      live "/prints/:category", PrintLive.Index, :index
    end

    get "/prints/:category/:slug", PrintController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", JanPaintingsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:jan_paintings, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: JanPaintingsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Admin pages: only logged-in users with is_admin set. The plugs guard the
  # first page load; the :require_admin on_mount guards live navigation.
  scope "/admin", JanPaintingsWeb.Admin do
    pipe_through [:browser, :require_authenticated_user, :require_admin_user]

    get "/prints/export.csv", PrintCSVController, :export
    get "/mailing-list", SubscriberController, :index
    get "/mailing-list/export.csv", SubscriberController, :export
    delete "/mailing-list/:id", SubscriberController, :delete
    get "/guides", GuideController, :index
    get "/guides/adding-prints", GuideController, :adding
    get "/guides/editing-prints", GuideController, :editing

    live_session :admin, on_mount: [{JanPaintingsWeb.UserAuth, :require_admin}] do
      live "/prints", PrintLive.Index, :index
      live "/prints/new", PrintLive.Form, :new
      live "/prints/:id/edit", PrintLive.Form, :edit
    end
  end

  # Campaign email admin pages (CustomerContact). Its own scope, without the
  # JanPaintingsWeb.Admin alias; the same admin plugs and on_mount as above.
  scope "/admin" do
    pipe_through [:browser, :require_authenticated_user, :require_admin_user]

    customer_contact_admin "/contact",
      on_mount: [{JanPaintingsWeb.UserAuth, :require_admin}],
      home_path: "/admin/prints"
  end

  ## Authentication routes

  scope "/", JanPaintingsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{JanPaintingsWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", JanPaintingsWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{JanPaintingsWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
