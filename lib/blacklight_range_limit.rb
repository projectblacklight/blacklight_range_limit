# BlacklightRangeLimit

module BlacklightRangeLimit
  mattr_accessor :labels
  self.labels = {
    :missing => "Unknown"
  }

  
  @omit_inject = {}
  def self.omit_inject=(value)
    value = Hash.new(true) if value == true
    @omit_inject = value      
  end
  def self.omit_inject ; @omit_inject ; end
  
  def self.inject!
    Dispatcher.to_prepare do
      
      unless omit_inject[:view_helpers]
        CatalogController.helper(BlacklightRangeLimit::ViewHelperOverride)
        SearchHistoryController.helper(BlacklightRangeLimit::ViewHelperOverride)
        CatalogController.helper(RangeLimitHelper)
        SearchHistoryController.helper(RangeLimitHelper)
      end

      unless omit_inject[:controller_mixin]
        CatalogController.send(:include, BlacklightRangeLimit::ControllerOverride)
      end
      
      CatalogController.before_filter do |controller|
        
        unless omit_inject[:css]
          controller.stylesheet_links << ["blacklight_range_limit", {:plugin => "blacklight_range_limit"}]
        end

        unless omit_inject[:flot]          
          # Replace with local version. 
          controller.javascript_includes << "http://flot.googlecode.com/svn/trunk/jquery.flot.js"
          controller.javascript_includes << "http://flot.googlecode.com/svn/trunk/jquery.flot.selection.js"
          # canvas for IE
          controller.extra_head_content << '<!--[if IE]><script language="javascript" type="text/javascript" src="http://flot.googlecode.com/svn/trunk/excanvas.min.js"></script><![endif]-->'        
        end
        
        unless omit_inject[:js]
          controller.javascript_includes << ["range_limit_slider", {:plugin => "blacklight_range_limit"}]
          controller.javascript_includes << ["range_limit_distro_facets", {:plugin => "blacklight_range_limit"}]
        end
      
      end  
    end
  end

  
  
end
