# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#welcome" do
    let(:user) do
      build_stubbed(:user, name: "María Padel", email: "maria@example.com", self_level: 5)
    end

    let(:mail) { described_class.welcome(user) }

    it "sets the subject from i18n" do
      expect(mail.subject).to eq("¡Bienvenido a Ok Padel, María Padel!")
    end

    it "sends to the user email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets from and reply_to" do
      expect(mail.from).to eq(["no-reply@okpadel.local"])
      expect(mail.reply_to).to eq(["soporte@okpadel.local"])
    end

    it "includes the user name in the body" do
      expect(mail.html_part.body.decoded).to include("María Padel")
      expect(mail.text_part.body.decoded).to include("María Padel")
    end

    it "includes the user category in the body" do
      category = user.category_label
      expect(mail.html_part.body.decoded).to include(category)
      expect(mail.text_part.body.decoded).to include(category)
    end

    it "includes the root URL in the body" do
      root = root_url(host: "example.com")
      expect(mail.html_part.body.decoded).to include(root)
      expect(mail.text_part.body.decoded).to include(root)
    end

    it "renders HTML and text parts" do
      expect(mail.html_part).to be_present
      expect(mail.text_part).to be_present
    end
  end
end
