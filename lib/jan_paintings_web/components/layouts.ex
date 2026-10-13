defmodule JanPaintingsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use JanPaintingsWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash} current_scope={@current_scope}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  attr :banner, :string,
    default: nil,
    doc: "category slug whose print detail is shown in the header art strip"

  slot :inner_block, required: true

  def app(assigns) do
    assigns = assign(assigns, :categories, JanPaintings.Catalog.categories())

    ~H"""
    <div class="flex min-h-screen flex-col">
      <header>
        <div class="relative bg-primary text-primary-content">
          <%!-- Only the art is clipped, so the mobile menu can drop below the header. --%>
          <div class="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
            <div
              class="banner-art absolute inset-y-0 right-0 max-w-[65%] sm:max-w-[60%]"
              style={"background-image: url('#{JanPaintings.Catalog.banner_url(@banner)}')"}
            />
          </div>
          <div class="relative mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-4 sm:px-6 sm:py-5 lg:px-8">
            <.link navigate={~p"/"} class="block min-w-0 shrink">
              <img
                src={~p"/images/jan-johnson-logo.png"}
                alt="Jan Johnson, Old Master & Modern Prints Inc."
                width="315"
                height="115"
                class="h-14 w-auto drop-shadow-[0_1px_2px_rgb(0_0_0_/_0.35)] sm:h-20 lg:h-24"
              />
            </.link>

            <details id="mobile-menu" class="group relative lg:hidden">
              <summary
                class="flex cursor-pointer list-none items-center rounded bg-primary/85 p-2 shadow hover:bg-primary [&::-webkit-details-marker]:hidden"
                aria-label="Menu"
              >
                <.icon name="hero-bars-3" class="size-6 group-open:hidden" />
                <.icon name="hero-x-mark" class="hidden size-6 group-open:block" />
              </summary>
              <nav class="absolute right-0 z-20 mt-2 flex w-56 flex-col rounded-box bg-base-100 p-2 text-base-content shadow-xl">
                <.link navigate={~p"/prints"} class="rounded px-3 py-2 hover:bg-base-200">
                  All Prints
                </.link>
                <.link
                  :for={c <- @categories}
                  navigate={~p"/prints/#{c.slug}"}
                  class="rounded px-3 py-2 hover:bg-base-200"
                >
                  {c.name}
                </.link>
                <.link navigate={~p"/about"} class="rounded px-3 py-2 hover:bg-base-200">About</.link>
                <.link href={~p"/about" <> "#contact"} class="rounded px-3 py-2 hover:bg-base-200">
                  Contact
                </.link>
                <div :if={@current_scope} class="mt-2 border-t border-base-300 pt-2">
                  <p class="truncate px-3 py-1 text-xs text-base-content/60">
                    {@current_scope.user.email}
                  </p>
                  <.link
                    :if={JanPaintings.Accounts.Scope.admin?(@current_scope)}
                    navigate={~p"/admin/prints"}
                    class="block rounded px-3 py-2 hover:bg-base-200"
                  >
                    Admin
                  </.link>
                  <.link href={~p"/users/settings"} class="block rounded px-3 py-2 hover:bg-base-200">
                    Account settings
                  </.link>
                  <.link
                    href={~p"/users/log-out"}
                    method="delete"
                    class="block rounded px-3 py-2 hover:bg-base-200"
                  >
                    Log out
                  </.link>
                </div>
                <div class="mt-2 border-t border-base-300 px-3 pt-3"><.theme_toggle /></div>
              </nav>
            </details>
          </div>
        </div>

        <div class="h-1 bg-secondary lg:h-auto">
          <nav class="mx-auto hidden max-w-6xl items-center gap-6 whitespace-nowrap px-8 py-2.5 text-sm uppercase tracking-wider text-secondary-content lg:flex xl:gap-7">
            <.link navigate={~p"/prints"} class="nav-link">All Prints</.link>
            <.link :for={c <- @categories} navigate={~p"/prints/#{c.slug}"} class="nav-link">
              {c.short}
            </.link>
            <.link navigate={~p"/about"} class="nav-link">About</.link>
            <.link href={~p"/about" <> "#contact"} class="nav-link">Contact</.link>
            <div class="ml-auto flex items-center gap-5">
              <.link
                :if={JanPaintings.Accounts.Scope.admin?(@current_scope)}
                navigate={~p"/admin/prints"}
                class="nav-link"
              >
                Admin
              </.link>
              <details :if={@current_scope} id="account-menu" class="relative">
                <summary
                  class="nav-link flex cursor-pointer list-none items-center gap-1 [&::-webkit-details-marker]:hidden"
                  title={@current_scope.user.email}
                >
                  <.icon name="hero-user-circle" class="size-5" />
                  <span class="sr-only">Account</span>
                  <.icon name="hero-chevron-down-micro" class="size-4" />
                </summary>
                <div class="absolute right-0 z-20 mt-3 w-64 rounded-box bg-base-100 p-2 text-sm normal-case tracking-normal text-base-content shadow-xl">
                  <p class="truncate px-3 py-1 text-xs text-base-content/60">
                    {@current_scope.user.email}
                  </p>
                  <.link href={~p"/users/settings"} class="block rounded px-3 py-2 hover:bg-base-200">
                    Account settings
                  </.link>
                  <.link
                    href={~p"/users/log-out"}
                    method="delete"
                    class="block rounded px-3 py-2 hover:bg-base-200"
                  >
                    Log out
                  </.link>
                </div>
              </details>
              <.theme_toggle />
            </div>
          </nav>
        </div>
      </header>

      <main class="flex-1 px-0 py-0 sm:px-4 sm:py-8 lg:py-12">
        <div class="paper-sheet mx-auto max-w-6xl px-4 py-10 sm:px-8 sm:py-12 lg:px-12">
          {render_slot(@inner_block)}
        </div>
      </main>

      <footer class="border-t-4 border-secondary bg-primary text-sm text-primary-content/80">
        <div class="mx-auto grid max-w-6xl gap-4 px-4 py-8 sm:grid-cols-2 sm:px-6 lg:px-8">
          <p>
            Jan Johnson, Old Master &amp; Modern Prints, Inc.<br />
            189 rue Saint-Pierre, Chambly, QC, Canada J3L 1L8
          </p>
          <p class="sm:text-right">
            <a href="mailto:jan@janjohnsonprints.com" class="nav-link">jan@janjohnsonprints.com</a>
            <br /> Phone <a href="tel:+14506582752" class="nav-link">450.658.2752</a>
            · Cell <a href="tel:+15146086959" class="nav-link">514.608.6959</a>
          </p>
          <p :if={!@current_scope} class="text-xs sm:col-span-2 sm:text-right">
            <.link navigate={~p"/users/log-in"} class="nav-link opacity-70">Log in</.link>
          </p>
        </div>
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
