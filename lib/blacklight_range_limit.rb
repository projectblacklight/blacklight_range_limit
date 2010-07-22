# BlacklightRangeLimit

module BlacklightRangeLimit
  mattr_accessor :labels
  self.labels = {
    :missing => "Unknown"
  }

  def self.inject!
    Dispatcher.to_prepare do
      CatalogController.helper(BlacklightRangeLimit::ViewHelperOverride)
      SearchHistoryController.helper(BlacklightRangeLimit::ViewHelperOverride)
      CatalogController.helper(RangeLimitHelper)
      SearchHistoryController.helper(RangeLimitHelper)
      
      CatalogController.send(:include, BlacklightRangeLimit::ControllerOverride)
      
      CatalogController.before_filter do |controller| 
        controller.stylesheet_links << ["blacklight_range_limit", {:plugin => "blacklight_range_limit"}]
      
        controller.javascript_includes << ["range_limit_slider", {:plugin => "blacklight_range_limit"}]
        controller.javascript_includes << ["range_limit_distro_facets", {:plugin => "blacklight_range_limit"}]
      
        # Replace with local version. 
        controller.javascript_includes << "http://flot.googlecode.com/svn/trunk/jquery.flot.js"
        controller.javascript_includes << "http://flot.googlecode.com/svn/trunk/jquery.flot.selection.js"
        # canvas for IE
        controller.extra_head_content << '<!--[if IE]><script language="javascript" type="text/javascript" src="http://flot.googlecode.com/svn/trunk/excanvas.min.js"></script><![endif]-->'
      
      end  
    end
  end

  
  
end
