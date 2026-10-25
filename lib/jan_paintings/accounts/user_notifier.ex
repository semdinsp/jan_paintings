defmodule JanPaintings.Accounts.UserNotifier do
  @moduledoc """
  Account emails: log in links, account confirmation and email changes.

  Each email has an HTML body styled like the website
  (`JanPaintingsWeb.EmailHTML`) and a plain-text body for clients that
  don't show HTML.
  """
  import Swoosh.Email

  require Logger

  alias JanPaintings.Mailer
  alias JanPaintings.Accounts.User
  alias JanPaintingsWeb.EmailHTML

  # Delivers the email using the application mailer, logging the result (the
  # recipient is left out of the log).
  defp deliver(recipient, subject, content) do
    email =
      new()
      |> to(recipient)
      |> from(Application.fetch_env!(:jan_paintings, __MODULE__)[:from])
      |> subject(subject)
      |> html_body(EmailHTML.action_email(content))
      |> text_body(text(content))

    case Mailer.deliver(email) do
      {:ok, metadata} ->
        Logger.info("Account email #{inspect(subject)} sent: #{inspect(metadata)}")
        {:ok, email}

      {:error, reason} = error ->
        Logger.error(
          "Account email #{inspect(subject)} from #{inspect(email.from)} failed: #{inspect(reason)}"
        )

        error
    end
  end

  defp text(%{heading: heading, paragraphs: paragraphs, button: {label, url}} = content) do
    footnote = if content[:footnote], do: ["\n", content.footnote, "\n"], else: []

    IO.iodata_to_binary([
      heading,
      "\n\n",
      Enum.map(paragraphs, &[&1, "\n\n"]),
      label,
      ":\n\n",
      url,
      "\n",
      footnote,
      "\n--\nJan Johnson, Old Master & Modern Prints, Inc.\n",
      "189 rue Saint-Pierre, Chambly, QC, Canada J3L 1L8\n",
      "jan@janjohnsonprints.com · Phone 450.658.2752 · Cell 514.608.6959\n"
    ])
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Confirm your new email address", %{
      heading: "Confirm your new email address",
      paragraphs: [
        "Hello,",
        "Someone asked to change the email address for your Jan Johnson Prints account to this one. Confirm the change with the button below."
      ],
      button: {"Confirm new email", url},
      footnote: "If you didn't ask for this change, you can ignore this email."
    })
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Your Jan Johnson Prints log in link", %{
      heading: "Log in to Jan Johnson Prints",
      paragraphs: [
        "Hello,",
        "Use the button below to log in as #{user.email}. The link works once and expires after a short time."
      ],
      button: {"Log in", url},
      footnote: "If you didn't ask to log in, you can ignore this email."
    })
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirm your Jan Johnson Prints account", %{
      heading: "Confirm your account",
      paragraphs: [
        "Hello,",
        "Thank you for creating an account with Jan Johnson Prints for #{user.email}. Confirm your email address to finish setting it up."
      ],
      button: {"Confirm my account", url},
      footnote: "If you didn't create an account, you can ignore this email."
    })
  end
end
