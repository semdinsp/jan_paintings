defmodule JanPaintingsWeb.EmailHTML do
  @moduledoc """
  HTML for emails, styled like the website: oxblood header with the logo, a
  cream sheet on the sage page colour, and serif type.

  Email clients ignore stylesheets and web fonts, so everything is inline
  and laid out with tables, and Georgia stands in for the site's fonts.
  """
  use Phoenix.Component

  @primary "#643440"
  @page "#b2baa6"
  @paper "#fcfaf6"
  @ink "#241e1c"
  @muted "#6b6461"
  @rule "#d4dacc"
  @serif "Georgia, 'Times New Roman', Times, serif"

  @doc """
  Renders an action email (a heading, some paragraphs and one button) to an
  HTML string.

    * `:heading` - the large heading.
    * `:paragraphs` - plain-text paragraphs shown above the button.
    * `:button` - `{label, url}` for the call to action.
    * `:footnote` - small print below the button, such as "ignore this if...".
  """
  def action_email(assigns) do
    assigns
    |> Map.new()
    |> Map.put_new(:footnote, nil)
    |> layout_with_action()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp layout_with_action(assigns) do
    assigns =
      Map.merge(assigns, %{
        logo_url: JanPaintingsWeb.Endpoint.url() <> "/images/jan-johnson-logo.png",
        site_url: JanPaintingsWeb.Endpoint.url(),
        primary: @primary,
        page: @page,
        paper: @paper,
        ink: @ink,
        muted: @muted,
        rule: @rule,
        serif: @serif
      })

    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="color-scheme" content="light" />
        <title>{@heading}</title>
      </head>
      <body style={"margin:0;padding:0;background-color:#{@page};"}>
        <table
          role="presentation"
          width="100%"
          cellpadding="0"
          cellspacing="0"
          border="0"
          style={"background-color:#{@page};"}
        >
          <tr>
            <td align="center" style="padding:24px 12px;">
              <table
                role="presentation"
                width="100%"
                cellpadding="0"
                cellspacing="0"
                border="0"
                style="max-width:560px;"
              >
                <tr>
                  <td style={"background-color:#{@primary};padding:20px 28px;"}>
                    <a href={@site_url} style="text-decoration:none;">
                      <img
                        src={@logo_url}
                        width="158"
                        height="58"
                        alt="Jan Johnson, Old Master &amp; Modern Prints Inc."
                        style={"display:block;border:0;color:#ffffff;font-family:#{@serif};font-size:20px;"}
                      />
                    </a>
                  </td>
                </tr>
                <tr>
                  <td style={"background-color:#{@paper};padding:32px 28px;font-family:#{@serif};color:#{@ink};"}>
                    <h1 style={"margin:0 0 16px;font-family:#{@serif};font-size:26px;line-height:1.25;font-weight:normal;color:#{@ink};"}>
                      {@heading}
                    </h1>
                    <p
                      :for={paragraph <- @paragraphs}
                      style="margin:0 0 16px;font-size:16px;line-height:1.6;"
                    >
                      {paragraph}
                    </p>
                    <table
                      role="presentation"
                      cellpadding="0"
                      cellspacing="0"
                      border="0"
                      style="margin:24px 0;"
                    >
                      <tr>
                        <td style={"background-color:#{@primary};border-radius:4px;"}>
                          <a
                            href={elem(@button, 1)}
                            style={"display:inline-block;padding:12px 24px;font-family:#{@serif};font-size:16px;font-weight:bold;color:#ffffff;text-decoration:none;"}
                          >
                            {elem(@button, 0)}
                          </a>
                        </td>
                      </tr>
                    </table>
                    <p style={"margin:0 0 8px;font-size:13px;line-height:1.5;color:#{@muted};"}>
                      If the button doesn't work, copy this link into your browser:
                    </p>
                    <p style="margin:0 0 16px;font-size:13px;line-height:1.5;word-break:break-all;">
                      <a href={elem(@button, 1)} style={"color:#{@primary};"}>{elem(@button, 1)}</a>
                    </p>
                    <p
                      :if={@footnote}
                      style={"margin:24px 0 0;padding-top:16px;border-top:1px solid #{@rule};font-size:13px;line-height:1.5;color:#{@muted};"}
                    >
                      {@footnote}
                    </p>
                  </td>
                </tr>
                <tr>
                  <td style={"background-color:#{@primary};padding:18px 28px;font-family:#{@serif};font-size:12px;line-height:1.6;color:#e9dfe1;"}>
                    Jan Johnson, Old Master &amp; Modern Prints, Inc.<br />
                    189 rue Saint-Pierre, Chambly, QC, Canada J3L 1L8<br />
                    <a href="mailto:jan@janjohnsonprints.com" style="color:#ffffff;">jan@janjohnsonprints.com</a><br />
                    Phone 450.658.2752 · Cell 514.608.6959
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end
end
