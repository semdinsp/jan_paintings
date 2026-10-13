defmodule JanPaintingsWeb.Admin.PrintLive.Index do
  @moduledoc "Admin list of all prints, with filters and a quick status change."
  use JanPaintingsWeb, :live_view

  alias JanPaintings.Catalog
  alias JanPaintings.Catalog.Print

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex flex-wrap items-end justify-between gap-4 border-b border-base-300 pb-6">
        <div>
          <p class="text-xs uppercase tracking-[0.2em] text-base-content/60">Admin</p>
          <h1 class="mt-1 font-serif text-3xl">Prints</h1>
          <p class="mt-1 text-sm text-base-content/70">
            {length(@prints)} of {@total} prints
          </p>
        </div>
        <.link navigate={~p"/admin/prints/new"} class="btn btn-primary">
          <.icon name="hero-plus" class="size-4" /> Add a print
        </.link>
      </div>

      <.form
        for={@filter_form}
        id="admin-print-filters"
        phx-change="filter"
        phx-submit="filter"
        class="mt-6 grid gap-3 sm:grid-cols-[1fr_12rem_10rem]"
      >
        <.input
          field={@filter_form[:q]}
          type="search"
          placeholder="Search artist or title"
          phx-debounce="250"
          autocomplete="off"
        />
        <.input
          field={@filter_form[:category]}
          type="select"
          prompt="All categories"
          options={Enum.map(@categories, &{&1.name, &1.slug})}
        />
        <.input
          field={@filter_form[:status]}
          type="select"
          prompt="Any status"
          options={Enum.map(Print.statuses(), &{String.capitalize(&1), &1})}
        />
      </.form>

      <p :if={@prints == []} class="mt-10 text-center text-base-content/60">
        No prints match these filters.
      </p>

      <ul id="admin-prints" class="mt-4 divide-y divide-base-300">
        <li
          :for={print <- @prints}
          id={"admin-print-#{print.id}"}
          class="grid grid-cols-[3.5rem_1fr] items-center gap-x-4 gap-y-2 py-3 sm:grid-cols-[3.5rem_1fr_9rem_8rem_auto]"
        >
          <.link navigate={~p"/admin/prints/#{print.id}/edit"} class="print-mount block size-14 p-1">
            <img
              :if={print.image != ""}
              src={Catalog.image_url(print.image)}
              alt=""
              loading="lazy"
              class="size-full object-contain"
            />
          </.link>
          <div class="min-w-0">
            <.link
              navigate={~p"/admin/prints/#{print.id}/edit"}
              class="block truncate font-medium hover:text-accent"
            >
              {print.title}
            </.link>
            <p class="truncate text-xs uppercase tracking-wider text-base-content/60">
              {print.artist} · {category_short(@categories, print.category)}
            </p>
          </div>
          <p class="col-start-2 text-sm text-base-content/70 sm:col-start-auto">
            {if print.price == "", do: "On request", else: print.price}
          </p>
          <form
            id={"status-#{print.id}"}
            phx-change="set_status"
            class="col-start-2 sm:col-start-auto"
          >
            <input type="hidden" name="print_id" value={print.id} />
            <select
              name="status"
              aria-label={"Status of #{print.title}"}
              class={["select select-sm w-full", status_class(print.status)]}
            >
              {Phoenix.HTML.Form.options_for_select(
                Enum.map(Print.statuses(), &{String.capitalize(&1), &1}),
                print.status
              )}
            </select>
          </form>
          <div class="col-start-2 flex gap-3 text-sm sm:col-start-auto">
            <.link navigate={~p"/admin/prints/#{print.id}/edit"} class="text-accent hover:underline">
              Edit
            </.link>
            <.link
              href={~p"/prints/#{print.category}/#{print.slug}"}
              target="_blank"
              class="text-base-content/60 hover:underline"
            >
              View
            </.link>
          </div>
        </li>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Admin · Prints", categories: Catalog.categories())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = Map.take(params, ~w(q category status))
    {:noreply, socket |> assign(filters: filters, filter_form: to_form(filters)) |> load_prints()}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = params |> Map.take(~w(q category status)) |> Map.reject(fn {_k, v} -> v == "" end)
    {:noreply, push_patch(socket, to: ~p"/admin/prints?#{filters}", replace: true)}
  end

  def handle_event("set_status", %{"print_id" => id, "status" => status}, socket) do
    print = Catalog.get_print!(id)

    case Catalog.set_status(print, status) do
      {:ok, print} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{print.title} is now #{print.status}.")
         |> load_prints()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not change the status.")}
    end
  end

  defp load_prints(socket) do
    %{filters: filters} = socket.assigns
    all = Catalog.list_prints()

    prints =
      all
      |> filter_by(:category, filters["category"])
      |> filter_by(:status, filters["status"])
      |> Catalog.search(filters["q"])

    assign(socket, prints: prints, total: length(all))
  end

  defp filter_by(prints, _field, value) when value in [nil, ""], do: prints
  defp filter_by(prints, field, value), do: Enum.filter(prints, &(Map.get(&1, field) == value))

  defp category_short(categories, slug) do
    Enum.find_value(categories, slug, &(&1.slug == slug && &1.short))
  end

  defp status_class("sold"), do: "select-primary"
  defp status_class("reserved"), do: "select-secondary"
  defp status_class(_), do: nil
end
