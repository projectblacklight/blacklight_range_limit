# Used for building the search for the range_limit route
# You may completely override this class in the host application if you want to customize the search behavior.
class RangeLimitSearchBuilder < SearchBuilder
  include BlacklightRangeLimit::RangeLimitSearchBuilderBehavior
end
