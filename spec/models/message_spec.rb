require "rails_helper"

RSpec.describe Message, type: :model do
  subject { build(:message) }

  describe "associations" do
    it { is_expected.to belong_to(:sender).class_name("User") }
    it { is_expected.to belong_to(:match).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe "recipients" do
    it "requires a receiver for direct messages" do
      message = build(:message, receiver: nil, is_group_chat: false)

      expect(message).not_to be_valid
      expect(message.errors[:receiver]).to include("can't be blank")
    end

    it "requires a match for group chats" do
      message = build(:message, match: nil, is_group_chat: true, receiver: nil)

      expect(message).not_to be_valid
      expect(message.errors[:match]).to include("can't be blank")
    end
  end
end
