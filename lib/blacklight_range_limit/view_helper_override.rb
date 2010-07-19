  # Meant to be applied on top of Blacklight helpers, to over-ride
  # Will add rendering of limit itself in sidebar, and of constraings
  # display. 
  module BlacklightRangeLimit::ViewHelperOverride


    
    def render_facet_limit(solr_field)
      if (range_config.keys.include?( solr_field ))
        if (should_show_limit(solr_field))
          render(:partial => "blacklight_range_limit/limit", :locals=> {:solr_field => solr_field, :config => range_config[solr_field]})
        end
      else
        super(solr_field)
      end
    end

    def render_constraints_filters(my_params = params)
      content = super(my_params)
      # add a constraint for ranges?
      unless my_params[:range].blank?
        my_params[:range].each_pair do |solr_field, hash|
          next unless hash["missing"] || hash["begin"] || hash["end"]
          
          content << render_constraint_element(
            facet_field_labels[solr_field],
            range_display(solr_field),
            :remove => remove_range_param(solr_field, my_params)
          )                      
        end
      end
      return content
    end

    def render_search_to_s_filters(my_params)
      content = super(my_params)
      # add a constraint for ranges?
      unless my_params[:range].blank?
        my_params[:range].each_pair do |solr_field, hash|
          next unless hash["missing"] || hash["begin"] || hash["end"]        
          
          content << render_search_to_s_element(
            facet_field_labels[solr_field],
            range_display(solr_field, my_params)
          )          
        
        end
      end
      return content
    end

    def remove_range_param(solr_field, my_params = params)
      if ( my_params["range"] )
        my_params = my_params.dup 
        my_params["range"].delete(solr_field)
      end
      return my_params
    end
    
  end

