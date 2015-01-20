require "spec_helper"

describe "Blacklight Range Limit Helper" do

  it "should render range text fields with/without labels" do
    begin_html = Capybara.string(helper.render_range_input('pub_date', 'begin'))
    begin_from_pub_html = Capybara.string(helper.render_range_input('pub_date', 'begin', 'from pub date'))
    expect(begin_html).to have_css 'input.form-control.range_begin#range_pub_date_begin'
    expect(begin_from_pub_html).to have_css 'label.sr-only[for="range_pub_date_begin"]'
  end

end
