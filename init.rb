# Include hook code here

config.to_prepare do
  CatalogController.helper(BlacklightRangeLimit::ViewHelperOverride)
  SearchHistoryController.helper(BlacklightRangeLimit::ViewHelperOverride)
  CatalogController.helper(RangeLimitHelper)
  CatalogController.send(:include, BlacklightRangeLimit::SolrHelperOverride)
end
