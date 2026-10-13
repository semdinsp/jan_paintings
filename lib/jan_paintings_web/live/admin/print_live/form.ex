defmodule JanPaintingsWeb.Admin.PrintLive.Form do
  @moduledoc "Admin form for adding, editing and deleting a print, with image uploads."
  use JanPaintingsWeb, :live_view

  alias JanPaintings.Catalog
  alias JanPaintings.Catalog.Print
  alias JanPaintings.Uploads

  @image_types ~w(.jpg .jpeg .png .webp)
  @max_file_size 20_000_000

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.link
        navigate={~p"/admin/prints"}
        class="text-sm uppercase tracking-widest text-base-content/60 hover:text-accent"
      >
        <span aria-hidden="true">&larr;</span> All prints
      </.link>

      <div class="mt-4 flex flex-wrap items-end justify-between gap-4 border-b border-base-300 pb-6">
        <h1 class="font-serif text-3xl">{@page_title}</h1>
        <.link
          :if={@print.id}
          href={~p"/prints/#{@print.category}/#{@print.slug}"}
          target="_blank"
          class="text-sm text-accent underline underline-offset-4"
        >
          View on the site <span aria-hidden="true">&nearr;</span>
        </.link>
      </div>

      <.form
        for={@form}
        id="print-form"
        phx-change="validate"
        phx-submit="save"
        class="mt-8 grid gap-10 lg:grid-cols-[1fr_20rem]"
      >
        <div class="space-y-2">
          <div class="grid gap-x-4 sm:grid-cols-2">
            <.input
              field={@form[:category]}
              type="select"
              label="Category"
              prompt="Choose a category"
              options={Enum.map(Catalog.categories(), &{&1.name, &1.slug})}
            />
            <.input
              field={@form[:status]}
              type="select"
              label="Status"
              options={Enum.map(Print.statuses(), &{String.capitalize(&1), &1})}
            />
          </div>
          <div class="grid gap-x-4 sm:grid-cols-[2fr_1fr]">
            <.input
              field={@form[:artist]}
              label="Artist"
              placeholder="SURNAME, Given names"
              phx-debounce="300"
            />
            <.input field={@form[:dates]} label="Dates" placeholder="1864–1955" />
          </div>
          <.input field={@form[:title]} type="textarea" label="Title" rows="2" phx-debounce="300" />
          <div class="grid gap-x-4 sm:grid-cols-2">
            <.input field={@form[:medium]} label="Medium" placeholder="Etching" />
            <.input field={@form[:price]} label="Price" placeholder="$1,500 USD (blank = On request)" />
          </div>
          <.input field={@form[:details]} type="textarea" label="Details" rows="3" />
          <.input
            field={@form[:catalogue_references]}
            type="textarea"
            label="Catalogue references"
            rows="2"
            placeholder="Bartsch 96; New Hollstein 12"
          />
          <.input field={@form[:state]} label="State" placeholder="Second state of three" />
          <div class="grid gap-x-4 sm:grid-cols-2">
            <.input
              field={@form[:dimensions]}
              label="Size (plate or image)"
              placeholder="206 × 160mm"
            />
            <.input field={@form[:sheet_size]} label="Sheet size" placeholder="If stated" />
          </div>
          <.input field={@form[:condition]} type="textarea" label="Condition" rows="3" />
          <.input field={@form[:provenance]} type="textarea" label="Provenance" rows="2" />
          <.input field={@form[:watermark]} label="Watermark" />
          <.input
            field={@form[:slug]}
            label="Web address"
            phx-debounce="300"
          />
          <p class="-mt-1 text-xs text-base-content/60">
            /prints/{@form[:category].value || "category"}/{@form[:slug].value || "…"}. Filled in
            from the artist and title if left blank. Changing it breaks old links.
          </p>
        </div>

        <%!-- Images come first on phones, where prints are often photographed and added. --%>
        <div class="order-first space-y-8 lg:order-none">
          <input type="hidden" name={@form[:image].name} value={@print.image} />
          <input type="hidden" name={@form[:large_image].name} value={@form[:large_image].value} />
          <.image_field
            label="Main image"
            upload={@uploads.image}
            current={@print.image}
            errors={@form[:image].errors}
          />
          <.image_field
            label="Larger image (optional)"
            upload={@uploads.large_image}
            current={@form[:large_image].value}
            remove="remove_large_image"
          />

          <section>
            <h2 class="text-sm font-semibold">Extra views</h2>
            <p class="text-xs text-base-content/60">Other sheets, states or details.</p>
            <div :if={@gallery != []} class="mt-3 grid grid-cols-3 gap-2">
              <div :for={{path, index} <- Enum.with_index(@gallery)} class="relative">
                <img
                  src={Catalog.image_url(path)}
                  alt=""
                  class="print-mount aspect-square w-full object-contain p-1"
                />
                <button
                  type="button"
                  phx-click="remove_gallery"
                  phx-value-index={index}
                  aria-label="Remove this view"
                  class="btn btn-circle btn-xs absolute -right-1 -top-1"
                >
                  <.icon name="hero-x-mark" class="size-3" />
                </button>
              </div>
            </div>
            <.upload_entries upload={@uploads.gallery} />
            <label class="btn btn-sm btn-ghost mt-3 border-base-300">
              <.icon name="hero-photo" class="size-4" /> Add views
              <.live_file_input upload={@uploads.gallery} class="hidden" />
            </label>
          </section>
        </div>

        <div class="paper-sheet sticky bottom-0 z-10 -mx-4 flex flex-wrap items-center gap-3 border-t border-base-300 px-4 py-3 sm:-mx-8 sm:px-8 lg:col-span-2 lg:-mx-12 lg:px-12">
          <.button phx-disable-with="Saving…" class="btn btn-primary">Save print</.button>
          <.link navigate={~p"/admin/prints"} class="btn btn-ghost">Cancel</.link>
          <button
            :if={@print.id}
            type="button"
            phx-click="delete"
            data-confirm={"Delete #{@print.title}? This cannot be undone."}
            class="btn btn-ghost ml-auto text-error"
          >
            <.icon name="hero-trash" class="size-4" /> Delete print
          </button>
        </div>
      </.form>
    </Layouts.app>
    """
  end

  attr :label, :string, required: true
  attr :upload, :any, required: true
  attr :current, :string, default: ""
  attr :errors, :list, default: []
  attr :remove, :string, default: nil

  defp image_field(assigns) do
    ~H"""
    <section phx-drop-target={@upload.ref}>
      <h2 class="text-sm font-semibold">{@label}</h2>
      <div
        :if={@current not in [nil, ""] and @upload.entries == []}
        class="relative mt-3"
      >
        <img
          src={Catalog.image_url(@current)}
          alt=""
          class="print-mount max-h-64 w-full object-contain p-2"
        />
        <button
          :if={@remove}
          type="button"
          phx-click={@remove}
          aria-label="Remove this image"
          class="btn btn-circle btn-xs absolute -right-1 -top-1"
        >
          <.icon name="hero-x-mark" class="size-3" />
        </button>
      </div>
      <.upload_entries upload={@upload} />
      <label class="btn btn-sm btn-ghost mt-3 border-base-300">
        <.icon name="hero-arrow-up-tray" class="size-4" />
        {if @current in [nil, ""], do: "Choose image", else: "Replace image"}
        <.live_file_input upload={@upload} class="hidden" />
      </label>
      <p class="mt-1 text-xs text-base-content/60">JPG, PNG or WebP, up to 20 MB.</p>
      <p :for={error <- @errors} class="mt-1 text-xs text-error">{translate_error(error)}</p>
    </section>
    """
  end

  attr :upload, :any, required: true

  defp upload_entries(assigns) do
    ~H"""
    <div :for={entry <- @upload.entries} class="mt-3 flex items-center gap-3">
      <.live_img_preview entry={entry} class="print-mount size-16 object-contain p-1" />
      <div class="min-w-0 flex-1 text-xs">
        <p class="truncate">{entry.client_name}</p>
        <progress class="progress progress-primary w-full" value={entry.progress} max="100" />
        <p :for={err <- upload_errors(@upload, entry)} class="mt-1 text-xs text-error">
          {upload_error(err)}
        </p>
      </div>
      <button
        type="button"
        phx-click="cancel_upload"
        phx-value-upload={@upload.name}
        phx-value-ref={entry.ref}
        aria-label="Cancel"
        class="btn btn-ghost btn-xs"
      >
        <.icon name="hero-x-mark" class="size-4" />
      </button>
    </div>
    <p :for={err <- upload_errors(@upload)} class="mt-1 text-xs text-error">{upload_error(err)}</p>
    """
  end

  defp upload_error(:too_large), do: "That file is larger than 20 MB."
  defp upload_error(:not_accepted), do: "Use a JPG, PNG or WebP image."
  defp upload_error(:too_many_files), do: "Too many files at once."
  defp upload_error(other), do: "Upload failed (#{other})."

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:image, accept: @image_types, max_entries: 1, max_file_size: @max_file_size)
     |> allow_upload(:large_image,
       accept: @image_types,
       max_entries: 1,
       max_file_size: @max_file_size
     )
     |> allow_upload(:gallery,
       accept: @image_types,
       max_entries: 12,
       max_file_size: @max_file_size
     )
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    print = %Print{}

    socket
    |> assign(page_title: "Add a print", print: print, gallery: [])
    |> assign_form(Catalog.change_print(print))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    print = Catalog.get_print!(id)

    socket
    |> assign(page_title: "Edit print", print: print, gallery: print.gallery)
    |> assign_form(Catalog.change_print(print))
  end

  @impl true
  def handle_event("validate", %{"print" => params}, socket) do
    changeset =
      socket.assigns.print
      |> Catalog.change_print(with_pending_image(params, socket))
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"print" => params}, socket) do
    params = params |> Map.put("gallery", socket.assigns.gallery) |> put_uploads(socket)
    save(socket, socket.assigns.live_action, params)
  end

  def handle_event("cancel_upload", %{"upload" => name, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, String.to_existing_atom(name), ref)}
  end

  def handle_event("remove_gallery", %{"index" => index}, socket) do
    {:noreply, update(socket, :gallery, &List.delete_at(&1, String.to_integer(index)))}
  end

  def handle_event("remove_large_image", _params, socket) do
    params = Map.put(socket.assigns.form.params, "large_image", "")
    {:noreply, assign_form(socket, Catalog.change_print(socket.assigns.print, params))}
  end

  def handle_event("delete", _params, socket) do
    {:ok, print} = Catalog.delete_print(socket.assigns.print)

    {:noreply,
     socket
     |> put_flash(:info, "Deleted #{print.title}.")
     |> push_navigate(to: ~p"/admin/prints")}
  end

  defp save(socket, :new, params) do
    case Catalog.create_print(params) do
      {:ok, print} -> saved(socket, print, "Added #{print.title}.")
      {:error, changeset} -> {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save(socket, :edit, params) do
    case Catalog.update_print(socket.assigns.print, params) do
      {:ok, print} -> saved(socket, print, "Saved #{print.title}.")
      {:error, changeset} -> {:noreply, assign_form(socket, changeset)}
    end
  end

  defp saved(socket, _print, message) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_navigate(to: ~p"/admin/prints")}
  end

  # While a new image is uploading the print has no image path yet; use a
  # placeholder so validation doesn't complain that the image is missing.
  defp with_pending_image(params, socket) do
    if socket.assigns.uploads.image.entries != [],
      do: Map.put(params, "image", "/uploads/pending"),
      else: params
  end

  defp put_uploads(params, socket) do
    params =
      case consume(socket, :image) do
        [path] -> Map.merge(params, %{"image" => path, "thumb" => path})
        [] -> params
      end

    params =
      case consume(socket, :large_image) do
        [path] -> Map.put(params, "large_image", path)
        [] -> params
      end

    Map.update!(params, "gallery", &(&1 ++ consume(socket, :gallery)))
  end

  defp consume(socket, name) do
    consume_uploaded_entries(socket, name, fn %{path: tmp_path}, entry ->
      {:ok, Uploads.store_print_image(tmp_path, entry.client_name)}
    end)
  end

  defp assign_form(socket, changeset), do: assign(socket, form: to_form(changeset))
end
