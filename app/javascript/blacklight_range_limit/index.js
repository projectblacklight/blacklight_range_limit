import BlacklightRangeLimit from 'range_limit_shared'
import 'range_limit_plotting'
import 'range_limit_distro_facets'
import 'range_limit_slider'

BlacklightRangeLimit.initialize = function() {
  // Support for Blacklight 7 and 8:
  const modalSelector = Blacklight.modal?.modalSelector || Blacklight.Modal.modalSelector 

  // RangeLimitDistroFacet.initialize(modalSelector)
  // RangeLimitSlider.initialize(modalSelector)
}

export default BlacklightRangeLimit