defmodule JanPaintingsWeb.SearchLiveTest do
  use JanPaintingsWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "print list" do
    test "filters as you type and keeps the URL in sync", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/prints")

      html = view |> form("#search-form", q: "neilson") |> render_change()

      assert html =~ "4 prints matching"
      assert html =~ "Dredging the St. Charles River"
      refute html =~ "Fiddler in an Inn"
      assert_patch(view, ~p"/prints?q=neilson")
    end

    test "clearing the box shows everything again", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/prints?q=neilson")

      view |> form("#search-form", q: "") |> render_change()

      assert_patch(view, ~p"/prints")
      assert render(view) =~ "180 prints shown"
    end

    test "the category pages have no search box", %{conn: conn} do
      for slug <- ~w(old-masters modern canadian) do
        {:ok, view, _html} = live(conn, ~p"/prints/#{slug}")
        refute has_element?(view, "#search-form")
      end

      {:ok, view, _html} = live(conn, ~p"/prints")
      assert has_element?(view, "#search-form")
    end
  end

  describe "home page search" do
    test "shows matching prints as you type", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, JanPaintingsWeb.SearchLive)

      html = view |> form("#home-search", q: "pissarro") |> render_change()

      assert html =~ "Quai de Paris"
      assert html =~ "See all 2 results"
      assert html =~ ~s(href="/prints?q=pissarro")
    end

    test "says so when nothing matches", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, JanPaintingsWeb.SearchLive)

      assert view |> form("#home-search", q: "zzzz") |> render_change() =~ "No prints match"
    end

    test "pressing enter opens the full results", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, JanPaintingsWeb.SearchLive)

      assert {:error, {:redirect, %{to: "/prints?q=tissot"}}} =
               view |> form("#home-search", q: "tissot") |> render_submit()
    end
  end
end
