import BlacklightRangeLimit from 'range_limit_shared'
import 'range_limit_plotting'
import 'range_limit_distro_facets'
import 'range_limit_slider'

BlacklightRangeLimit.initialize = function(modalSelector) {
  BlacklightRangeLimit.initializeDistroFacets(modalSelector)
  BlacklightRangeLimit.initializeSlider(modalSelector)
}

export default BlacklightRangeLimit