require "rails_helper"

RSpec.describe TnwCommon::SimpleSearchHelper, type: :helper do
  describe "#date_filter" do
    it "returns correct filter when end_date nil" do
      expect(helper.date_filter(start_date: "1340", end_date: nil)).to eq("entry_date_facet_ssim:[1340 TO *]")
    end
  end
end
