require 'spec_helper'

RSpec.describe CatalogController,  type: :controller do
  # Note that ActionController::BadRequest is caught by rails and turned into a 400
  # response, and ActionController::RoutingError is caught by raisl and turned into 404
  describe "bad params" do
    let (:facet_field) { "pub_date_si" }

    it "without start param present raise BadRequest " do
      expect {
        get :range_limit, params: {
          "range_field"=> facet_field,
          "range_start"=>"1931"
        }
      }.to raise_error(ActionController::BadRequest)
    end

    it "without end param raise BadRequest " do
      expect {
        get :range_limit, params: {
          "range_field"=> facet_field,
          "range_start"=>"1931"
        }
      }.to raise_error(ActionController::BadRequest)
    end

    it "without either boundary raise BadRequest" do
      expect {
        get :range_limit, params: {
          "range_field"=> facet_field,
        }
      }.to raise_error(ActionController::BadRequest)
    end

    it "without a range_field raise RoutingError" do
      expect {
        get :range_limit, params: {}
      }.to raise_error(ActionController::RoutingError)
    end

    it "with params out of order raise BadRequest"  do
      expect {
        get :range_limit, params: {
          "range_field"=> facet_field,
          "range_start"=>"1940",
          "range_end"=>"1930"
        }
      }.to raise_error(ActionController::BadRequest)
    end

    it "with one of the params is an array raise BadRequest" do
      expect {
        get :range_limit, params: {
          "range_field"=> facet_field,
          "range_start"=>"1931",
          "range_end"=>["1940"]
        }
      }.to raise_error(ActionController::BadRequest)
    end
  end
end
