class PlayerStat < ApplicationRecord
  belongs_to :user

  def total_matches
    wins + losses
  end
end
