defmodule JanPaintingsWeb.EmailHTML do
  @moduledoc """
  HTML for emails, styled like the website (see design.md): the ink logo on
  warm paper, hairline rules, a warm-grey footer, and rose only for links
  and the button.

  Email clients ignore stylesheets and web fonts, so everything is inline
  and laid out with tables. Georgia stands in for EB Garamond in headings,
  and Helvetica/Arial for Source Sans 3 in the text.
  """
  use Phoenix.Component

  @primary "#a8436a"
  @page "#f1ede6"
  @paper "#faf8f4"
  @ink "#1f1d1a"
  @muted "#5c5650"
  @rule "#ddd6cb"
  @serif "Georgia, 'Times New Roman', Times, serif"
  @sans "'Helvetica Neue', Helvetica, Arial, sans-serif"

  @colors %{primary: @primary, ink: @ink, muted: @muted, rule: @rule, serif: @serif, sans: @sans}

  @doc """
  Renders an action email (a heading, some paragraphs and one button) to an
  HTML string.

    * `:heading` - the large heading.
    * `:paragraphs` - plain-text paragraphs shown above the button.
    * `:button` - `{label, url}` for the call to action.
    * `:footnote` - small print below the button, such as "ignore this if...".
  """
  def action_email(content) do
    content
    |> Map.new()
    |> Map.put_new(:footnote, nil)
    |> Map.merge(@colors)
    |> action_body()
    |> to_html()
  end

  @doc """
  Renders a message email (a heading, a table of details, a quoted message
  and a reply button) to an HTML string. Used for contact form enquiries.

    * `:heading` - the large heading.
    * `:intro` - a line above the details.
    * `:details` - `{label, value}` rows; rows with a nil or blank value are
      left out. A value may be `{text, url}` to show a link.
    * `:message` - the sender's message; line breaks are kept.
    * `:button` - `{label, url}`, usually a mailto: reply link.
  """
  def message_email(content) do
    content
    |> Map.new()
    |> Map.update!(:details, fn rows -> Enum.reject(rows, &blank?(elem(&1, 1))) end)
    |> Map.merge(@colors)
    |> message_body()
    |> to_html()
  end

  defp blank?(value), do: value in [nil, ""]

  # The sender's message as paragraphs (split on blank lines) of lines.
  defp message_paragraphs(message) do
    message
    |> String.split(~r/\R\s*\R/u, trim: true)
    |> Enum.map(&String.split(String.trim(&1), ~r/\R/u))
  end

  defp to_html(rendered) do
    rendered |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp action_body(assigns) do
    ~H"""
    <.shell heading={@heading}>
      <p :for={paragraph <- @paragraphs} style="margin:0 0 16px;font-size:16px;line-height:1.6;">
        {paragraph}
      </p>
      <.email_button label={elem(@button, 0)} url={elem(@button, 1)} />
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
    </.shell>
    """
  end

  defp message_body(assigns) do
    ~H"""
    <.shell heading={@heading}>
      <p style="margin:0 0 20px;font-size:16px;line-height:1.6;">{@intro}</p>
      <table
        role="presentation"
        width="100%"
        cellpadding="0"
        cellspacing="0"
        border="0"
        style={"border-top:1px solid #{@rule};"}
      >
        <tr :for={{label, value} <- @details}>
          <td
            valign="top"
            width="90"
            style={"padding:10px 12px 10px 0;border-bottom:1px solid #{@rule};font-family:#{@sans};font-size:11px;font-weight:bold;letter-spacing:1.5px;text-transform:uppercase;color:#{@muted};"}
          >
            {label}
          </td>
          <td
            valign="top"
            style={"padding:8px 0;border-bottom:1px solid #{@rule};font-family:#{@sans};font-size:15px;line-height:1.5;color:#{@ink};"}
          >
            <%= case value do %>
              <% {text, url} -> %>
                <a href={url} style={"color:#{@primary};"}>{text}</a>
              <% text -> %>
                {text}
            <% end %>
          </td>
        </tr>
      </table>
      <p style={"margin:24px 0 8px;font-size:11px;font-weight:bold;letter-spacing:1.5px;text-transform:uppercase;color:#{@muted};"}>
        Message
      </p>
      <div style={"margin:0;padding:4px 0 4px 16px;border-left:3px solid #{@rule};"}>
        <p
          :for={lines <- message_paragraphs(@message)}
          style="margin:0 0 12px;font-size:16px;line-height:1.6;"
        >
          <%= for {line, index} <- Enum.with_index(lines) do %>
            <br :if={index > 0} />{line}
          <% end %>
        </p>
      </div>
      <.email_button label={elem(@button, 0)} url={elem(@button, 1)} />
    </.shell>
    """
  end

  attr :label, :string, required: true
  attr :url, :string, required: true

  defp email_button(assigns) do
    assigns = Map.merge(assigns, @colors)

    ~H"""
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:24px 0;">
      <tr>
        <td style={"background-color:#{@primary};border-radius:2px;"}>
          <a
            href={@url}
            style={"display:inline-block;padding:12px 20px;font-family:#{@sans};font-size:15px;font-weight:bold;color:#ffffff;text-decoration:none;"}
          >
            {@label}
          </a>
        </td>
      </tr>
    </table>
    """
  end

  attr :heading, :string, required: true
  slot :inner_block, required: true

  defp shell(assigns) do
    assigns =
      Map.merge(assigns, %{
        logo_url: JanPaintingsWeb.Endpoint.url() <> "/images/jan-johnson-logo-ink.png",
        site_url: JanPaintingsWeb.Endpoint.url(),
        primary: @primary,
        page: @page,
        paper: @paper,
        ink: @ink,
        rule: @rule,
        serif: @serif,
        sans: @sans
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
                  <td style={"background-color:#{@paper};padding:20px 28px;border-bottom:1px solid #{@ink};"}>
                    <a href={@site_url} style="text-decoration:none;">
                      <img
                        src={@logo_url}
                        width="158"
                        height="60"
                        alt="Jan Johnson, Old Master &amp; Modern Prints Inc."
                        style={"display:block;border:0;color:#{@ink};font-family:#{@serif};font-size:20px;"}
                      />
                    </a>
                  </td>
                </tr>
                <tr>
                  <td style={"background-color:#{@paper};padding:32px 28px;font-family:#{@sans};color:#{@ink};"}>
                    <h1 style={"margin:0 0 16px;font-family:#{@serif};font-size:26px;line-height:1.25;font-weight:normal;color:#{@ink};"}>
                      {@heading}
                    </h1>
                    {render_slot(@inner_block)}
                  </td>
                </tr>
                <tr>
                  <td style={"background-color:#{@page};padding:18px 28px;border-top:1px solid #{@rule};font-family:#{@sans};font-size:13px;line-height:1.6;color:#{@ink};"}>
                    Jan Johnson, Old Master &amp; Modern Prints, Inc.<br />
                    189 rue Saint-Pierre, Chambly, QC, Canada J3L 1L8<br />
                    <a href="mailto:jan@janjohnsonprints.com" style={"color:#{@primary};"}>jan@janjohnsonprints.com</a><br />
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
