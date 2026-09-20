require "rails_helper"

RSpec.describe PlayerCategory do
  let(:host_class) do
    Class.new do
      include PlayerCategory
    end
  end

  describe ".category_label" do
    it "returns 8va for the lowest category" do
      expect(host_class.category_label(8)).to eq("8va")
    end

    it "returns 1ra for the highest category" do
      expect(host_class.category_label(1)).to eq("1ra")
    end
  end
end
