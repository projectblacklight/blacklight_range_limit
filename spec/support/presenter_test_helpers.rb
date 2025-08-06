# frozen_string_literal: true

module PresenterTestHelpers
  def controller
    # view_component 3+ should be just `vc_test_controller_class` when we drop VC 2 support we can
    # just use that.
    @controller ||= (respond_to?(:vc_test_controller_class) ? vc_test_controller_class : ApplicationController).new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers)
  end

  def request
    @request ||= ActionDispatch::TestRequest.create
  end
end
