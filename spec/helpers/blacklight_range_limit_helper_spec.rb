require "spec_helper"

describe "Blacklight Range Limit Helper" do

  it "should render range text fields with/without labels" do
    begin_html = Capybara.string(helper.render_range_input('pub_date', 'begin'))
    begin_from_pub_html = Capybara.string(helper.render_range_input('pub_date', 'begin', 'from pub date'))
    expect(begin_html).to have_css 'input.form-control.range_begin#range_pub_date_begin'
    expect(begin_from_pub_html).to have_css 'label.sr-only[for="range_pub_date_begin"]'
  end

  it "should render range text fields with specified maxlength, defaulting to 4 if not specified" do
    html_maxlength_default = Capybara.string(helper.render_range_input('pub_date', 'begin'))
    html_maxlength_6 = Capybara.string(helper.render_range_input('pub_date', 'begin', nil, 6))
    expect(html_maxlength_default).to have_css 'input.form-control.range_begin#range_pub_date_begin[maxlength="4"]'
    expect(html_maxlength_6).to have_css 'input.form-control.range_begin#range_pub_date_begin[maxlength="6"]'
  end

end
