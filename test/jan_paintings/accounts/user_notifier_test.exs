defmodule JanPaintings.Accounts.UserNotifierTest do
  use JanPaintings.DataCase, async: true

  import JanPaintings.AccountsFixtures

  alias JanPaintings.Accounts.UserNotifier

  @url "http://localhost:4002/users/log-in/abc123"

  test "log in emails have a site-styled HTML body and a plain-text body" do
    user = user_fixture()
    {:ok, email} = UserNotifier.deliver_login_instructions(user, @url)

    assert email.subject == "Your Jan Johnson Prints log in link"
    assert email.html_body =~ "<!DOCTYPE html>"
    assert email.html_body =~ "Log in to Jan Johnson Prints"
    assert email.html_body =~ ~s(href="#{@url}")
    assert email.html_body =~ "/images/jan-johnson-logo-ink.png"
    assert email.html_body =~ "#8f5550"
    assert email.text_body =~ "Log in to Jan Johnson Prints"
    assert email.text_body =~ @url
    refute email.text_body =~ "<"
  end

  test "unconfirmed users get the confirmation email" do
    {:ok, email} = UserNotifier.deliver_login_instructions(unconfirmed_user_fixture(), @url)

    assert email.subject == "Confirm your Jan Johnson Prints account"
    assert email.html_body =~ "Confirm my account"
    assert email.text_body =~ @url
  end

  test "change of email instructions" do
    {:ok, email} = UserNotifier.deliver_update_email_instructions(user_fixture(), @url)

    assert email.subject == "Confirm your new email address"
    assert email.html_body =~ "Confirm new email"
    assert email.text_body =~ @url
  end

  test "escapes user-supplied text in the HTML body" do
    user = %JanPaintings.Accounts.User{
      email: "<b>x</b>@example.com",
      confirmed_at: DateTime.utc_now()
    }

    {:ok, email} = UserNotifier.deliver_login_instructions(user, @url)

    refute email.html_body =~ "<b>x</b>"
    assert email.html_body =~ "&lt;b&gt;x&lt;/b&gt;@example.com"
  end
end
