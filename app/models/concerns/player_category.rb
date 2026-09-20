module PlayerCategory
  extend ActiveSupport::Concern

  # 8 = 8va (peor), 1 = 1ra (mejor)
  MIN = 1
  MAX = 8
  RANGE = (MIN..MAX).freeze

  LABELS = {
    8 => "8va",
    7 => "7ma",
    6 => "6ta",
    5 => "5ta",
    4 => "4ta",
    3 => "3ra",
    2 => "2da",
    1 => "1ra"
  }.freeze

  class_methods do
    def category_label(value)
      LABELS[value.to_i]
    end

    def category_options_for_select
      LABELS.map { |value, label| [ label, value ] }
    end
  end
end
