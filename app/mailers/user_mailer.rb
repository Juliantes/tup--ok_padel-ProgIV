# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user

    I18n.with_locale(:es) do
      mail(
        to: user.email,
        subject: I18n.t("mailers.user_mailer.welcome.subject", name: user.name)
      )
    end
  end
end
