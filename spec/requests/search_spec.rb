require 'rails_helper'

RSpec.describe "Searches", type: :request do
  describe "GET /simple" do
    it "returns http success" do
      get "/search/simple"
      expect(response).to have_http_status(:success)
    end
  end

end
