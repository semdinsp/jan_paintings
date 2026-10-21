defmodule JanPaintingsWeb.Admin.PrintLive.Index do
  @moduledoc """
  Admin list of all prints, with filters, a quick status change, and CSV
  download and import (see `JanPaintings.Catalog.CSV`).
  """
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
        <div class="flex flex-wrap gap-2">
          <.link navigate={~p"/admin/guides"} class="btn btn-ghost">
            <.icon name="hero-book-open" class="size-4" /> Guides
          </.link>
          <.link navigate={~p"/admin/mailing-list"} class="btn btn-ghost">
            <.icon name="hero-envelope" class="size-4" /> Mailing list
          </.link>
          <.link href={~p"/admin/prints/export.csv"} class="btn btn-ghost" download>
            <.icon name="hero-arrow-down-tray" class="size-4" /> Download CSV
          </.link>
          <.link navigate={~p"/admin/prints/new"} class="btn btn-primary">
            <.icon name="hero-plus" class="size-4" /> Add a print
          </.link>
        </div>
      </div>

      <form
        id="csv-import"
        phx-change="validate_csv"
        phx-submit="import_csv"
        class="mt-6 flex flex-wrap items-center gap-3 rounded-box border border-base-300 p-4 text-sm"
      >
        <label class="font-medium" for={@uploads.csv.ref}>Add prints from a CSV</label>
        <.live_file_input upload={@uploads.csv} class="file-input file-input-sm max-w-xs" />
        <button
          type="submit"
          class="btn btn-sm btn-primary"
          disabled={@uploads.csv.entries == []}
          phx-disable-with="Importing…"
        >
          Import
        </button>
        <p class="basis-full text-xs text-base-content/60">
          Use the columns of the downloaded CSV. Rows whose slug is already in the catalogue are
          skipped, so you can add rows to a download and upload it. A row with no image is added
          as a draft, hidden from the site until you add its image and change its status. Images
          given must already be on the site (an /images/… or /uploads/… path). If any row has a
          problem, nothing is added.
        </p>
        <p :for={err <- upload_errors(@uploads.csv)} class="basis-full text-error">
          {upload_error_message(err)}
        </p>
      </form>

      <div
        :if={@import_problems != []}
        id="csv-import-problems"
        class="alert alert-error mt-4 block text-sm"
      >
        <p class="font-medium">Nothing was imported. Fix these rows and upload again:</p>
        <ul class="mt-2 list-disc pl-5">
          <li :for={{row, message} <- @import_problems}>
            {if row > 0, do: "Row #{row}: "}{message}
          </li>
        </ul>
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
          class="grid grid-cols-[3.5rem_1fr_auto] items-center gap-x-3 gap-y-2 py-3 sm:grid-cols-[3.5rem_1fr_9rem_8rem_auto] sm:gap-x-4"
        >
          <.link navigate={~p"/admin/prints/#{print.id}/edit"} class="mat block size-14 p-1">
            <img
              :if={print.image != ""}
              src={Catalog.image_url(print.image)}
              alt=""
              loading="lazy"
              class="size-full object-contain"
            />
          </.link>
          <div class="col-span-2 min-w-0 sm:col-span-1">
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
            class="w-32 sm:w-auto"
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
          <div class="col-span-2 col-start-2 flex gap-4 text-sm sm:col-span-1 sm:col-start-auto">
            <.link navigate={~p"/admin/prints/#{print.id}/edit"} class="text-accent hover:underline">
              Edit
            </.link>
            <.link
              :if={print.status != "draft"}
              href={~p"/prints/#{print.category}/#{print.slug}"}
              target="_blank"
              class="text-base-content/60 hover:underline"
            >
              View
            </.link>
            <span :if={print.status == "draft"} class="text-base-content/60">Not on the site</span>
          </div>
        </li>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Admin · Prints",
       categories: Catalog.categories(),
       import_problems: []
     )
     |> allow_upload(:csv, accept: ~w(.csv), max_entries: 1, max_file_size: 5_000_000)}
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

  def handle_event("validate_csv", _params, socket), do: {:noreply, socket}

  def handle_event("import_csv", _params, socket) do
    results =
      consume_uploaded_entries(socket, :csv, fn %{path: path}, _entry ->
        {:ok, path |> File.read!() |> Catalog.CSV.import()}
      end)

    case results do
      [] ->
        {:noreply, socket}

      [{:ok, %{created: created, skipped: skipped}}] ->
        {:noreply,
         socket
         |> assign(import_problems: [])
         |> put_flash(:info, import_summary(length(created), length(skipped)))
         |> load_prints()}

      [{:error, problems}] ->
        {:noreply, socket |> clear_flash() |> assign(import_problems: problems)}
    end
  end

  def handle_event("set_status", %{"print_id" => id, "status" => status}, socket) do
    print = Catalog.get_print!(id)

    case Catalog.set_status(print, status) do
      {:ok, print} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{print.title} is now #{print.status}.")
         |> load_prints()}

      {:error, changeset} ->
        message =
          if Keyword.has_key?(changeset.errors, :image),
            do: "#{print.title} needs an image before it can go on the site.",
            else: "Could not change the status."

        {:noreply, socket |> put_flash(:error, message) |> load_prints()}
    end
  end

  defp load_prints(socket) do
    %{filters: filters} = socket.assigns
    all = Catalog.list_all_prints()

    prints =
      all
      |> filter_by(:category, filters["category"])
      |> filter_by(:status, filters["status"])
      |> Catalog.search(filters["q"])

    assign(socket, prints: prints, total: length(all))
  end

  defp import_summary(created, skipped) do
    added = "Added #{created} #{if created == 1, do: "print", else: "prints"}."

    if skipped == 0,
      do: added,
      else: "#{added} Skipped #{skipped} already in the catalogue."
  end

  defp upload_error_message(:not_accepted), do: "Choose a .csv file."
  defp upload_error_message(:too_large), do: "That file is too large (5 MB at most)."
  defp upload_error_message(:too_many_files), do: "Choose one file."
  defp upload_error_message(_), do: "That file could not be uploaded."

  defp filter_by(prints, _field, value) when value in [nil, ""], do: prints
  defp filter_by(prints, field, value), do: Enum.filter(prints, &(Map.get(&1, field) == value))

  defp category_short(categories, slug) do
    Enum.find_value(categories, slug, &(&1.slug == slug && &1.short))
  end

  defp status_class("sold"), do: "select-primary"
  defp status_class("reserved"), do: "select-secondary"
  defp status_class("draft"), do: "select-warning"
  defp status_class(_), do: nil
end
