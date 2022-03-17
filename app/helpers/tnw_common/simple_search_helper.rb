module TnwCommon
  module SimpleSearchHelper
    def date_filter(start_date:, end_date:, type:)
      str = "entry_" if type == :entry
      str = "" if type == :document
      start_date = start_date.blank? ? "*" : start_date
      end_date = end_date.blank? ? "*" : end_date
      "#{str}date_facet_ssim:[#{start_date} TO #{end_date}]" if (start_date != "*") || (end_date != "*")
    end

    def parse_search_term(search_term:)
      # Match searching for dates 1340/11/30
      date = %r{\d{4}/\d{2}/\d{2}}
      if search_term.match? date
        "\"#{search_term}\""
      else
        "(#{search_term.downcase})"
      end
    end

    def combine_advanced_search_terms(all_sterms:, exact_sterms:, any_sterms:, none_sterms:)
      search_term = ""
      search_term += "(#{all_sterms.downcase.split.join(' && ')})" unless all_sterms.blank?
      unless all_sterms.blank? || (exact_sterms.blank? && any_sterms.blank?)
        search_term += " && " unless search_term.delete(" ").blank?
      end
      search_term += "(\"#{exact_sterms.downcase}\")" unless exact_sterms.blank?
      unless exact_sterms.blank? || any_sterms.blank?
        search_term += " && "
      end
      search_term += "(#{any_sterms.downcase.split.join(' || ')})" unless any_sterms.blank?
      search_term += " !#{none_sterms.downcase.split.join(' !')}" unless none_sterms.blank?
      "(#{search_term})"
    end

    def shared_search_fields(sterm:)
      # AR Entries
      entry = "entry_type_search:#{sterm} ||
      section_type_search:#{sterm} || section_type_new_tesim:#{sterm} ||
      summary_search:#{sterm} || summary_tesim:#{sterm} ||
      marginalia_search:#{sterm} ||
      subject_search:#{sterm} ||
      language_search:#{sterm} ||
      note_search:#{sterm} ||
      editorial_note_search:#{sterm} ||
      is_referenced_by_search:#{sterm} ||
      entry_person_same_as_facet_ssim:#{sterm} ||
      entry_place_same_as_facet_ssim:#{sterm} || "

      # TNA Documents
      #
      # Do not search IDs
      # "series_ssim":["p55485090"],
      # "language_tesim":["pz50gw105"],
      # "subject_tesim":["6t053j89s"],
      # "document_type_search":["47429c30v"],
      # "document_type_facet_ssim":["47429c30v"],
      #
      # Do not search facets
      # "subject_facet_ssim":["Archives"],
      # "register_or_department_facet_ssim":[""],
      # "language_facet_ssim":["Latin"],
      #
      # Avoid searching _search filed will only match exact term. Requires adding *term* to match term oin phrase.
      # "entry_date_note_search":["entry date note test"],
      # "note_search":["for the appointment of commissioners to arrest hemmyngburgh, monk of selby, a vagabond in secular habit, as certified by abbot geoffrey, and deliver him to his abbot, dated 28 may 1359, see cpr 1358-61, p. 224."],
      # "language_search":["latin"],
      # "summary_search":["request for the arrest of brother john de hemmyngbrough, who has fled selby abbey without licence and is wandering in both secular and monastic habit."],
      # "subject_search":["archives"],
      #
      # Prefere search _tesim will match a term out of a phrase.
      # "entry_date_note_tesim":["Entry date note test"],
      # "note_tesim":["For the appointment of commissioners to arrest Hemmyngburgh, monk of Selby, a vagabond in secular habit, as certified by Abbot Geoffrey, and deliver him to his abbot, dated 28 May 1359, see CPR 1358-61, p. 224."],
      # "language_new_tesim":["Latin"],
      # "repository_tesim":["TNA"],
      # "reference_tesim":["C 81/1786/45"],
      # "summary_tesim":["Request for the arrest of Brother John de Hemmyngbrough, who has fled Selby abbey without licence and is wandering in both secular and monastic habit."],
      # "subject_new_tesim":["Archives"],
      #
      # Add Document _tesim fields but summary_tesim
      document = "entry_date_note_tesim: ||
      note_tesim:#{sterm} ||
      language_new_tesim:#{sterm} ||
      repository_tesim:#{sterm} ||
      reference_tesim:#{sterm} ||
      subject_new_tesim:#{sterm} ||
      publication_tesim:#{sterm} ||
      tna_addressees_tesim:#{sterm} ||
      tna_persons_tesim:#{sterm} ||
      tna_senders_tesim:#{sterm}"
      #
      # All fields
      entry + document + "|| suggest:#{sterm}"
    end

    # Sets the facet arrays and search results according to the search term
    def set_search_result_arrays(sub = nil)
      # Issue: Can this be simplyfied? Required for add_facet_to_hash and facet_hash
      @section_type_facet_hash = Hash.new 0
      @person_same_as_facet_hash = Hash.new 0
      @place_same_as_facet_hash = Hash.new 0
      @subject_facet_hash = Hash.new 0
      @date_facet_hash = Hash.new 0
      @register_facet_hash = Hash.new 0
      @department_facet_hash = Hash.new 0
      @search_result_type = Hash.new 0 # To storre information on search result typs :entry, :document

      entry_id_set = Set.new
      facets = facet_fields

      query = SolrQuery.new
      @query = SolrQuery.new

      # search_term2 = if @search_term.include?(" ") || @search_term.include?("*")
      #   "(" + @search_term.downcase + ")"
      # else
      #   "(*" + @search_term.downcase + "*)"
      # end
      if sub == "advanced"
        search_term2 = combine_advanced_search_terms(
          all_sterms: @all_sterms,
          exact_sterms: @exact_sterms,
          any_sterms: @any_sterms,
          none_sterms: @none_sterms
        )
      else
        search_term2 = parse_search_term(search_term: @search_term) unless @search_term.blank?
      end
      # Filter query for the entry (section types and subject facets), used when looping through the entries
      # TNA Documents facet fields are different tha Borthwick Entries
      fq_entry = filter_entries
      fq_document = filter_documents
      fq_date = date_filter(start_date: @start_date, end_date: @end_date, type: :entry)
      fq_entry = Array(fq_entry) | Array(fq_date) unless fq_date.nil?
      fq_date = date_filter(start_date: @start_date, end_date: @end_date, type: :document)
      fq_document = Array(fq_document) | Array(fq_date) unless fq_date.nil?

      # TNA Documents: Get matching document ids and facets
      # has_model_ssim:Document AND repository_tesim:(TNA)
      if (sub != "group") && (sub != "person") && (sub != "place") && (@archival_repository == "all" || @archival_repository != "borthwick")
        # if the search has come from the subjects browse, limit to searching for the subject
        q = if sub == "subject"
          "has_model_ssim:Document AND subject_search:" + search_term2
        else
          # q = "has_model_ssim:Entry AND (entry_type_search:*#{search_term2}* or section_type_search:*#{search_term2}* or summary_search:*#{search_term2}* or marginalia_search:*#{search_term2}* or subject_search:*#{search_term2}* or language_search:*#{search_term2}* or note_search:*#{search_term2}* or editorial_note_search:*#{search_term2}* or is_referenced_by_search:*#{search_term2}*)"
          # Solr field issue summary_search and summary_tesim term not matched in 1st field despite same content
          "has_model_ssim:Document AND (#{shared_search_fields(sterm: search_term2)})"
        end
        num = count_query(q)
        unless num == 0
          # @query.solr_query(query, 'id', 0)['response']['numFound'].to_i
          q_result = query.solr_query(q, "id", num, "date_full_ssim asc", 0, true, -1, "index", facets, fq_document)
          result_to_facet_hash(q_result)
          entry_id_set.merge(q_result["response"]["docs"].map { |e| e["id"] })
          # Keep information aboout search result types
          q_result["response"]["docs"].map { |e| @search_result_type[e["id"]] = :document }
        end
      end

      # ENTRIES: Get the matching entry ids and facets
      if (sub != "group") && (sub != "person") && (sub != "place") && (@archival_repository == "all" || @archival_repository != "tna")
        # if the search has come from the subjects browse, limit to searching for the subject
        q = if sub == "subject"
          "has_model_ssim:Entry AND subject_search:" + search_term2
        else
          # q = "has_model_ssim:Entry AND (entry_type_search:*#{search_term2}* or section_type_search:*#{search_term2}* or summary_search:*#{search_term2}* or marginalia_search:*#{search_term2}* or subject_search:*#{search_term2}* or language_search:*#{search_term2}* or note_search:*#{search_term2}* or editorial_note_search:*#{search_term2}* or is_referenced_by_search:*#{search_term2}*)"
          # Solr field issue summary_search and summary_tesim term not matched in 1st field despite same content
          "has_model_ssim:Entry AND (#{shared_search_fields(sterm: search_term2)})"
        end
        num = count_query(q)
        unless num == 0
          # @query.solr_query(query, 'id', 0)['response']['numFound'].to_i
          q_result = query.solr_query(q, "id", num, "date_full_ssim asc", 0, true, -1, "index", facets, fq_entry)
          add_result_to_facet_hash(q_result)
          entry_id_set.merge(q_result["response"]["docs"].map { |e| e["id"] })
          # Keep information aboout search result types
          q_result["response"]["docs"].map { |e| @search_result_type[e["id"]] = :entry }
        end
      end

      # PEOPLE/GROUPS: Get the matching entry ids and facets
      if (sub != "subject") && (sub != "place") && (@archival_repository == "all" || @archival_repository != "tna")
        # if the search has come from the people or group browse, limit to searching for group or person
        q = if (sub == "group") || (sub == "person")
          # q = 'has_model_ssim:RelatedAgent AND person_same_as_search:"' + @search_term.downcase + '"'
          "has_model_ssim:RelatedAgent AND person_same_as_search:" + search_term2
        else
          # q = "has_model_ssim:RelatedAgent AND (person_same_as_search:*#{search_term2}* or person_role_search:*#{search_term2}* or person_descriptor_search:*#{search_term2}* or person_descriptor_same_as_search:*#{search_term2}* or person_note_search:*#{search_term2}* or person_same_as_search:*#{search_term2}* or person_related_place_search:*#{search_term2}* or person_related_person_search:*#{search_term2}*)"
          # Use *_tesim to match against a term serarches. _search works only with complate search phrase or *term*
          "has_model_ssim:RelatedAgent AND (
              person_same_as_search:#{search_term2} or person_same_as_new_tesim:#{search_term2} or
              person_role_search:#{search_term2} or person_role_new_tesim:#{search_term2} or
              person_descriptor_search:#{search_term2} or person_descriptor_new_tesim:#{search_term2} or
              person_descriptor_same_as_search:#{search_term2} or
              person_note_search:#{search_term2} or person_note_tesim:#{search_term2} or
              person_related_place_search:#{search_term2} or person_related_place_tesim:#{search_term2} or
              person_related_person_search:#{search_term2}
            )"
        end
        num = count_query(q)
        unless num == 0
          q_result = query.solr_query(q, "relatedAgentFor_ssim", num)
          # Keep information aboout search result types
          q_result["response"]["docs"].map { |e| @search_result_type[e["relatedAgentFor_ssim"][0]] = :entry unless e.empty? }
          q_result["response"]["docs"].map do |result|
            next if result.empty?

            result["relatedAgentFor_ssim"].each do |relatedagent|
              q_result2 = query.solr_query("id:#{relatedagent}", "id,has_model_ssim", 1, nil, 0, true, -1, "index",
                facets, fq_entry)
              q_result2["response"]["docs"].map do |entry|
                next if q_result2["response"]["numFound"] == 0
                # Check that the model is Entry
                next if entry["has_model_ssim"] != ["Entry"]

                add_result_to_facet_hash(q_result2) unless entry_id_set.include? entry["id"]
                entry_id_set << entry["id"]
              end
            end
          end
        end
      end

      # PLACE: Get the matching entry ids and facets
      if (sub != "group") && (sub != "person") && (sub != "subject") && (@archival_repository == "all" || @archival_repository != "tna")
        # if the search has come from the places browse, limit to searching for places
        q = if sub == "place"
          # q = 'has_model_ssim:RelatedPlace AND place_same_as_search:"' + @search_term.downcase + '"'
          # Note Solr place_same_as_search filed will only match exact filed content. Otherwise returns nothing.
          "has_model_ssim:RelatedPlace AND place_same_as_search:#{search_term2}"
        else
          # q = "has_model_ssim:RelatedPlace AND (place_same_as_search:*#{search_term2}* or place_role_search:*#{search_term2}* or place_type_search:*#{search_term2}* or place_note_search:*#{search_term2}* or place_as_written_search:*#{search_term2}*)"
          # Use *_tesim to match against a term serarches. _search works only with complate search phrase or *term*
          "has_model_ssim:RelatedPlace AND (place_same_as_new_tesim:#{search_term2} or 
              place_role_search:#{search_term2} or place_role_new_tesim:#{search_term2} or
              place_type_search:#{search_term2} or place_type_new_tesim:#{search_term2} or
              place_note_search:#{search_term2} or place_note_tesim:#{search_term2} or
              place_as_written_search:#{search_term2} or place_as_written_tesim:#{search_term2}
            )"
        end
        facets = facet_fields
        num = count_query(q)
        unless num == 0
          q_result = query.solr_query(q, "relatedPlaceFor_ssim", num)
          # Keep information aboout search result types
          q_result["response"]["docs"]&.map { |e| @search_result_type[e["relatedPlaceFor_ssim"][0]] = :entry unless e.empty? }
          q_result["response"]["docs"]&.map do |result|
            id = ""
            id = result["relatedPlaceFor_ssim"][0] unless result["relatedPlaceFor_ssim"].nil?
            q_result2 = query.solr_query("id:#{id}", "id,has_model_ssim", 1, nil, 0, true, -1, "index", facets,
              fq_entry)
            q_result2["response"]["docs"].map do |entry|
              next if q_result2["response"]["numFound"] == 0
              # Check that the model is Entry
              next if entry["has_model_ssim"] != ["Entry"]

              add_result_to_facet_hash(q_result2) unless entry_id_set.include? entry["id"]
              entry_id_set << entry["id"]
            end
          end
        end
      end

      # SINGLE DATES: Get the matching entry ids and facets
      if (sub != "group") && (sub != "person") && (sub != "subject") && (sub != "place") && (@archival_repository == "all" || @archival_repository != "tna")
        # q = "has_model_ssim:SingleDate AND date_tesim:*#{search_term2}*"
        # q = "has_model_ssim:SingleDate AND date_tesim:#{search_term2}"
        q = "has_model_ssim:SingleDate AND date_new_ssi:#{search_term2}"
        facets = facet_fields
        num = count_query(q)
        unless num == 0
          q_result = query.solr_query(q, "dateFor_ssim", num, "date_new_ssi asc")
          # Keep information aboout search result types
          q_result["response"]["docs"]&.map { |e| @search_result_type[e["dateFor_ssim"][0]] = :entry unless e.empty? }
          q_result["response"]["docs"].map do |res|
            next if res.empty?

            res["dateFor_ssim"]&.each do |single_date|
              # from the entry dates, get the entry ids
              query.solr_query("id:#{single_date}", "entryDateFor_ssim", num)["response"]["docs"]&.map do |result|
                unless result["entryDateFor_ssim"].blank?
                  q_result2 = query.solr_query("id:#{result["entryDateFor_ssim"][0]}", "id", 1, nil, 0, true, -1,
                    "index", facets, fq_entry)
                end
                next if q_result2.blank?
                unless q_result2["response"]["numFound"] == 0
                  unless entry_id_set.include? q_result2["response"]["docs"][0]["id"]
                    add_result_to_facet_hash(q_result2)
                  end
                  entry_id_set << q_result2["response"]["docs"][0]["id"]
                  # Keep information aboout search result types
                  @search_result_type[q_result2["response"]["docs"][0]["id"]] = :entry
                end
                next if result.empty?
              end
            end
          end
        end
        # ENTRY DATES: Get the matching entry ids (no facets needed for entry dates)
        q = "has_model_ssim:EntryDate AND (date_note_tesim:#{search_term2})"
        num = count_query(q)
        unless num == 0
          q_result = query.solr_query(q, "entryDateFor_ssim", num, nil, 0, nil, nil, nil, nil, fq_entry)
          # Keep information aboout search result types
          q_result["response"]["docs"]&.map { |e| @search_result_type[e["entryDateFor_ssim"][0]] = :entry unless e.empty? }
          entry_id_set.merge(q_result["response"]["docs"]&.map { |e|
                               e["entryDateFor_ssim"][0] unless e["entryDateFor_ssim"].blank?
                             })
        end
      end

      # Sort all of the hashes
      @section_type_facet_hash = @section_type_facet_hash.sort.to_h unless @section_type_facet_hash.blank?
      @person_same_as_facet_hash = @person_same_as_facet_hash.sort.to_h unless @person_same_as_facet_hash.blank?
      @place_same_as_facet_hash = @place_same_as_facet_hash.sort.to_h unless @place_same_as_facet_hash.blank?
      @subject_facet_hash = @subject_facet_hash.sort.to_h unless @subject_facet_hash.blank?
      @date_facet_hash = @date_facet_hash.sort.to_h unless @date_facet_hash.blank?

      # sort by register number
      @register_facet_hash = @register_facet_hash.sort_by { |k, _| (k[9..10].to_i < 10 ? "0" + k[9..10] : k) }.to_h unless @register_facet_hash.blank?

      # This variable is used on the display page
      @number_of_rows = entry_id_set.size

      # Get the data for one page only, e.g. 10 rows
      entry_id_array = entry_id_set.to_a.slice((@page - 1) * @rows_per_page, @rows_per_page)

      # Iterate over the 10 (or less) entries and get all the data to display
      # Also highlight the search term
      entry_id_array.each do |entry_id|
        q = "id:#{entry_id}"

        fl = "entry_type_facet_ssim, section_type_facet_ssim, summary_tesim, marginalia_tesim, language_facet_ssim,
        subject_facet_ssim, note_tesim, editorial_note_tesim, is_referenced_by_tesim,
        date_ssim, place_same_as_facet_ssim, tna_addressees_tesim, tna_senders_tesim, tna_persons_tesim"

        query.solr_query(q, fl, 1)["response"]["docs"].map do |result|
          # Display all the text if not 'matched records'
          @match_term = @search_term
          @match_term = ".*" if @match_term == "" || @display_type == "full display" || @display_type == "summary"

          # Build up the element_array with the entry_id, etc
          @element_array = []
          @element_array << entry_id
          # Process :entry search results => "Register 5A f.110 (recto) entry 6", "9593tv46x"
          get_entry_and_folio_details(entry_id) 
          # Proces TNA Documents search results => "TNA C 81/365/22990A", "p55485090"
          get_document_details(entry_id) # unless @search_result_type[entry_id] != :document
          @element_array << get_element(result["entry_type_facet_ssim"])
          @element_array << get_element(result["section_type_facet_ssim"])
          @element_array << get_element(result["summary_tesim"])
          @element_array << get_element(result["marginalia_tesim"])
          @element_array << get_element(result["language_facet_ssim"])
          @element_array << get_element(result["subject_facet_ssim"])
          @element_array << get_element(result["note_tesim"])
          @element_array << get_element(result["editorial_note_tesim"])
          # Add [places]
          @element_array << get_element(result["is_referenced_by_tesim"])
          # Use different solr fields depending on search result type
          case @search_result_type[entry_id]
          when :entry
            get_places(entry_id, search_term2)
          when :document
            @element_array << [get_element(result["place_same_as_facet_ssim"])]
          end
          case @search_result_type[entry_id]
          # Add [people]
          when :entry
            get_people(entry_id, search_term2)
          when :document
            str = ""
            str += "Addressee/s: #{get_element(result["tna_addressees_tesim"])}; " unless result["tna_addressees_tesim"].blank? 
            str +=  "Sender/s: #{get_element(result["tna_senders_tesim"])}; " unless result["tna_senders_tesim"].blank? 
            str +=  "Person/s: #{get_element(result["tna_persons_tesim"])}; " unless result["tna_persons_tesim"].blank? 
            @element_array << [str]
          end
          # Add [dates]
          case @search_result_type[entry_id]
          when :entry
            get_dates(entry_id, search_term2) 
          when :document
            @element_array << [get_element(result["date_ssim"])] 
            @element_array << @search_result_type[entry_id] 
          end
          @partial_list_array << @element_array
        end
      end
    rescue => e
      log_error(__method__, __FILE__, e)
      raise
    end

    def get_dates(entry_id, search_term2)
      # entry date
      query = SolrQuery.new
      fl = "id, date_note_tesim, date_role_facet_ssim"
      fl_single = "id, date_tesim,date_type_tesim, date_certainty_tesim"
      tmp_array = []

      if @display_type == "matched records"
        q = "entryDateFor_ssim:#{entry_id} AND (date_note_search:*#{search_term2}* OR date_role_search:*#{search_term2}*)"
        num = query.solr_query(q, "id", 0)["response"]["numFound"].to_i
        q = "entryDateFor_ssim:#{entry_id}" if num == 0
        query.solr_query(q, fl, 1)["response"]["docs"].map do |result|
          date_array = []
          date_role_string = result["date_role_facet_ssim"]
          date_note_string = result["date_note_tesim"]
          # single dates
          q = "dateFor_ssim:#{result["id"]} AND (date_certainty_tesim:*#{search_term2}* OR date_tesim:*#{search_term2}*)"
          num = query.solr_query(q, "id", 0)["response"]["numFound"].to_i
          q = "dateFor_ssim:#{result["id"]}" if num == 0
          query.solr_query(q, fl_single, num)["response"]["docs"].map do |result2|
            date_array << result2
          end
          # If 'matched records' is selected, get the places, agents and dates if search results have been found above
          date_string = get_date_string(date_role_string, date_note_string, date_array)
          tmp_array << date_string if date_string.include? "span"
          tmp_array = [] if tmp_array[0] == ""
        end
      else
        q = "entryDateFor_ssim:#{entry_id}"
        # date_note_string = ''
        date_role_string = ""
        date_note_string = ""
        # entry dates
        num = query.solr_query(q, "id", 0)["response"]["numFound"].to_i
        query.solr_query("entryDateFor_ssim:#{entry_id}", fl, num)["response"]["docs"].map do |result|
          date_role_string = result["date_role_facet_ssim"]
          date_note_string = result["date_note_tesim"]
          date_array = []
          # single dates
          entry_id2 = result["id"]
          q = "dateFor_ssim:#{entry_id2}"
          num = query.solr_query(q, "id", 0)["response"]["numFound"].to_i
          query.solr_query(q, fl_single, num)["response"]["docs"].map do |result2|
            date_array << result2
          end
          tmp_array << get_date_string(date_role_string, date_note_string, date_array)
        end
      end
      @element_array << tmp_array
    rescue => e
      log_error(__method__, __FILE__, e)
      raise
    end

    # Helper method for getting the dates data
    def get_date_string(
      date_role_string,
      date_note_string,
      date_array
    )

      date_string = ""
      unless date_role_string.nil? || (date_role_string == ["unknown"])
        date_string += "#{get_element(date_role_string, true).capitalize}: "
      end
      unless date_array.nil? || (date_array == [])
        date_array.each do |result|
          if !result["date_type_tesim"].nil?
            if result["date_type_tesim"].join == "single"
              date_string += get_element(result["date_tesim"], true)
              date_string += " (#{get_element(result["date_certainty_tesim"], true)})"
            elsif result["date_type_tesim"].join == "start"
              date_string += get_element(result["date_tesim"])
              date_string += " (#{get_element(result["date_certainty_tesim"], true)}) - "
            elsif result["date_type_tesim"].join == "end"
              date_string += get_element(result["date_tesim"])
              date_string += " (#{get_element(result["date_certainty_tesim"], true)})"
            end
          else
            date_string += get_element(result["date_tesim"], true)
            date_string += " (#{get_element(result["date_certainty_tesim"], true)})"
          end
        end
      end
      unless date_note_string.nil?
        date_string += "; Note: " unless date_string.end_with? ": "
        date_string += get_element(date_note_string, true).capitalize.to_s
      end
      # This should only happen with matched records, where there is only a role; we do not want to show this
      date_string = date_string[0, date_string.index("; Note:")] if date_string.include? "; Note:"
      date_string
    rescue => e
      log_error(__method__, __FILE__, e)
      raise
    end

    # Get the place data from solr for a particular entry_id and search term (see above method call)
    def get_places(entry_id, search_term2)
      q = "relatedPlaceFor_ssim:#{entry_id} "
      if @display_type == "matched records"
        q = "relatedPlaceFor_ssim:#{entry_id} AND (place_as_written_search:*#{search_term2}* or place_role_search:*#{search_term2}* or place_type_search:*#{search_term2}* or place_note_search:*#{search_term2}* or place_same_as_search:*#{search_term2}*)"
      end
      fl = "id, place_as_written_tesim, place_role_facet_ssim, place_type_facet_ssim, place_note_tesim, place_same_as_facet_ssim"

      # place_note_string = ''
      temp_array = []

      SolrQuery.new.solr_query(q, fl, 1000)["response"]["docs"].map do |result|
        place_string = get_place_string(
          result["place_as_written_tesim"],
          result["place_role_facet_ssim"],
          result["place_type_facet_ssim"],
          result["place_same_as_facet_ssim"]
        )
        # If 'matched records' is selected, get the places, agents and dates if search results have been found above
        if @display_type == "matched records"
          temp_array << place_string if place_string.include? "span"
        else
          temp_array << place_string
        end
      end

      @element_array << temp_array
    rescue => e
      log_error(__method__, __FILE__, e)
      raise
    end

    # Get the person data from solr for a particular entry_id and search term (see above method call)
    def get_people(entry_id, search_term2)
      q = "relatedAgentFor_ssim:#{entry_id}"
      if @display_type == "matched records"
        q = "relatedAgentFor_ssim:#{entry_id} AND (person_as_written_search:*#{search_term2}* or person_role_search:*#{search_term2}* or person_descriptor_search:*#{search_term2}* or person_descriptor_same_as_search:*#{search_term2}* or person_note_search:*#{search_term2}* or person_same_as_search:*#{search_term2}* or person_related_place_search:*#{search_term2}* or person_related_person_search:*#{search_term2}*)"
      end
      fl = "id, person_as_written_tesim, person_role_facet_ssim, person_descriptor_facet_ssim, person_descriptor_as_written_tesim, person_note_tesim, person_same_as_facet_ssim, person_related_place_tesim, person_related_person_tesim"

      # not currently including person_descriptor_as_written and person_note
      temp_array = []

      SolrQuery.new.solr_query(q, fl, 1000)["response"]["docs"].map do |result|
        person_string = get_person_string(
          result["person_as_written_tesim"],
          result["person_role_facet_ssim"],
          result["person_descriptor_facet_ssim"],
          result["person_same_as_facet_ssim"],
          result["person_related_place_tesim"],
          result["person_related_person_tesim"],
          result["person_note_tesim"]
        )
        # If 'matched records' is selected, get the places, agents and dates if search results have been found above
        if @display_type == "matched records"
          temp_array << person_string if person_string.include? "span"
        else
          temp_array << person_string
        end
      end

      temp_array = temp_array.sort

      # Put testator at beginning
      temp_array.each_with_index do |a, index|
        if a.start_with? "Testator"
          # Remove testators from current position and insert at beginning
          temp_array.insert(0, temp_array.delete_at(index))
        end
      end
      @element_array << temp_array
    rescue => e
      log_error(__method__, __FILE__, e)
      raise
    end

    # Helper method for getting the person / group data
    def get_person_string(
      person_as_written_string,
      person_role_string,
      person_descriptor_string,
      person_same_as_string,
      person_related_place_string,
      person_related_person_string,
      person_note_string
    )

      person_string = ""
      # In the Register 12 data, where an exact match to the roles vocab was not found, a note was used
      # Use this note if present where role is 'unknown'
      unless person_role_string.nil?
        if person_role_string == ["unknown"]
          unless person_note_string.nil? && person_note_string.include?("Role: ")
            person_string += "#{get_element(person_note_string, true).gsub("Role: ", "").capitalize}: "
          end
        else
          person_string += "#{get_element(person_role_string, true).capitalize}: "
        end
      end
      if person_same_as_string.nil?
        person_string += get_element(person_as_written_string, true) unless person_as_written_string.nil?
        unless person_descriptor_string.nil?
          person_string += if (person_string == "") || person_string.end_with?(": ")
            get_element(person_descriptor_string, true).capitalize.to_s
          else
            " (#{get_element(person_descriptor_string, true)})"
          end
        end
      else
        person_string += get_element(person_same_as_string, true)
        person_string += " (#{get_element(person_descriptor_string, true)})" unless person_descriptor_string.nil?
        unless person_as_written_string.nil?
          person_string += "; written as #{get_element(person_as_written_string, true)}"
        end
      end
      unless person_related_place_string.nil?
        person_string += "; related places: #{get_element(person_related_place_string, true)}"
      end
      unless person_related_person_string.nil?
        person_string += "; related people: #{get_element(person_related_person_string, true)}"
      end
      person_string
    end

    # Helper method for getting the place data
    def get_place_string(
      place_as_written_string,
      place_role_string,
      place_type_string,
      place_same_as_string
    )
      place_string = ""
      unless place_role_string.nil? || (place_role_string == ["unknown"])
        place_string += "#{get_element(place_role_string, true).capitalize}: "
      end
      if place_same_as_string.nil?
        place_string += get_element(place_as_written_string, true) unless place_as_written_string.nil?
        unless place_type_string.nil? || (place_type_string == ["unknown"])
          place_string += " (#{get_element(place_type_string, true)})"
        end
      else
        place_string += get_element(place_same_as_string)
        unless place_type_string.nil? || (place_type_string == ["unknown"])
          place_string += " (#{get_element(place_type_string, true)})"
        end
        place_string += "; written as #{get_element(place_as_written_string, true)}" unless place_as_written_string.nil?
      end
      place_string
    end

    # This method uses the entry_id to get the title of the search result, i.e. 'Register Folio Entry' and folio_id
    def get_entry_and_folio_details(entry_id)
      # Get the entry_no and folio_id for the entry_id
      id = get_id(entry_id)
      # if TNA Documents stop gracefully
      return if @search_result_type[id] == :document

      SolrQuery.new.solr_query("id:" + id, "entry_no_tesim, entry_folio_facet_ssim, folio_ssim",
        1)["response"]["docs"].map do |result|
        @element_array << if result["entry_folio_facet_ssim"].nil? || result["entry_no_tesim"].nil?
          "Untitled"
        else
          "#{result["entry_folio_facet_ssim"].join} entry #{result["entry_no_tesim"].join}"
        end
        @element_array << result["folio_ssim"].join
      end
    rescue => e
      log_error(__method__, __FILE__, e)
      raise
    end

    # This method uses the document_id to get the title of the search result, i.e. 'TNA Reference' and series_id
    def get_document_details(entry_id)
      # Get the entry_no and folio_id for the entry_id
      id = get_id(entry_id)
      # if TNA Documents stop gracefully
      return if @search_result_type[id] != :document

      # Constructed from "series_ssim":["p55485090"], "repository_tesim":["TNA"], "reference_tesim":["C 81/365/22990A"],
      SolrQuery.new.solr_query("id:" + id, "repository_tesim, reference_tesim, series_ssim",
        1)["response"]["docs"].map do |result|
        @element_array << if result["repository_tesim"].nil? || result["reference_tesim"].nil?
          "Untitled"
        else
          "#{result["repository_tesim"].join} - #{result["reference_tesim"].join}"
        end
        @element_array << result["series_ssim"].join
      end
    rescue => e
      log_error(__method__, __FILE__, e)
      raise
    end

    # Helper method to check if terms match the search term and if so, whether to put a comma in front of it
    # i.e. this is required if it is not the first term in the string
    def get_element(input_array, return_string = nil)
      begin
        str = ""
        is_match = false

        unless input_array.nil?

          # Iterate over the input array and add columns between elements
          input_array.each do |t|
            is_match = true if /#{@match_term}/i.match?(t)
            str += ", " if str != ""
            str += t
          end

          # The following code highlights text which matches the search_term
          # It highlights all combinations, e.g. 'york', 'York', 'YORK', 'paul young', 'paul g', etc
          if (is_match == true) && (@search_term != "")
            # if (is_match == true) && (@search_term != "") && !@search_term.downcase.include?("*")
            # Replace all spaces with '.*' so that it searches for all characters in between text, e.g. 'paul y' will find 'paul young'
            # temp = @search_term.gsub(/\s+/, '.*')
            # remove double quotes and other Solr special characters
            temp = @search_term.delete('\"\+\-\!\?\*\~\&\|\(\)') # .gsub(/\s+/, ".*")
            # Split each term for highlight FixMe: support for "word phrases"
            temp.split.each do |t|
              next unless t.length > 3 # Skip short words e.g. "of, at, in"

              str = str.gsub(/#{t}/i) do |term|
                "<span class=\'highlight_text\'>#{term}</span>"
              end
            end
          elsif (is_match == false) && (@search_term != "")
            str = "" if return_string.nil?
          end
        end
      rescue => e
        log_error(__method__, __FILE__, e)
        raise
      end

      str
    end

    # This method gets all the solr data from an entry into a db_entry database object
    # We did this because getting the data using activeFedora is too slow
    # It is used to display the data on the view pages and when a user is editing the entry form
    # but activeFedora is used when the user actually saves the form (so that the data goes into Fedora)
    # Note that although we are using an object which corresponds to the database tables, we don't actually populate the tables with any data
    # It appears that rails requires the tables to be there even if you don't use them in order to create a database object
    def get_solr_data(db_entry)
      SolrQuery.new.solr_query("id:" + db_entry.entry_id,
        "entry_no_tesim, entry_type_tesim, section_type_tesim, continues_on_tesim, summary_tesim, marginalia_tesim, language_tesim, subject_tesim, note_tesim, editorial_note_tesim, is_referenced_by_tesim", 1)["response"]["docs"].map do |result|
        next if result["entry_no_tesim"].nil?

        db_entry.id = 1

        db_entry.entry_no = result["entry_no_tesim"].join

        entry_type_list = result["entry_type_tesim"]

        entry_type_list&.each do |tt|
          db_entry_type = DbEntryType.new
          db_entry_type.name = tt
          db_entry.db_entry_types << db_entry_type
        end

        section_type_list = result["section_type_tesim"]

        section_type_list&.each do |tt|
          db_section_type = DbSectionType.new
          db_section_type.name = tt
          db_entry.db_section_types << db_section_type
        end

        db_entry.continues_on = result["continues_on_tesim"].join unless result["continues_on_tesim"].nil?

        summary = result["summary_tesim"]

        db_entry.summary = summary.join unless summary.nil?

        marginalium_list = result["marginalia_tesim"]

        marginalium_list&.each do |tt|
          db_marginalium = DbMarginalium.new
          db_marginalium.name = tt
          db_entry.db_marginalia << db_marginalium
        end

        language_list = result["language_tesim"]

        language_list&.each do |tt|
          db_language = DbLanguage.new
          db_language.name = tt
          db_entry.db_languages << db_language
        end

        subject_list = result["subject_tesim"]

        subject_list&.each do |tt|
          db_subject = DbSubject.new
          db_subject.name = tt
          db_entry.db_subjects << db_subject
        end

        note_list = result["note_tesim"]

        note_list&.each do |tt|
          db_note = DbNote.new
          db_note.name = tt
          db_entry.db_notes << db_note
        end

        editorial_note_list = result["editorial_note_tesim"]

        editorial_note_list&.each do |tt|
          db_editorial_note = DbEditorialNote.new
          db_editorial_note.name = tt
          db_entry.db_editorial_notes << db_editorial_note
        end

        is_referenced_by_list = result["is_referenced_by_tesim"]

        is_referenced_by_list&.each do |tt|
          db_is_referenced_by = DbIsReferencedBy.new
          db_is_referenced_by.name = tt
          db_entry.db_is_referenced_bys << db_is_referenced_by
        end

        SolrQuery.new.solr_query("has_model_ssim:EntryDate AND entryDateFor_ssim:" + db_entry.entry_id,
          "id, date_role_tesim, date_note_tesim", 100)["response"]["docs"].map do |result|
          date_id = result["id"]

          next if date_id.nil?

          db_entry_date = DbEntryDate.new

          db_entry_date.date_id = date_id

          db_entry_date.id = 1

          SolrQuery.new.solr_query("has_model_ssim:SingleDate AND dateFor_ssim:" + date_id,
            "id, date_tesim, date_type_tesim, date_certainty_tesim", 100)["response"]["docs"].map do |result2|
            single_date_id = result2["id"]

            next if single_date_id.nil?

            db_single_date = DbSingleDate.new

            db_single_date.single_date_id = single_date_id

            db_single_date.id = 1 # single_date_id.gsub(/test:/, '').to_i

            date_certainty_list = result2["date_certainty_tesim"]

            date_certainty_list&.each do |tt|
              db_date_certainty = DbDateCertainty.new
              db_date_certainty.name = tt
              db_single_date.db_date_certainties << db_date_certainty
            end

            date = result2["date_tesim"]

            db_single_date.date = date.join unless date.nil?

            date_type = result2["date_type_tesim"]

            db_single_date.date_type = date_type.join unless date_type.nil?

            db_entry_date.db_single_dates << db_single_date
          end

          date_role = result["date_role_tesim"]

          db_entry_date.date_role = date_role.join unless date_role.nil?

          date_note = result["date_note_tesim"]

          db_entry_date.date_note = date_note.join unless date_note.nil?

          db_entry.db_entry_dates << db_entry_date
        end

        SolrQuery.new.solr_query('has_model_ssim:RelatedPlace AND relatedPlaceFor_ssim:"' + db_entry.entry_id + '"',
          "id, place_same_as_tesim, place_as_written_tesim, place_role_tesim, place_type_tesim, place_note_tesim", 100)["response"]["docs"].map do |result|
          related_place_id = result["id"]

          next if related_place_id.nil?

          db_related_place = DbRelatedPlace.new

          db_related_place.place_id = related_place_id

          db_related_place.id = 1 # related_place_id.gsub(/test:/, '').to_i

          place_same_as = result["place_same_as_tesim"]

          db_related_place.place_same_as = place_same_as.join unless place_same_as.nil?

          place_as_written_list = result["place_as_written_tesim"]

          place_as_written_list&.each do |tt|
            db_place_as_written = DbPlaceAsWritten.new
            db_place_as_written.name = tt
            db_related_place.db_place_as_writtens << db_place_as_written
          end

          place_role_list = result["place_role_tesim"]

          place_role_list&.each do |tt|
            db_place_role = DbPlaceRole.new
            db_place_role.name = tt
            db_related_place.db_place_roles << db_place_role
          end

          place_type_list = result["place_type_tesim"]

          place_type_list&.each do |tt|
            db_place_type = DbPlaceType.new
            db_place_type.name = tt
            db_related_place.db_place_types << db_place_type
          end

          place_note_list = result["place_note_tesim"]

          place_note_list&.each do |tt|
            db_place_note = DbPlaceNote.new
            db_place_note.name = tt
            db_related_place.db_place_notes << db_place_note
          end

          db_entry.db_related_places << db_related_place
        end

        SolrQuery.new.solr_query('has_model_ssim:RelatedAgent AND relatedAgentFor_ssim:"' + db_entry.entry_id + '"',
          "id, person_same_as_tesim, person_group_tesim, person_gender_tesim, person_as_written_tesim, person_role_tesim, person_descriptor_tesim, person_descriptor_as_written_tesim, person_note_tesim, person_related_place_tesim, person_related_person_tesim", 100)["response"]["docs"].map do |result|
          related_agent_id = result["id"]

          next if related_agent_id.nil?

          db_related_agent = DbRelatedAgent.new

          db_related_agent.person_id = related_agent_id

          # related_agent_id.unpack('b*').each do | o | db_related_agent.id = o.to_i(2) end
          db_related_agent.id = 1

          person_same_as = result["person_same_as_tesim"]

          db_related_agent.person_same_as = person_same_as.join unless person_same_as.nil?

          person_group = result["person_group_tesim"]

          db_related_agent.person_group = person_group.join unless person_group.nil?

          person_gender = result["person_gender_tesim"]

          db_related_agent.person_gender = person_gender.join unless person_gender.nil?

          person_as_written_list = result["person_as_written_tesim"]

          person_as_written_list&.each do |tt|
            db_person_as_written = DbPersonAsWritten.new
            db_person_as_written.name = tt
            db_related_agent.db_person_as_writtens << db_person_as_written
          end

          person_role_list = result["person_role_tesim"]

          person_role_list&.each do |tt|
            db_person_role = DbPersonRole.new
            db_person_role.name = tt
            db_related_agent.db_person_roles << db_person_role
          end

          person_descriptor_list = result["person_descriptor_tesim"]

          person_descriptor_list&.each do |tt|
            db_person_descriptor = DbPersonDescriptor.new
            db_person_descriptor.name = tt
            db_related_agent.db_person_descriptors << db_person_descriptor
          end

          person_descriptor_as_written_list = result["person_descriptor_as_written_tesim"]

          person_descriptor_as_written_list&.each do |tt|
            db_person_descriptor_as_written = DbPersonDescriptorAsWritten.new
            db_person_descriptor_as_written.name = tt
            db_related_agent.db_person_descriptor_as_writtens << db_person_descriptor_as_written
          end

          person_note_list = result["person_note_tesim"]

          person_note_list&.each do |tt|
            db_person_note = DbPersonNote.new
            db_person_note.name = tt
            db_related_agent.db_person_notes << db_person_note
          end

          person_related_place_list = result["person_related_place_tesim"]

          person_related_place_list&.each do |tt|
            db_person_related_place = DbPersonRelatedPlace.new
            db_person_related_place.name = tt
            db_related_agent.db_person_related_places << db_person_related_place
          end

          person_related_person_list = result["person_related_person_tesim"]

          person_related_person_list&.each do |tt|
            db_person_related_person = DbPersonRelatedPerson.new
            db_person_related_person.name = tt
            db_related_agent.db_person_related_people << db_person_related_person
          end

          db_entry.db_related_agents << db_related_agent
        end
      end
    rescue => e
      log_error(__method__, __FILE__, e)
      raise
    end

    # Gets the list of entries (id, entry_no) in the specific folio
    def get_entry_list(folio_id)
      begin
        entry_list = []

        id = get_id(folio_id)

        SolrQuery.new.solr_query("folio_ssim:#{id}", "id, entry_no_tesim", 1800,
          "entry_no_si asc")["response"]["docs"].map do |result|
          element_list = []
          id = result["id"]
          entry_no = result["entry_no_tesim"].join
          element_list << id
          element_list << entry_no
          entry_list << element_list
        end
        # Sort entries by their numeric entry nos
        entry_list.sort! { |a, b| a[1].to_i <=> b[1].to_i }
      rescue => e
        log_error(__method__, __FILE__, e)
        raise
      end

      entry_list
    end

    # return the numRecords from a solr query
    def count_query(query)
      @query.solr_query(query, "id", 0)["response"]["numFound"].to_i
    end

    # return the facet fields
    def facet_fields
      %w[
        register_or_department_facet_ssim
        section_type_facet_ssim
        subject_facet_ssim
        entry_person_same_as_facet_ssim
        entry_place_same_as_facet_ssim
        entry_date_facet_ssim
        date_facet_ssim
        place_same_as_facet_ssim
        person_same_as_facet_ssim
        entry_register_facet_ssim
      ]
    end

    # Build the filter query for solr - part of facet brows search
    # Borthwick Entries facet fields
    def filter_entries()
      fq = []
      fq << "section_type_facet_ssim:\"#{@section_type_facet}\"" unless @section_type_facet.nil?
      fq << "subject_facet_ssim:\"#{@subject_facet}\"" unless @subject_facet.nil?
      fq << "entry_register_facet_ssim:\"#{@register_facet}\"" unless @register_facet.nil?
      fq << "register_or_department_facet_ssim:\"#{@department_facet}\"" unless @department_facet.nil?
      fq << "entry_person_same_as_facet_ssim:\"#{@person_same_as_facet}\"" unless @person_same_as_facet.nil?
      fq << "entry_place_same_as_facet_ssim:\"#{@place_same_as_facet}\"" unless @place_same_as_facet.nil?
      fq << "entry_date_facet_ssim:#{@date_facet}*" unless @date_facet.nil?
      fq = nil if fq.empty?
      fq
    end
    # TNA Documents facet fields
    def filter_documents()
      fq = []
      fq << "section_type_facet_ssim:\"#{@section_type_facet}\"" unless @section_type_facet.nil?
      fq << "subject_facet_ssim:\"#{@subject_facet}\"" unless @subject_facet.nil?
      fq << "entry_register_facet_ssim:\"#{@register_facet}\"" unless @register_facet.nil?
      fq << "register_or_department_facet_ssim:\"#{@department_facet}\"" unless @department_facet.nil?
      fq << "person_same_as_facet_ssim:\"#{@person_same_as_facet}\"" unless @person_same_as_facet.nil?
      fq << "place_same_as_facet_ssim:\"#{@place_same_as_facet}\"" unless @place_same_as_facet.nil?
      fq << "date_facet_ssim:#{@date_facet}*" unless @date_facet.nil?
      fq = nil if fq.empty?
      fq
    end

    def result_to_facet_hash(solr_result)
      unless solr_result["facet_counts"]["facet_fields"]["subject_facet_ssim"].nil?
        @subject_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["subject_facet_ssim"].flatten(1)]
      end
      unless solr_result["facet_counts"]["facet_fields"]["section_type_facet_ssim"].nil?
        @section_type_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["section_type_facet_ssim"].flatten(1)]
      end
      unless solr_result["facet_counts"]["facet_fields"]["entry_person_same_as_facet_ssim"].nil?
        @person_same_as_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["entry_person_same_as_facet_ssim"].flatten(1)]
      end
      # TNA Person facet - currently not present in Solr 
      unless solr_result["facet_counts"]["facet_fields"]["person_same_as_facet_ssim"].nil?
        @person_same_as_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["person_same_as_facet_ssim"].flatten(1)]
      end
      unless solr_result["facet_counts"]["facet_fields"]["entry_place_same_as_facet_ssim"].nil?
        @place_same_as_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["entry_place_same_as_facet_ssim"].flatten(1)]
      end
      # TNA Place facet
      unless solr_result["facet_counts"]["facet_fields"]["place_same_as_facet_ssim"].nil?
        @place_same_as_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["place_same_as_facet_ssim"].flatten(1)]
      end
      unless solr_result["facet_counts"]["facet_fields"]["entry_date_facet_ssim"].nil?
        @date_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["entry_date_facet_ssim"].flatten(1)]
      end
      # TNA Documents date facet
      unless solr_result["facet_counts"]["facet_fields"]["date_facet_ssim"].nil?
        @date_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["date_facet_ssim"].flatten(1)]
      end
      unless solr_result["facet_counts"]["facet_fields"]["entry_register_facet_ssim"].nil?
        @register_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["entry_register_facet_ssim"].flatten(1)]
      end
      # TNA Department facet
      unless solr_result["facet_counts"]["facet_fields"]["register_or_department_facet_ssim"].nil?
        @department_facet_hash = Hash[*solr_result["facet_counts"]["facet_fields"]["register_or_department_facet_ssim"].flatten(1)]
      end
    end

    def add_result_to_facet_hash(solr_result)
      solr_result["facet_counts"]["facet_fields"]["subject_facet_ssim"]&.each_with_index do |st, index|
        if index.even? == true
          if @subject_facet_hash[st]
            @subject_facet_hash[st] += solr_result["facet_counts"]["facet_fields"]["subject_facet_ssim"][index + 1]
          else
            @subject_facet_hash[st] = solr_result["facet_counts"]["facet_fields"]["subject_facet_ssim"][index + 1]
          end
        end
      end
      solr_result["facet_counts"]["facet_fields"]["section_type_facet_ssim"]&.each_with_index do |st, index|
        if index.even? == true
          if @section_type_facet_hash[st]
            @section_type_facet_hash[st] += solr_result["facet_counts"]["facet_fields"]["section_type_facet_ssim"][index + 1]
          else
            @section_type_facet_hash[st] =
              solr_result["facet_counts"]["facet_fields"]["section_type_facet_ssim"][index + 1]
          end
        end
      end
      solr_result["facet_counts"]["facet_fields"]["entry_person_same_as_facet_ssim"]&.each_with_index do |st, index|
        if index.even? == true
          if @person_same_as_facet_hash[st]
            @person_same_as_facet_hash[st] += solr_result["facet_counts"]["facet_fields"]["entry_person_same_as_facet_ssim"][index + 1]
          else
            @person_same_as_facet_hash[st] =
              solr_result["facet_counts"]["facet_fields"]["entry_person_same_as_facet_ssim"][index + 1]
          end
        end
      end
      solr_result["facet_counts"]["facet_fields"]["entry_place_same_as_facet_ssim"]&.each_with_index do |st, index|
        if index.even? == true
          if @place_same_as_facet_hash[st]
            @place_same_as_facet_hash[st] += solr_result["facet_counts"]["facet_fields"]["entry_place_same_as_facet_ssim"][index + 1]
          else
            @place_same_as_facet_hash[st] =
              solr_result["facet_counts"]["facet_fields"]["entry_place_same_as_facet_ssim"][index + 1]
          end
        end
      end
      solr_result["facet_counts"]["facet_fields"]["entry_date_facet_ssim"]&.each_with_index do |st, index|
        if index.even? == true
          if @date_facet_hash[st]
            @date_facet_hash[st] += solr_result["facet_counts"]["facet_fields"]["entry_date_facet_ssim"][index + 1]
          else
            @date_facet_hash[st] = solr_result["facet_counts"]["facet_fields"]["entry_date_facet_ssim"][index + 1]
          end
        end
      end
      solr_result["facet_counts"]["facet_fields"]["entry_register_facet_ssim"]&.each_with_index do |st, index|
        if index.even? == true
          if @register_facet_hash[st]
            @register_facet_hash[st] += solr_result["facet_counts"]["facet_fields"]["entry_register_facet_ssim"][index + 1]
          else
            @register_facet_hash[st] =
              solr_result["facet_counts"]["facet_fields"]["entry_register_facet_ssim"][index + 1]
          end
        end
      end
      solr_result["facet_counts"]["facet_fields"]["register_or_department_facet_ssim"]&.each_with_index do |st, index|
        if index.even? == true
          if @department_facet_hash[st]
            @department_facet_hash[st] += solr_result["facet_counts"]["facet_fields"]["register_or_department_facet_ssim"][index + 1]
          else
            @department_facet_hash[st] =
              solr_result["facet_counts"]["facet_fields"]["register_or_department_facet_ssim"][index + 1]
          end
        end
      end
    end

    def get_id(o)
      o.include?("/") ? o.rpartition("/").last : o
    end

    # Writes error message to the log
    def log_error(method, file, error)
      time = ""
      # Only add time for development log because production already outputs timestamp
      time = Time.now.strftime("[%d/%m/%Y %H:%M:%S] ").to_s if Rails.env == "development"
      logger.error "#{time}EXCEPTION IN #{file}, method='#{method}' [#{error}]"
    end
  end
end
