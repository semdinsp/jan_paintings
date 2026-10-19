defmodule JanPaintingsWeb.Admin.PrintLiveTest do
  use JanPaintingsWeb.ConnCase

  import Phoenix.LiveViewTest
  import JanPaintings.AccountsFixtures

  alias JanPaintings.{Accounts, Catalog}

  # A real 1x1 JPEG, so uploads behave like a photo from the gallery.
  @jpeg Base.decode64!(
          "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="
        )

  defp log_in_admin(%{conn: conn}) do
    {:ok, admin} = Accounts.set_admin(user_fixture(), true)
    %{conn: log_in_user(conn, admin), admin: admin}
  end

  defp upload(view, name, filename) do
    file_input(view, "#print-form", name, [
      %{name: filename, content: @jpeg, type: "image/jpeg"}
    ])
  end

  describe "access" do
    test "sends visitors to the log in page", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/admin/prints")
    end

    test "turns away users who are not admins", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/prints")
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/prints/new")
    end

    test "only admins can download the CSV", %{conn: conn} do
      assert conn |> get(~p"/admin/prints/export.csv") |> redirected_to() == ~p"/users/log-in"

      conn = log_in_user(conn, user_fixture())
      assert conn |> get(~p"/admin/prints/export.csv") |> redirected_to() == ~p"/"
    end

    test "shows the Admin link only to admins", %{conn: conn} do
      html = conn |> log_in_user(user_fixture()) |> get(~p"/") |> html_response(200)
      refute html =~ ~s(href="/admin/prints")

      {:ok, admin} = Accounts.set_admin(user_fixture(), true)
      html = conn |> log_in_user(admin) |> get(~p"/") |> html_response(200)
      assert html =~ ~s(href="/admin/prints")
    end
  end

  describe "csv" do
    setup :log_in_admin

    defp csv_upload(view, content) do
      file_input(view, "#csv-import", :csv, [
        %{name: "prints.csv", content: content, type: "text/csv"}
      ])
    end

    test "downloads every print as CSV", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/prints")
      assert html =~ ~s(href="/admin/prints/export.csv")
      assert html =~ ~s(href="/admin/guides")

      conn = get(conn, ~p"/admin/prints/export.csv")
      assert response_content_type(conn, :csv) =~ "text/csv"
      assert [disposition] = get_resp_header(conn, "content-disposition")
      assert disposition =~ ~r/attachment; filename="jan-johnson-prints-\d{4}-\d{2}-\d{2}.csv"/

      [header | rows] =
        conn |> response(200) |> Catalog.CSV.Parser.parse_string(skip_headers: false)

      assert header == Catalog.CSV.columns()
      assert length(rows) == 180
    end

    test "adds the new prints in an uploaded CSV", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/prints")

      csv =
        "slug,category,artist,title,image\r\n" <>
          "neilson-dredging-the-st-charles-river,canadian,X,Y,/images/x.jpg\r\n" <>
          "\"\",modern,\"DOE, Jane\",A New Etching,/images/catalogue/beham-nude-650.jpg\r\n"

      render_upload(csv_upload(view, csv), "prints.csv")
      html = view |> form("#csv-import") |> render_submit()

      assert html =~ "Added 1 print. Skipped 1 already in the catalogue."
      assert html =~ "181 of 181 prints"
      assert Catalog.get_print("doe-a-new-etching").artist == "DOE, Jane"
    end

    test "lists the problem rows and adds nothing", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/prints")

      csv =
        "category,artist,title,image\r\nmodern,\"DOE, Jane\",,/images/catalogue/beham-nude-650.jpg\r\n"

      render_upload(csv_upload(view, csv), "prints.csv")
      html = view |> form("#csv-import") |> render_submit()

      assert html =~ "Nothing was imported"
      assert html =~ "Row 2: title can&#39;t be blank"
      assert html =~ "180 of 180 prints"
    end

    test "adds rows without an image as drafts", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/prints")
      csv = "category,artist,title\r\nmodern,\"DOE, Jane\",Coming Soon\r\n"

      render_upload(csv_upload(view, csv), "prints.csv")
      assert view |> form("#csv-import") |> render_submit() =~ "Added 1 print."

      draft = Catalog.get_print("doe-coming-soon")
      assert {draft.status, draft.image} == {"draft", ""}
    end

    test "refuses files that are not CSV", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/prints")

      upload =
        file_input(view, "#csv-import", :csv, [
          %{name: "prints.xlsx", content: "x", type: "application/vnd.ms-excel"}
        ])

      assert {:error, [[_ref, :not_accepted]]} = render_upload(upload, "prints.xlsx")
    end
  end

  describe "list" do
    setup :log_in_admin

    test "lists every print and filters them", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/prints")
      assert html =~ "180 of 180 prints"

      html = view |> form("#admin-print-filters", %{"category" => "canadian"}) |> render_change()
      assert_patch(view, ~p"/admin/prints?category=canadian")
      assert html =~ "37 of 180 prints"

      {:ok, _view, html} = live(conn, ~p"/admin/prints?status=sold")
      assert html =~ "7 of 180 prints"

      {:ok, _view, html} = live(conn, ~p"/admin/prints?q=neilson")
      assert html =~ "4 of 180 prints"
    end

    test "marks a print sold from the list", %{conn: conn} do
      print = Catalog.get_print("neilson-dredging-the-st-charles-river")
      {:ok, view, _html} = live(conn, ~p"/admin/prints")

      html =
        view
        |> element("#status-#{print.id}")
        |> render_change(%{"print_id" => print.id, "status" => "sold"})

      assert html =~ "is now sold"
      assert Catalog.get_print(print.slug).status == "sold"

      public = conn |> get(~p"/prints/canadian/#{print.slug}") |> html_response(200)
      assert public =~ "Sold"
    end

    test "lists drafts, and asks for an image before one goes on the site", %{conn: conn} do
      {:ok, draft} =
        Catalog.create_print(%{
          "category" => "modern",
          "artist" => "DOE, Jane",
          "title" => "Work in Progress",
          "status" => "draft"
        })

      {:ok, view, html} = live(conn, ~p"/admin/prints?status=draft")
      assert html =~ "Work in Progress"
      assert html =~ "1 of 181 prints"
      assert has_element?(view, "#admin-print-#{draft.id}", "Not on the site")
      refute has_element?(view, "#admin-print-#{draft.id} a", "View")

      html =
        view
        |> element("#status-#{draft.id}")
        |> render_change(%{"print_id" => draft.id, "status" => "available"})

      assert html =~ "Work in Progress needs an image before it can go on the site."
      assert Catalog.get_print(draft.slug).status == "draft"

      {:ok, _view, html} = live(conn, ~p"/admin/prints/#{draft.id}/edit")
      assert html =~ "Draft: not on the site"
      refute html =~ "View on the site"
    end
  end

  describe "add" do
    setup :log_in_admin

    test "creates a print with uploaded images", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/prints/new")

      assert render_submit(view, "save", %{"print" => %{"artist" => ""}}) =~ "can&#39;t be blank"

      image = upload(view, :image, "Neige dorée.JPG")
      assert render_upload(image, "Neige dorée.JPG") =~ "Neige dorée.JPG"
      gallery = upload(view, :gallery, "verso.jpg")
      render_upload(gallery, "verso.jpg")

      view
      |> form("#print-form",
        print: %{
          category: "canadian",
          artist: "LEDUC, Ozias",
          title: "Neige dorée",
          price: "$900 CAD",
          status: "available"
        }
      )
      |> render_submit()

      assert_redirect(view, ~p"/admin/prints")

      print = Catalog.get_print("leduc-neige-doree")
      assert print.price == "$900 CAD"
      assert "/uploads/prints/neige-doree-" <> _ = print.image
      assert print.thumb == print.image
      assert [gallery_path] = print.gallery

      assert File.exists?(
               Path.join(JanPaintings.Uploads.dir(), String.trim_leading(print.image, "/uploads"))
             )

      # The uploaded file is served at its path.
      assert conn |> get(print.image) |> response(200) == @jpeg
      assert conn |> get(gallery_path) |> response(200) == @jpeg

      html = conn |> get(~p"/prints/canadian/leduc-neige-doree") |> html_response(200)
      assert html =~ "Neige dorée"
      assert html =~ print.image
    end

    test "keeps a print saved without an image as a draft", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/prints/new")
      assert html =~ "No image yet? Save anyway"

      fields = %{category: "canadian", artist: "LEDUC, Ozias", title: "Neige"}
      refute view |> form("#print-form", print: fields) |> render_change() =~ "add an image"

      {:ok, _view, html} =
        view |> form("#print-form", print: fields) |> render_submit() |> follow_redirect(conn)

      assert html =~ "Added Neige as a draft."
      assert %{status: "draft", image: ""} = Catalog.get_print("leduc-neige")
    end

    test "needs an image for a new print given another status", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/prints/new")

      html =
        view
        |> form("#print-form",
          print: %{category: "canadian", artist: "LEDUC, Ozias", title: "Neige", status: "sold"}
        )
        |> render_submit()

      assert html =~ "add an image, or save the print as a draft"
      refute Catalog.get_print("leduc-neige")
    end
  end

  describe "edit" do
    setup :log_in_admin

    setup do
      %{
        print:
          Catalog.get_print(
            "tissot-the-return-from-the-parable-of-the-prodigal-son-a-set-of-four-plus-title"
          )
      }
    end

    test "shows what the price and size sort as, and warns when unreadable",
         %{conn: conn, print: print} do
      {:ok, view, _html} = live(conn, ~p"/admin/prints/#{print.id}/edit")

      html = view |> form("#print-form", print: %{price: "The set $4,000 USD"}) |> render_change()
      assert html =~ "Sorts as 4,000 USD."

      html = view |> form("#print-form", print: %{dimensions: "260 x356mm"}) |> render_change()
      assert html =~ "Sorts as 260 × 356 mm (926 cm²)."

      html = view |> form("#print-form", print: %{price: "", dimensions: ""}) |> render_change()
      assert html =~ "No price: listed last when sorting by price."
      assert html =~ "No size: listed last when sorting by size."

      html =
        view
        |> form("#print-form", print: %{price: "Ask", dimensions: "Folio"})
        |> render_change()

      assert html =~ "No amount found"
      assert html =~ "No size found"
    end

    test "updates the description and keeps the images", %{conn: conn, print: print} do
      {:ok, view, html} = live(conn, ~p"/admin/prints/#{print.id}/edit")
      assert html =~ print.title

      view
      |> form("#print-form",
        print: %{
          price: "$4,000 USD",
          condition: "Fine.",
          catalogue_references: "Béraldi XII, 50",
          state: "First state",
          sheet_size: "400 × 500mm",
          nationality: "french",
          additional_notes: "A note on the print.",
          catalogue_details: "Etching, 1900.\nWatermark: Crowned shield"
        }
      )
      |> render_submit()

      assert_redirect(view, ~p"/admin/prints")
      updated = Catalog.get_print(print.slug)
      assert updated.price == "$4,000 USD"
      assert updated.condition == "Fine."
      assert updated.catalogue_references == "Béraldi XII, 50"
      assert updated.state == "First state"
      assert updated.sheet_size == "400 × 500mm"
      assert updated.nationality == "french"
      assert updated.additional_notes == "A note on the print."
      assert updated.catalogue_details == "Etching, 1900.\nWatermark: Crowned shield"
      assert updated.image == print.image
      assert updated.gallery == print.gallery
    end

    test "removes an extra view", %{conn: conn, print: print} do
      assert length(print.gallery) == 2
      {:ok, view, _html} = live(conn, ~p"/admin/prints/#{print.id}/edit")

      view
      |> element(~s(button[phx-click="remove_gallery"][phx-value-index="0"]))
      |> render_click()

      view |> form("#print-form") |> render_submit()

      assert Catalog.get_print(print.slug).gallery == tl(print.gallery)
    end

    test "removes the larger image", %{conn: conn} do
      print = Catalog.get_print("tiepolo-venice-receiving-neptunes-homage-after-g-b-tiepolo")
      assert print.large_image != ""
      {:ok, view, _html} = live(conn, ~p"/admin/prints/#{print.id}/edit")

      view |> element(~s(button[phx-click="remove_large_image"])) |> render_click()
      view |> form("#print-form") |> render_submit()

      updated = Catalog.get_print(print.slug)
      assert updated.large_image == ""
      assert updated.image == print.image
    end

    test "deletes the print", %{conn: conn, print: print} do
      {:ok, view, _html} = live(conn, ~p"/admin/prints/#{print.id}/edit")

      view |> element(~s(button[phx-click="delete"])) |> render_click()

      assert_redirect(view, ~p"/admin/prints")
      refute Catalog.get_print(print.slug)
    end
  end
end
