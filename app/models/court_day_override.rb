# frozen_string_literal: true

class CourtDayOverride < ApplicationRecord
  belongs_to :court

  validates :date, presence: true
  validates :date, uniqueness: { scope: :court_id }
end
