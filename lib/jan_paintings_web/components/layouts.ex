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

  attr :active, :string,
    default: nil,
    doc: ~s(menu item for the current page: "prints", a category slug, or "about")

  slot :inner_block, required: true

  def app(assigns) do
    assigns =
      assign(assigns,
        menu:
          [{"prints", "All Prints", ~p"/prints"}] ++
            Enum.map(
              JanPaintings.Catalog.categories(),
              &{&1.slug, &1.name, ~p"/prints/#{&1.slug}"}
            ),
        about_menu: [{"about", "About Us", ~p"/about"}]
      )

    ~H"""
    <div class="flex min-h-screen flex-col">
      <header class="bg-dusk">
        <div class="mx-auto flex max-w-[1200px] items-center justify-between gap-4 px-4 py-5 md:px-6">
          <.link navigate={~p"/"} class="block shrink-0">
            <img
              src={~p"/images/jan-johnson-logo-ink.png"}
              alt="Jan Johnson, Old Master & Modern Prints Inc."
              width="512"
              height="193"
              class="h-16 w-auto sm:h-20 md:h-30 dark:invert"
            />
          </.link>
          <div class="ml-auto flex min-w-0 items-center gap-5 text-sm text-ink">
            <.link
              :if={JanPaintings.Accounts.Scope.admin?(@current_scope)}
              navigate={~p"/admin/prints"}
              class="hover:text-rose"
            >
              Admin
            </.link>
            <details :if={@current_scope} id="account-menu" class="relative">
              <summary
                class="flex min-h-11 cursor-pointer list-none items-center gap-1 hover:text-rose [&::-webkit-details-marker]:hidden"
                title={@current_scope.user.email}
              >
                <.icon name="hero-user-circle" class="size-5" />
                <span class="sr-only">Account</span>
                <.icon name="hero-chevron-down-micro" class="size-4" />
              </summary>
              <div class="absolute right-0 z-40 mt-1 w-64 border border-rule bg-paper p-2 text-ink">
                <p class="truncate px-3 py-1 text-xs text-ink-2">{@current_scope.user.email}</p>
                <.link href={~p"/users/settings"} class="block px-3 py-2 hover:text-rose">
                  Account settings
                </.link>
                <.link
                  href={~p"/users/log-out"}
                  method="delete"
                  class="block px-3 py-2 hover:text-rose"
                >
                  Log out
                </.link>
              </div>
            </details>
          </div>
          <img
            src={~p"/images/beham-triton.jpg"}
            alt="Ornament with a triton, engraving by Beham"
            width="798"
            height="275"
            class="h-16 w-auto min-w-0 object-contain object-right sm:h-20 md:h-30"
          />
        </div>
      </header>

      <div class="sticky top-0 z-30 bg-paper">
        <nav
          aria-label="Main"
          class="mx-auto max-w-[1200px] px-4 md:px-6"
        >
          <div class="hidden h-12 items-stretch gap-7 border-b-3 border-gold md:flex">
            <.link
              :for={{key, label, path} <- @menu}
              navigate={path}
              class="menu-item"
              aria-current={key == @active && "page"}
            >
              {label}
            </.link>
            <span class="flex-1" />
            <.menu_search id="menu-search" class="hidden w-60 self-center lg:block" />
            <%!-- No room for the box beside the menu items on tablets. --%>
            <.link
              navigate={~p"/prints"}
              class="flex items-center text-ink hover:text-rose lg:hidden"
              title="Search by artist or title"
            >
              <.icon name="hero-magnifying-glass" class="size-5" />
              <span class="sr-only">Search</span>
            </.link>
            <.link
              :for={{key, label, path} <- @about_menu}
              href={path}
              class="menu-item"
              aria-current={key == @active && "page"}
            >
              {label}
            </.link>
          </div>

          <details
            id="mobile-menu"
            class="group border-b-3 border-gold md:hidden"
          >
            <summary class="flex h-12 cursor-pointer list-none items-center gap-2 font-medium [&::-webkit-details-marker]:hidden">
              <.icon name="hero-bars-3" class="size-5 group-open:hidden" />
              <.icon name="hero-x-mark" class="hidden size-5 group-open:block" /> Menu
            </summary>
            <div class="pb-2">
              <.menu_search id="drawer-search" class="mb-2" />
              <.link
                :for={{key, label, path} <- @menu ++ @about_menu}
                href={path}
                class="drawer-item"
                aria-current={key == @active && "page"}
              >
                {label}
              </.link>
            </div>
          </details>
        </nav>
      </div>

      <main class="flex-1">
        <div class="mx-auto max-w-[1200px] px-4 py-12 md:px-6 md:py-16">
          {render_slot(@inner_block)}
        </div>
      </main>

      <footer class="bg-dusk py-12 text-[0.9375rem] text-ink [--rose:var(--ink)] [--rose-2:var(--ink)]">
        <div class="mx-auto grid max-w-[1200px] gap-6 px-4 md:grid-cols-2 md:px-6 lg:grid-cols-3">
          <p>
            Jan Johnson, Old Master &amp; Modern Prints, Inc.<br />
            189 rue Saint-Pierre, Chambly, QC, Canada J3L 1L8
          </p>
          <p>
            <a href="mailto:jan@janjohnsonprints.com" class="link">jan@janjohnsonprints.com</a>
            <br /> Phone <a href="tel:+14506582752" class="link">450.658.2752</a>
            · Cell <a href="tel:+15146086959" class="link">514.608.6959</a>
            <br /> <.link href={~p"/about" <> "#contact"} class="link">Contact us</.link>
          </p>
          <div class="flex items-start gap-5 md:col-span-2 lg:col-span-1 lg:justify-end">
            <.link
              :if={!@current_scope}
              navigate={~p"/users/log-in"}
              class="flex size-9 items-center justify-center text-ink hover:text-rose"
              title="Log in"
            >
              <.icon name="hero-arrow-right-end-on-rectangle" class="size-5" />
              <span class="sr-only">Log in</span>
            </.link>
            <.theme_toggle />
          </div>
        </div>
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Compact search box for the menu bar; Enter opens the matches on /prints.
  """
  attr :id, :string, required: true
  attr :class, :any, default: nil

  def menu_search(assigns) do
    ~H"""
    <form id={@id} action={~p"/prints"} method="get" role="search" class={@class}>
      <label class="input input-sm h-9 w-full pr-1">
        <span class="sr-only">Search by artist or title</span>
        <input
          id={"#{@id}-input"}
          type="search"
          name="q"
          placeholder="Artist or title"
          autocomplete="off"
          class="grow"
        />
        <button
          type="submit"
          class="flex size-7 cursor-pointer items-center justify-center text-ink-2 hover:text-rose"
        >
          <.icon name="hero-magnifying-glass" class="size-4" />
          <span class="sr-only">Search</span>
        </button>
      </label>
    </form>
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
