class PlayerStat < ApplicationRecord
  MAX_WIN_RATE = BigDecimal("100")

  belongs_to :user

  validates :wins, :losses, :current_streak, :best_streak,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :win_rate,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_WIN_RATE
            }

  def total_matches
    wins + losses
  end
end
