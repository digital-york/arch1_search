require "rails_helper"

RSpec.describe TnwCommon::SimpleSearchHelper, type: :helper do
  describe "#date_filter set correct Solr filter when" do
    it "end_date is nil" do
      expect(helper.date_filter(start_date: "1340", end_date: nil)).to eq("entry_date_facet_ssim:[1340 TO *]")
    end
    it "both dates are nil" do
      expect(helper.date_filter(start_date: nil, end_date: nil)).to eq(nil)
    end
  end

  describe "#set_search_result_arrays returns correct" do
    # Assign instance variables
    before(:each) do
      assign(:search_term, "Bishop Auckland")
      assign(:page, 1)
      assign(:rows_per_page, 10)
      assign(:partial_list_array, [])
    end

    it "results with Date filter" do
      assign(:start_date, "1361")
      expect(helper.set_search_result_arrays).to eq(["bn999b195", "z603qx95j"])
    end

    it "number of Registres facets" do
      helper.set_search_result_arrays
      expect(helper.instance_variable_get(:@register_facet_hash).values.sum).to eq(8)
      expect(helper.instance_variable_get(:@register_facet_hash).keys).to eq(["Register 5A (1299-1555)", "Register 10 (1342-1352)", "Register 11 (1352-1373)", "Register 12 (1374-1388)"])
    end

    it "number of Date facets" do
      helper.set_search_result_arrays
      expect(helper.instance_variable_get(:@date_facet_hash).values.sum).to eq(7)
      expect(helper.instance_variable_get(:@date_facet_hash).keys).to eq(["1340", "1343", "1351", "1361", "1382"])
    end

    it "number of Section Type facets" do
      helper.set_search_result_arrays
      expect(helper.instance_variable_get(:@section_type_facet_hash).values.sum).to eq(8)
      expect(helper.instance_variable_get(:@section_type_facet_hash).keys).to eq(["Archdeaconry of Cleveland", "Archdeaconry of Nottingham", "Archdeaconry of York", "Archdeaconry of the East Riding", "Diverse letters"])
    end

    it "number of Subject facets" do
      helper.set_search_result_arrays
      expect(helper.instance_variable_get(:@subject_facet_hash).values.sum).to eq(1)
      expect(helper.instance_variable_get(:@subject_facet_hash).keys).to eq(["Exchanges"])
    end

    it "number of Place facets" do
      helper.set_search_result_arrays
      expect(helper.instance_variable_get(:@place_same_as_facet_hash).values.sum).to eq(21)
      expect(helper.instance_variable_get(:@place_same_as_facet_hash).keys[0]).to eq("Auckland St Andrew, Durham, England")
    end

    it "number of Person or Group facets" do
      helper.set_search_result_arrays
      expect(helper.instance_variable_get(:@person_same_as_facet_hash).values.sum).to eq(2)
      expect(helper.instance_variable_get(:@person_same_as_facet_hash).keys).to eq(["Fordham, John, d 1425, Bishop of Durham", "Neville, Master, Alexander, c 1332-1392, Archbishop of York"])
    end

    it "it highlights search term"
  end
end
