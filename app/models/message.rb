class Message < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User", optional: true
  belongs_to :match, optional: true

  validates :content, presence: true
  validates :receiver, presence: true, unless: :is_group_chat?
  validates :match, presence: true, if: :is_group_chat?
end
