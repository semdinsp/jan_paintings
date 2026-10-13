defmodule Mix.Tasks.JanPaintings.AdminTest do
  use JanPaintings.DataCase

  import JanPaintings.AccountsFixtures

  alias JanPaintings.Accounts
  alias Mix.Tasks.JanPaintings.Admin

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  end

  test "grants admin to a new email" do
    email = unique_user_email()
    Admin.run([email])

    assert_received {:mix_shell, :info, [message]}
    assert message =~ "is now an admin"
    assert Accounts.get_user_by_email(email).is_admin
  end

  test "revokes admin" do
    {:ok, user} = Accounts.grant_admin(unique_user_email())
    Admin.run([user.email, "--revoke"])

    assert_received {:mix_shell, :info, [message]}
    assert message =~ "no longer an admin"
    refute Accounts.get_user_by_email(user.email).is_admin
  end

  test "raises without an email" do
    assert_raise Mix.Error, ~r/Usage/, fn -> Admin.run([]) end
  end

  test "raises when revoking an unknown email" do
    assert_raise Mix.Error, ~r/No user/, fn -> Admin.run([unique_user_email(), "--revoke"]) end
  end
end
