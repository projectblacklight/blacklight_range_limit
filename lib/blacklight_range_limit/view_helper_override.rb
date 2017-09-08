  # Meant to be applied on top of Blacklight helpers, to over-ride
  # Will add rendering of limit itself in sidebar, and of constraings
  # display.
  module BlacklightRangeLimit::ViewHelperOverride



    def facet_partial_name(display_facet)
      config = range_config(display_facet.name)
      return config[:partial] || 'blacklight_range_limit/range_limit_panel' if config && should_show_limit(display_facet.name)
      super
    end

    def has_range_limit_parameters?(my_params = params)
      my_params[:range] &&
        my_params[:range].to_unsafe_h.any? do |key, v|
          v.present? && v.respond_to?(:'[]') &&
          (v["begin"].present? || v["end"].present? || v["missing"].present?)
        end
    end

    # over-ride, call super, but make sure our range limits count too
    def has_search_parameters?
      super || has_range_limit_parameters?
    end

    def query_has_constraints?(my_params = params)
      super || has_range_limit_parameters?(my_params)
    end

    # Over-ride to recognize our custom params for range facets
    def facet_field_in_params?(field_name)
      return super || (
        range_config(field_name) &&
        params[:range] &&
        params[:range][field_name] &&
          ( params[:range][field_name]["begin"].present? ||
            params[:range][field_name]["end"].present? ||
            params[:range][field_name]["missing"].present?
          )
      )
    end

    def render_constraints_filters(my_params = params)
      content = super(my_params)
      # add a constraint for ranges?
      unless my_params[:range].blank?
        my_params[:range].each_pair do |solr_field, hash|

          next unless hash["missing"] || (!hash["begin"].blank?) || (!hash["end"].blank?)
          content << render_constraint_element(
            facet_field_label(solr_field),
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
            facet_field_label(solr_field),
            range_display(solr_field, my_params),
            :escape_value => false
          )

        end
      end
      return content
    end

    def remove_range_param(solr_field, my_params = params)
      my_params = Blacklight::SearchState.new(my_params, blacklight_config).to_h
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

    def range_config(solr_field)
      BlacklightRangeLimit.range_config(blacklight_config, solr_field)
    end

  end
