  # Meant to be applied on top of Blacklight helpers, to over-ride
  # Will add rendering of limit itself in sidebar, and of constraings
  # display. 
  module BlacklightRangeLimit::ViewHelperOverride

    def query_has_constraints?(localized_params = params)
      !(localized_params[:q].blank? and localized_params[:f].blank? and localized_params[:range].blank?)
    end

    def has_search_parameters?
      !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank? or !params[:range].blank?
    end

   
    def facet_partial_name(display_facet)
      return "blacklight_range_limit/range_limit_panel" if range_config(display_facet.name) and should_show_limit(display_facet.name)
      super
    end

    def render_constraints_filters(my_params = params)
      content = super(my_params)
      # add a constraint for ranges?
      unless my_params[:range].blank?
        my_params[:range].each_pair do |solr_field, hash|
          next unless hash["missing"] || (!hash["begin"].blank?) || (!hash["end"].blank?)
          content << render_constraint_element(
            facet_field_labels[solr_field],
            range_display(solr_field, my_params),
            :escape_value => false,
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
          next unless hash["missing"] || (!hash["begin"].blank?) || (! hash["end"].blank?)        
          
          content << render_search_to_s_element(
            facet_field_labels[solr_field],
            range_display(solr_field, my_params),
            :escape_value => false
          )          
        
        end
      end
      return content
    end

    def remove_range_param(solr_field, my_params = params)
      if ( my_params["range"] )
        my_params = my_params.dup
        my_params["range"] = my_params["range"].dup
        my_params["range"].delete(solr_field)
      end
      return my_params
    end

    # Looks in the solr @response for ["facet_counts"]["facet_queries"][solr_field], for elements
    # expressed as "solr_field:[X to Y]", turns them into
    # a list of hashes with [:from, :to, :count], sorted by
    # :from. Assumes integers for sorting purposes. 
    def solr_range_queries_to_a(solr_field)
      return [] unless @response["facet_counts"] && @response["facet_counts"]["facet_queries"]

      array = []

      @response["facet_counts"]["facet_queries"].each_pair do |query, count|
        if query =~ /#{solr_field}: *\[ *(\d+) *TO *(\d+) *\]/
          array << {:from => $1, :to => $2, :count => count}
        end
      end
      array = array.sort_by {|hash| hash[:from].to_i }

      return array
    end
    
  end

