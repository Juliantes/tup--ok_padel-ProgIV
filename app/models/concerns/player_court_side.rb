module PlayerCourtSide
  extend ActiveSupport::Concern

  LABELS = {
    "derecha" => "Derecha",
    "reves" => "Revés"
  }.freeze

  class_methods do
    def court_side_options_for_select
      court_sides.keys.map { |value| [ LABELS[value], value ] }
    end
  end

  def court_side_label
    return nil if court_side.blank?

    LABELS[court_side]
  end
end
