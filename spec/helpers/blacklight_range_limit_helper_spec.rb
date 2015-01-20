require "spec_helper"

describe "Blacklight Range Limit Helper" do

  it "should render range text fields with/without labels" do 
    expect(helper.render_range_input('pub_date', 'begin')).to match /^<input type=\"text\" class=\"form-control range_begin\" id=\"range_pub_date_begin\" maxlength=\"4\"/
    expect(helper.render_range_input('pub_date', 'begin', 'from pub date')).to match /^<label class=\"sr-only\" for=\"range_pub_date_begin\">from pub date<\/label>/
  end

end
