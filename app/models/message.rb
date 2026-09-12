class Message < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User", optional: true
  belongs_to :match, optional: true

  validates :content, presence: true
  validate :chat_recipients_present

  private

  def chat_recipients_present
    if is_group_chat?
      errors.add(:match, "must be present for group chats") if match.blank?
    elsif receiver.blank?
      errors.add(:receiver, "must be present for direct messages")
    end
  end
end
