
# We want to add a new collection action to Catalog, without over-writing
# what's already there. This SEEMS to do it. 
ActionController::Routing::Routes.draw do |map|
  map.resources(:catalog, :collection=> {:range_limit => :get})
end

