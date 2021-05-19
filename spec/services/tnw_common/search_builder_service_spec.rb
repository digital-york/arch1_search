# frozen_string_literal: true

require "rails_helper"

RSpec.describe TnwCommon::SearchBuilderService do
  let(:query) {
    {
      q: "has_model_ssim:Entry AND suggest:(*Bishop* AND *Auckland*)",
      fq: "entry_date_facet_ssim:[* TO 1600]"
    }
  }
  let(:search_builder) {
    TnwCommon::SearchBuilderService.new(
      search_term: "Bishop Auckland",
      start_date: "",
      end_date: "1600",
      archival_repository: ""
    )
  }

  describe "#query" do
    it "with date filter" do
      expect(search_builder.query).to eq(query)
    end
  end
end
