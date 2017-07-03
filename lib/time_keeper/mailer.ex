defmodule TimeKeeper.Mailer do
  @moduledoc """
    Base mailer. Adds Bamboo mailer for sending emails.
  """

  use Bamboo.Mailer, otp_app: :time_keeper
end
