defmodule Mix.Tasks.JanPaintings.Admin do
  @shortdoc "Grants or revokes admin access for a user"

  @moduledoc """
  Grants admin access to a user, creating the account if needed.

      $ mix jan_paintings.admin jan@janjohnsonprints.com
      $ mix jan_paintings.admin jan@janjohnsonprints.com --revoke

  New accounts have no password: the user logs in from /users/log-in with a
  magic link sent to their email.
  """
  use Mix.Task

  alias JanPaintings.Accounts

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    case OptionParser.parse(args, strict: [revoke: :boolean]) do
      {opts, [email], []} -> update(email, !opts[:revoke])
      _ -> Mix.raise("Usage: mix jan_paintings.admin EMAIL [--revoke]")
    end
  end

  defp update(email, true) do
    case Accounts.grant_admin(email) do
      {:ok, user} -> Mix.shell().info("#{user.email} is now an admin.")
      {:error, changeset} -> Mix.raise("Could not grant admin: #{inspect(changeset.errors)}")
    end
  end

  defp update(email, false) do
    with %Accounts.User{} = user <- Accounts.get_user_by_email(email),
         {:ok, user} <- Accounts.set_admin(user, false) do
      Mix.shell().info("#{user.email} is no longer an admin.")
    else
      nil -> Mix.raise("No user with email #{email}.")
      {:error, changeset} -> Mix.raise("Could not revoke admin: #{inspect(changeset.errors)}")
    end
  end
end
