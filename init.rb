# Include hook code here

config.to_prepare do
  CatalogController.helper(BlacklightRangeLimit::ViewHelperOverride)
  SearchHistoryController.helper(BlacklightRangeLimit::ViewHelperOverride)
  CatalogController.helper(RangeLimitHelper)
  CatalogController.send(:include, BlacklightRangeLimit::SolrHelperOverride)

  CatalogController.before_filter do |controller| 
    controller.stylesheet_links << ["blacklight_range_limit", {:plugin => "blacklight_range_limit"}]
  end
end
