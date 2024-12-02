require 'spec_helper'

describe CatalogController, type: :request do
  let(:range_facet_field) { "pub_date_si" }

  let(:parsed_body) { Nokogiri::HTML(response.body) }

  describe "bad params should not produce uncaught exception when" do
    it "bad root range" do
      get "/catalog?range=bad"

      expect(response.code).to eq("200")
      expect(parsed_body.css("span.applied-filter")).not_to be_present
    end

    it "facet params are ill structured" do
      get "/catalog?#{  {"f" => { range_facet_field => [{"=Library&q="=>""}] } }.to_param  }"

      expect(response.code).to eq("200")
      expect(parsed_body.css("span.applied-filter")).not_to be_present
    end

    it "newline in range facet does not interupt facet" do
      get "/catalog?#{ {"range"=>{ range_facet_field => {"begin"=>"1588\n", "end"=>"2020\n"}}}.to_param }"

      expect(response.code).to eq("200")
      expect(parsed_body.css("span.applied-filter")).to be_present
      expect(parsed_body.css("span.applied-filter").collect(&:text)).to include(/1588.*to.*2020/)
    end

    it "weird attack in range value is ignored" do
      param_hash = {"range"=>{"year_facet_isim"=>{"begin"=>"1989',(;))#- --", "end"=>"1989',(;))#- --"}}}
      get "/catalog?#{ param_hash.to_param  }"

      expect(response.code).to eq("200")
      expect(parsed_body.css("span.applied-filter")).not_to be_present
    end

    it "empty range param is ignored" do
      get "/catalog?#{ { "range" => { "year_facet_isim" => nil } }.to_param }"

      expect(response.code).to eq("200")
      expect(parsed_body.css("span.applied-filter")).not_to be_present
    end

    describe "out of bounds range config" do
      let(:max) { BlacklightRangeLimit.default_range_config[:range_config][:max_value] }
      let(:min) { BlacklightRangeLimit.default_range_config[:range_config][:min_value] }

      let(:too_high) { max.abs * 2 }
      let(:too_low) { min.abs * -2 }

      it "does not error" do
        get "/catalog?#{ {"range"=>{ range_facet_field => {"begin"=> too_low, "end"=> too_high }}}.to_param }"

        expect(response.code).to eq("200")
        expect(parsed_body.css("span.applied-filter")).to be_present
      end
    end
  end
end
