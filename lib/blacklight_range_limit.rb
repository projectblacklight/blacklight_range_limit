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
        CatalogController.add_template_helper(
          BlacklightRangeLimit::ViewHelperOverride
        ) unless
         CatalogController.master_helper_module.include?( 
            BlacklightRangeLimit::ViewHelperOverride
         )
        
        SearchHistoryController.add_template_helper(
          BlacklightRangeLimit::ViewHelperOverride
        ) unless
          SearchHistoryController.master_helper_module.include?( 
            BlacklightRangeLimit::ViewHelperOverride
          )
          
        CatalogController.add_template_helper(
          RangeLimitHelper
         ) unless
          CatalogController.master_helper_module.include?( 
            RangeLimitHelper
          )
         
        SearchHistoryController.add_template_helper(
          RangeLimitHelper
        ) unless
          SearchHistoryController.master_helper_module.include?( 
            RangeLimitHelper
          )
      end

      unless omit_inject[:controller_mixin]
        CatalogController.send(:include, BlacklightRangeLimit::ControllerOverride) unless CatalogController.include?(BlacklightRangeLimit::ControllerOverride)
      end
      
      CatalogController.before_filter do |controller|
        
        unless omit_inject[:css]
          safe_arr_add(controller.stylesheet_links ,
            ["blacklight_range_limit", {:plugin => "blacklight_range_limit"}])
        end

        unless omit_inject[:flot]
          # Replace with local version. 
          safe_arr_add(controller.javascript_includes,
          ["flot/jquery.flot.js", {:plugin=>:blacklight_range_limit}])
          safe_arr_add(controller.javascript_includes,          
          ["flot/jquery.flot.selection.js", {:plugin=>:blacklight_range_limit}])
          # canvas for IE

          # Hacky hack to insert URL to plugin asset when we don't have
          # access to helper methods, bah, will break if you change plugin
          # defaults. We need Rails 3.0 please.           
          safe_arr_add(controller.extra_head_content, '<!--[if IE]><script type="text/javascript" src="' + "#{controller.relative_url_root}/plugin_assets/blacklight_range_limit/javascripts/flot/excanvas.min.js?foo" + '"></script><![endif]-->')
          #safe_arr_add(controller.extra_head_content, '<!--[if IE]><script language="javascript" type="text/javascript" src="https://flot.googlecode.com/svn/trunk/excanvas.min.js"></script><![endif]-->')
          
        end
        
        unless omit_inject[:js]
          safe_arr_add(controller.javascript_includes,
                  ["range_limit_slider", {:plugin => "blacklight_range_limit"}])
          safe_arr_add(controller.javascript_includes ,
            ["range_limit_distro_facets", {:plugin => "blacklight_range_limit"}])
        end
      
      end  
    end
  end

  # Add element to array only if it's not already there
  def self.safe_arr_add(array, element)
    array << element unless array.include?(element)
  end
  
end
