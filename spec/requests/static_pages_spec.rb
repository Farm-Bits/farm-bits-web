require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET /home" do
    it "returns a successful response" do
      get home_path
      expect(response).to be_successful
    end
  end

  describe "GET /privacy_policy" do
    it "returns a successful response" do
      get privacy_policy_path
      expect(response).to be_successful
    end
  end
end
