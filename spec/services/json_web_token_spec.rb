require "rails_helper"

RSpec.describe JsonWebToken do
  describe ".decode" do
    it "returns the payload for a valid token" do
      token = described_class.encode(user_id: 7)

      expect(described_class.decode(token)[:user_id]).to eq(7)
    end

    it "raises InvalidToken when the token cannot be decoded" do
      expect { described_class.decode("not-a-token") }.to raise_error(described_class::InvalidToken)
    end

    it "raises ExpiredSignature when the token is expired" do
      token = described_class.encode({ user_id: 7 }, 1.minute.ago)

      expect { described_class.decode(token) }.to raise_error(described_class::ExpiredSignature)
    end
  end
end
