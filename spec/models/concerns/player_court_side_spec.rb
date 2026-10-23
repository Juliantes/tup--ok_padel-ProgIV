require "rails_helper"

RSpec.describe PlayerCourtSide do
  let(:host_class) do
    Class.new do
      include PlayerCourtSide

      def self.court_sides
        { "derecha" => 0, "reves" => 1 }
      end
    end
  end

  describe ".court_side_options_for_select" do
    it "returns labeled options for each side" do
      expect(host_class.court_side_options_for_select).to eq(
        [ [ "Derecha", "derecha" ], [ "Revés", "reves" ] ]
      )
    end
  end

  describe "#court_side_label" do
    it "returns the Spanish label for derecha" do
      user = build(:user, court_side: :derecha)

      expect(user.court_side_label).to eq("Derecha")
    end

    it "returns nil when court_side is unset" do
      user = build(:user, court_side: nil)

      expect(user.court_side_label).to be_nil
    end
  end
end
