defmodule JanPaintingsWeb.PageControllerTest do
  use JanPaintingsWeb.ConnCase

  test "GET /", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)
    assert html =~ "Old Master Prints"
    assert html =~ "Canadian Prints"
  end

  test "the homepage has a tile for each category and none for All Prints or About", %{
    conn: conn
  } do
    html = conn |> get(~p"/") |> html_response(200)
    [tiles] = Regex.run(~r{<nav[^>]*aria-label="Browse the gallery".*?</nav>}s, html)

    hrefs = Regex.scan(~r{href="([^"]*)"}, tiles, capture: :all_but_first) |> List.flatten()
    assert hrefs == ["/prints/old-masters", "/prints/modern", "/prints/canadian"]
    refute html =~ "About the Gallery"
  end

  test "the menu bar has a home icon, marked current on the home page", %{conn: conn} do
    home = conn |> get(~p"/") |> html_response(200)
    about = conn |> get(~p"/about") |> html_response(200)

    home_links = fn html -> Regex.scan(~r{<a[^>]*href="/"[^>]*title="Home"[^>]*>}, html) end
    current? = fn [tag] -> tag =~ ~s(aria-current="page") end

    assert [_desktop, _phone] = home_links.(home)
    assert Enum.all?(home_links.(home), current?)
    assert [_, _] = home_links.(about)
    refute Enum.any?(home_links.(about), current?)
  end

  test "the menu bar has no All Prints link, but the page is still there", %{conn: conn} do
    for path <- [~p"/", ~p"/about", ~p"/prints"] do
      html = conn |> get(path) |> html_response(200)
      [nav] = Regex.run(~r{<nav[^>]*aria-label="Main".*?</nav>}s, html)
      refute nav =~ "All Prints"
      refute nav =~ "hero-squares-2x2"

      refute nav =~
               ~r{<a[^>]*class="drawer-item"[^>]*href="/prints"|<a[^>]*href="/prints"[^>]*class="drawer-item"}
    end

    assert conn |> get(~p"/prints") |> html_response(200) =~ "All Prints"
  end

  test "the menu bar has a search box that opens the matches on /prints", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    assert html =~ ~r{<form[^>]* id="menu-search" action="/prints" method="get"}
    assert html =~ ~s(id="menu-search-input")
    assert html =~ ~s(id="drawer-search-input")
  end

  test "GET /terms-of-sale, linked from the footer", %{conn: conn} do
    html = conn |> get(~p"/terms-of-sale") |> html_response(200)
    assert html =~ ~r/<h1[^>]*>Terms of Sale<\/h1>/

    for heading <- [
          "Authenticity",
          "Prints on approval",
          "Packing and shipping",
          "Payment",
          "Canadian clients"
        ] do
      assert html =~ ~r/<h2[^>]*>#{heading}<\/h2>/
    end

    assert html =~ "refund your payment in full"
    assert html =~ "credit cards during 2026"
    assert html =~ ~r{<link[^>]*rel="canonical"[^>]*href="[^"]*/terms-of-sale"}

    [footer] = Regex.run(~r{<footer.*?</footer>}s, html)
    assert footer =~ ~r{<a[^>]*href="/terms-of-sale"[^>]*>Terms of sale</a>}
  end

  test "the menu bar and phone drawer have Contact Us, going to the contact page", %{
    conn: conn
  } do
    for path <- [~p"/", ~p"/about", ~p"/prints/modern"] do
      html = conn |> get(path) |> html_response(200)
      [nav] = Regex.run(~r{<nav[^>]*aria-label="Main".*?</nav>}s, html)

      # Once in the desktop bar and once in the drawer, not current here.
      contact = Regex.scan(~r{<a[^>]*href="/contact"[^>]*>\s*Contact Us\s*</a>}, nav)
      assert length(contact) == 2
      refute Enum.any?(contact, fn [tag] -> tag =~ "aria-current" end)
    end

    # Marked current on the contact page itself.
    html = conn |> get(~p"/contact") |> html_response(200)
    [nav] = Regex.run(~r{<nav[^>]*aria-label="Main".*?</nav>}s, html)
    contact = Regex.scan(~r{<a[^>]*href="/contact"[^>]*>\s*Contact Us\s*</a>}, nav)
    assert Enum.all?(contact, fn [tag] -> tag =~ ~s(aria-current="page") end)
  end

  test "GET /about", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    assert html =~ "International Fine Print Dealers"
    assert html =~ "acting at auction for clients and performing appraisals"

    # The museum clients, in alphabetical order.
    [clients] = Regex.run(~r{<section[^>]*id="about-clients".*?</section>}s, html)
    names = Regex.scan(~r{<li[^>]*>\s*(.*?)\s*</li>}s, clients, capture: :all_but_first)
    assert length(names) == 43
    assert ["Agnes Etherington Art Centre" <> _] = hd(names)
    assert ["Zimmerli Art Museum" <> _] = List.last(names)
    assert clients =~ "British Museum"
    assert clients =~ "Some of the museums we have worked with:"

    # Only the first three show until the button opens the rest.
    assert clients =~ ~r/<ul[^>]*id="about-clients-list"[^>]*data-collapsed/
    assert length(Regex.scan(~r/<li class="client-more">/, clients)) == 40

    assert clients =~
             ~r/<button(?=[^>]*id="about-clients-toggle")(?=[^>]*aria-expanded="false")[^>]*>[\s\S]*?Show all 43 museums/

    assert html =~ ~r/<h1[^>]*>About Us<\/h1>/
    assert html =~ ~s(src="/images/jan-johnson.jpg")
    # Shown at every screen size, not only beside the text on wide screens.
    [figure_class] =
      Regex.run(~r/<figure[^>]*id="about-portrait"[^>]*class="([^"]*)"/, html,
        capture: :all_but_first
      )

    refute figure_class =~ ~r/(^|\s)hidden(\s|$)/
    assert html =~ ~r{property="og:image" content="[^"]*/images/jan-johnson.jpg"}
  end
end
