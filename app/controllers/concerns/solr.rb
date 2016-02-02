module Solr
  require 'active_support/core_ext/array'

  # Sets the facet arrays and search results according to the search term
  def set_search_result_arrays(sub=nil)

    begin

      @section_type_facet_hash = Hash.new 0
      @person_same_as_facet_hash = Hash.new 0
      @place_same_as_facet_hash = Hash.new 0
      @subject_facet_hash = Hash.new 0
      @date_facet_hash = Hash.new 0
      @register_facet_hash = Hash.new 0

      entry_id_set = Set.new

      query = SolrQuery.new
      @query = SolrQuery.new

      # Replace all spaces in a search term with asterisks
      search_term2 = @search_term.downcase.gsub(/ /, '*')

      puts entry_id_set.length

      # ENTRIES: Get the matching entry ids and facets
      if sub != 'group' or sub != 'person'or sub != 'place'
        # if the search has come from the subjects browse, limit to searching for the subject
        if sub == 'subject'
          q = 'has_model_ssim:Entry AND subject_search:"' + @search_term.downcase + '"'
        else
          q = "has_model_ssim:Entry AND (entry_type_search:*#{search_term2}* or section_type_search:*#{search_term2}* or summary_search:*#{search_term2}* or marginalia_search:*#{search_term2}* or subject_search:*#{search_term2}* or language_search:*#{search_term2}* or note_search:*#{search_term2}* or editorial_note_search:*#{search_term2}* or is_referenced_by_search:*#{search_term2}*)"
        end
        fq = filter_query
        facets = facet_fields
        num = count_query(q)
        unless num == 0
          q_result = query.solr_query(q, 'id', num, nil, 0, true, -1, 'index', facets, fq)
          facet_hash(q_result)
          entry_id_set.merge(q_result['response']['docs'].map { |e| e['id'] })
        end
      end

      # Filter query for the entry (section types and subject facets), used when looping through the entries
      fq_entry = filter_query

      # PEOPLE/GROUPS: Get the matching entry ids and facets
      if sub != 'subject'and sub != 'place'
        # if the search has come from the people or group browse, limit to searching for group or person
        if sub == 'group' or sub == 'person'
          q = 'has_model_ssim:RelatedAgent AND person_same_as_search:"' + @search_term.downcase + '"'
        else
          q = "has_model_ssim:RelatedAgent AND (person_same_as_search:*#{search_term2}* or person_role_search:*#{search_term2}* or person_descriptor_search:*#{search_term2}* or person_descriptor_same_as_search:*#{search_term2}* or person_note_search:*#{search_term2}* or person_same_as_search:*#{search_term2}* or person_related_place_search:*#{search_term2}* or person_related_person_search:*#{search_term2}*)"
        end
        num = count_query(q)
        unless num == 0
          q_result = query.solr_query(q, 'relatedAgentFor_ssim', num)
          q_result['response']['docs'].map do |result|
            result['relatedAgentFor_ssim'].each do |relatedagent|
              q_result2 = query.solr_query("id:#{relatedagent}", 'id,has_model_ssim', 1, nil, 0, true, -1, 'index', facets, fq_entry)
              q_result2['response']['docs'].map do |entry|
                unless q_result2['response']['numFound'] == 0
                  # Check that the model is Entry
                  unless entry['has_model_ssim'] != ['Entry']
                    unless entry_id_set.include? entry['id']
                      add_facet_to_hash(q_result2)
                    end
                    entry_id_set << entry['id']
                  end
                end
              end
            end
          end
        end
      end

      # PLACE: Get the matching entry ids and facets
      if sub != 'group' and sub != 'person' and sub != 'subject'
        # if the search has come from the places browse, limit to searching for places
        if sub == 'place'
          q = 'has_model_ssim:RelatedPlace AND place_same_as_search:"' + @search_term.downcase + '"'
        else
          q = "has_model_ssim:RelatedPlace AND (place_same_as_search:*#{search_term2}* or place_role_search:*#{search_term2}* or place_type_search:*#{search_term2}* or place_note_search:*#{search_term2}* or place_as_written_search:*#{search_term2}*)"
        end
        facets = facet_fields
        num = count_query(q)
        unless num == 0
          q_result = query.solr_query(q, 'relatedPlaceFor_ssim', num)
          q_result['response']['docs'].map do |result|
            q_result2 = query.solr_query("id:#{result['relatedPlaceFor_ssim'][0]}", 'id,has_model_ssim', 1, nil, 0, true, -1, 'index', facets, fq_entry)
            q_result2['response']['docs'].map do |entry|
              unless q_result2['response']['numFound'] == 0
                # Check that the model is Entry
                unless entry['has_model_ssim'] != ['Entry']
                  unless entry_id_set.include? entry['id']
                    add_facet_to_hash(q_result2)
                  end
                  entry_id_set << entry['id']
                end
              end
            end
          end
        end
      end

      # SINGLE DATES: Get the matching entry ids and facets
      if sub != 'group' and sub != 'person' and sub != 'subject' and sub != 'place'
        q = "has_model_ssim:SingleDate AND date_tesim:*#{search_term2}*"
        facets = facet_fields
        num = count_query(q)
        unless num == 0
          q_result = query.solr_query(q, 'dateFor_ssim', num)
          q_result['response']['docs'].map do |res|
            res['dateFor_ssim'].each do |single_date|
              # from the entry dates, get the entry ids
              query.solr_query("id:#{single_date}", "entryDateFor_ssim", num)['response']['docs'].map do |result|
                q_result2 = query.solr_query("id:#{result['entryDateFor_ssim'][0]}", 'id', 1, nil, 0, true, -1, 'index', facets,fq_entry)
                unless q_result2['response']['numFound'] == 0
                  unless entry_id_set.include? q_result2['response']['docs'][0]['id']
                    #add facets
                    add_facet_to_hash(q_result2)
                  end
                  entry_id_set << q_result2['response']['docs'][0]['id']
                end
              end
            end
          end

        # ENTRY DATES: Get the matching entry ids (no facets needed for entry dates)
          q = "has_model_ssim:EntryDate AND (date_note_tesim:*#{search_term2}*"
          num = count_query(q)
          unless num == 0
            q_result = query.solr_query(q, 'entryDateFor_ssim', num, nil, 0, nil, nil, nil, nil, fq_entry)
            entry_id_set.merge(q_result['response']['docs'].map { |e| e['entryDateFor_ssim'][0] })
          end
        end
      end

      #Sort all of the hashes
      @section_type_facet_hash = @section_type_facet_hash.sort.to_h
      @person_same_as_facet_hash = @person_same_as_facet_hash.sort.to_h
      @place_same_as_facet_hash = @place_same_as_facet_hash.sort.to_h
      @subject_facet_hash = @subject_facet_hash.sort.to_h
      @date_facet_hash = @date_facet_hash.sort.to_h
      @register_facet_hash = @register_facet_hash.sort.to_h

      # This variable is used on the display page
      @number_of_rows = entry_id_set.size

      # Get the data for one page only, e.g. 10 rows
      entry_id_array = entry_id_set.to_a.slice((@page - 1) * @rows_per_page, @rows_per_page)

      # Iterate over the 10 (or less) entries and get all the data to display
      # Also highlight the search term
      entry_id_array.each do |entry_id|
        q = "id:#{entry_id}"

        fl = "entry_type_facet_ssim, section_type_facet_ssim, summary_tesim, marginalia_tesim, language_facet_ssim, subject_facet_ssim, note_tesim, editorial_note_tesim, is_referenced_by_tesim"

        query.solr_query(q, fl, 1)['response']['docs'].map do |result|
          # Display all the text if not 'matched records'
          @match_term = @search_term
          if @match_term == '' || @display_type == 'full display' || @display_type == 'summary' then
            @match_term = '.*'
          end

          # Build up the element_array with the entry_id, etc
          @element_array = []
          @element_array << entry_id
          get_entry_and_folio_details(entry_id)
          @element_array << get_element(result['entry_type_facet_ssim'])
          @element_array << get_element(result['section_type_facet_ssim'])
          @element_array << get_element(result['summary_tesim'])
          @element_array << get_element(result['marginalia_tesim'])
          @element_array << get_element(result['language_facet_ssim'])
          @element_array << get_element(result['subject_facet_ssim'])
          @element_array << get_element(result['note_tesim'])
          @element_array << get_element(result['editorial_note_tesim'])
          @element_array << get_element(result['is_referenced_by_tesim'])
          get_places(entry_id, search_term2)
          get_people(entry_id, search_term2)
          get_dates(entry_id, search_term2)
          @partial_list_array << @element_array
        end
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end


  def get_dates(entry_id, search_term2)

    begin

      # entry date
      query = SolrQuery.new
      fl = 'id, date_note_tesim, date_role_facet_ssim'
      fl_single = 'id, date_tesim,date_type_tesim, date_certainty_tesim'
      tmp_array = []

      if @display_type == 'matched records'
        q = "entryDateFor_ssim:#{entry_id} AND (date_note_search:*#{search_term2}* OR date_role_search:*#{search_term2}*)"
        num = query.solr_query(q,'id',0)['response']['numFound'].to_i
        if num == 0
          q = "entryDateFor_ssim:#{entry_id}"
        end
        query.solr_query(q, fl, 1)['response']['docs'].map do |result|
          date_array = []
          date_role_string = result['date_role_facet_ssim']
          date_note_string = result['date_note_tesim']
          #single dates
          q = "dateFor_ssim:#{result['id']} AND (date_certainty_tesim:*#{search_term2}* OR date_tesim:*#{search_term2}*)"
          num = query.solr_query(q,'id',0)['response']['numFound'].to_i
          if num == 0
            q = "dateFor_ssim:#{result['id']}"
          end
          query.solr_query(q, fl_single,num)['response']['docs'].map do |result2|
            date_array << result2
          end
          tmp_array << get_date_string(date_role_string,date_note_string,date_array)
          if tmp_array[0] == '' then tmp_array = [] end
        end
      else
        q = "entryDateFor_ssim:#{entry_id}"
        #date_note_string = ''
        date_role_string = ''
        date_note_string = ''
        # entry dates
        num = query.solr_query(q,'id',0)['response']['numFound'].to_i
        query.solr_query("entryDateFor_ssim:#{entry_id}", fl, num)['response']['docs'].map do |result|
          date_role_string = result['date_role_facet_ssim']
          date_note_string = result['date_note_tesim']
          date_array = []
          #single dates
          entry_id2 = result['id']
          q = "dateFor_ssim:#{entry_id2}"
          num = query.solr_query(q,'id',0)['response']['numFound'].to_i
          query.solr_query(q, fl_single,num)['response']['docs'].map do |result2|
            date_array << result2
          end
          tmp_array << get_date_string(date_role_string,date_note_string,date_array)
        end
      end

      @element_array << tmp_array

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Helper method for getting the dates data
  def get_date_string(
      date_role_string,
      date_note_string,
      date_array)

    begin
    date_string = ''
    unless date_role_string.nil? or date_role_string == ['unknown']
      date_string += "#{get_element(date_role_string,true).capitalize}: "
    end
    unless date_array.nil? or date_array == []
      date_array.each do | result |
        if result['date_type_tesim'] != nil
          if result['date_type_tesim'].join == 'single'
            date_string += get_element(result['date_tesim'],true)
            date_string += " (#{get_element(result['date_certainty_tesim'],true)})"
          elsif result['date_type_tesim'].join == 'start'
            date_string += get_element(result['date_tesim'])
            date_string += " (#{get_element(result['date_certainty_tesim'],true)}) - "
          elsif result['date_type_tesim'].join == 'end'
            date_string += get_element(result['date_tesim'])
            date_string += " (#{get_element(result['date_certainty_tesim'],true)})"
          end
        else
          date_string += get_element(result['date_tesim'],true)
          date_string += " (#{get_element(result['date_certainty_tesim'],true)})"
        end
      end
    end
    unless date_note_string.nil?
      unless date_string.end_with? ': '
        date_string += '; Note: '
      end
      date_string += "#{get_element(date_note_string,true).capitalize}"
    end
    # This should only happen with matched records, where there is only a role; we do not want to show this
    if date_string.end_with? ': '
      date_string = ''
    end
    date_string
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  # Get the place data from solr for a particular entry_id and search term (see above method call)
  def get_places(entry_id, search_term2)

    begin
      q = "relatedPlaceFor_ssim:#{entry_id} "
      if @display_type == 'matched records'
        q = "relatedPlaceFor_ssim:#{entry_id} AND (place_as_written_search:*#{search_term2}* or place_role_search:*#{search_term2}* or place_type_search:*#{search_term2}* or place_note_search:*#{search_term2}* or place_same_as_search:*#{search_term2}*)"
      end
      fl = 'id, place_as_written_tesim, place_role_facet_ssim, place_type_facet_ssim, place_note_tesim, place_same_as_facet_ssim'

      #place_note_string = ''
      temp_array = []

      SolrQuery.new.solr_query(q, fl, 1000)['response']['docs'].map do |result|
        place_string = get_place_string(
        result['place_as_written_tesim'],
        result['place_role_facet_ssim'],
        result['place_type_facet_ssim'],
        result['place_same_as_facet_ssim']
        )
        temp_array << place_string
      end

      @element_array << temp_array

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Get the person data from solr for a particular entry_id and search term (see above method call)
  def get_people(entry_id, search_term2)

    begin

      q = "relatedAgentFor_ssim:#{entry_id}"
      if @display_type == 'matched records'
        q = "relatedAgentFor_ssim:#{entry_id} AND (person_as_written_search:*#{search_term2}* or person_role_search:*#{search_term2}* or person_descriptor_search:*#{search_term2}* or person_descriptor_same_as_search:*#{search_term2}* or person_note_search:*#{search_term2}* or person_same_as_search:*#{search_term2}* or person_related_place_search:*#{search_term2}* or person_related_person_search:*#{search_term2}*)"
      end
      fl = 'id, person_as_written_tesim, person_role_facet_ssim, person_descriptor_facet_ssim, person_descriptor_as_written_tesim, person_note_tesim, person_same_as_facet_ssim, person_related_place_tesim, person_related_person_tesim'

      # not currently including person_descriptor_as_written and person_note
      temp_array = []

      SolrQuery.new.solr_query(q, fl, 1000)['response']['docs'].map do |result|
        person_string = get_person_string(
            result['person_as_written_tesim'],
            result['person_role_facet_ssim'],
            result['person_descriptor_facet_ssim'],
            result['person_same_as_facet_ssim'],
            result['person_related_place_tesim'],
            result['person_related_person_tesim'],
            result['person_note_tesim']
        )
        temp_array << person_string
      end

      temp_array = temp_array.sort

      # Put testator at beginning
      temp_array.each_with_index do |a,index|
        if a.start_with? 'Testator'
          # Remove testators from current position and insert at beginning
          temp_array.insert(0,temp_array.delete_at(index))
        end
      end

      @element_array << temp_array

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Helper method for getting the person / group data
  def get_person_string(
      person_as_written_string,
      person_role_string,
      person_descriptor_string,
      person_same_as_string,
      person_related_place_string,
      person_related_person_string,
      person_note_string)

    person_string = ''
    # In the Register 12 data, where an exact match to the roles vocab was not found, a note was used
    # Use this note if present where role is 'unknown'
    unless person_role_string.nil?
      if person_role_string == ['unknown']
        unless person_note_string.nil? and person_note_string.include? 'Role: '
          person_string += "#{get_element(person_note_string,true).gsub('Role: ','').capitalize}: "
        end
      else
        person_string += "#{get_element(person_role_string,true).capitalize}: "
      end
    end
    if person_same_as_string.nil?
      unless person_as_written_string.nil?
        person_string += get_element(person_as_written_string,true)
      end
      unless person_descriptor_string.nil? or person_descriptor_string == ['unknown']
        person_string += " (#{get_element(person_descriptor_string,true)})"
      end
    else
      person_string += get_element(person_same_as_string)
      unless person_descriptor_string.nil? or person_descriptor_string == ['unknown']
        person_string += " (#{get_element(person_descriptor_string,true)})"
      end
      unless person_as_written_string.nil?
        person_string += "; written as #{get_element(person_as_written_string,true)}"
      end
    end
    unless person_related_place_string.nil?
      person_string += "; related places: #{get_element(person_related_place_string,true)}"
    end
    unless person_related_person_string.nil?
      person_string += "; related people: #{get_element(person_related_person_string,true)}"
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
    place_string = ''
    unless place_role_string.nil? or place_role_string == ['unknown']
      place_string += "#{get_element(place_role_string,true).capitalize}: "
    end
    if place_same_as_string.nil?
      unless place_as_written_string.nil?
        place_string += get_element(place_as_written_string,true)
      end
      unless place_type_string.nil? or place_type_string == ['unknown']
        place_string += " (#{get_element(place_type_string,true)})"
      end
    else
      place_string += get_element(place_same_as_string)
      unless place_type_string.nil? or place_type_string == ['unknown']
        place_string += " (#{get_element(place_type_string,true)})"
      end
      unless place_as_written_string.nil?
        place_string += "; written as #{get_element(place_as_written_string,true)}"
      end
    end
    place_string

  end

  # This method uses the entry_id to get the title of the search result, i.e. 'Register Folio Entry' and folio_id
  def get_entry_and_folio_details(entry_id)

    begin

      # Get the entry_no and folio_id for the entry_id
      SolrQuery.new.solr_query('id:' + entry_id, 'entry_no_tesim, entry_folio_facet_ssim, folio_ssim', 1)['response']['docs'].map do |result|
        @element_array << "#{result['entry_folio_facet_ssim'].join} entry #{result['entry_no_tesim'].join}"
        @element_array << result['folio_ssim'].join

      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Helper method to check if terms match the search term and if so, whether to put a comma in front of it
  # i.e. this is required if it is not the first term in the string
  def get_element(input_array,return_string=nil)

    begin

      str = ''
      is_match = false

      if input_array != nil

        # Iterate over the input array and add columns between elements
        input_array.each do |t|
          if t.match(/#{@match_term}/i)
            is_match = true
          end
          if str != '' then
            str = str + ', '
          end
          str = str + t
        end

        # The following code highlights text which matches the search_term
        # It highlights all combinations, e.g. 'york', 'York', 'YORK', 'paul young', 'paul g', etc
        if is_match == true and @search_term != ''
          # Replace all spaces with '.*' so that it searches for all characters in between text, e.g. 'paul y' will find 'paul young'
          temp = @search_term.gsub(/\s+/, '.*');
          str = str.gsub(/#{temp}/i) do |term|
            "<span class=\'highlight_text\'>#{term}</span>"
          end
        elsif is_match == false and @search_term != '' and return_string.nil?
          str = ''
        end

      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

    return str
  end

  # This method gets all the solr data from an entry into a db_entry database object
  # We did this because getting the data using activeFedora is too slow
  # It is used to display the data on the view pages and when a user is editing the entry form
  # but activeFedora is used when the user actually saves the form (so that the data goes into Fedora)
  # Note that although we are using an object which corresponds to the database tables, we don't actually populate the tables with any data
  # It appears that rails requires the tables to be there even if you don't use them in order to create a database object
  def get_solr_data(db_entry)

    begin

      SolrQuery.new.solr_query('id:' + db_entry.entry_id, 'entry_no_tesim, entry_type_tesim, section_type_tesim, continues_on_tesim, summary_tesim, marginalia_tesim, language_tesim, subject_tesim, note_tesim, editorial_note_tesim, is_referenced_by_tesim', 1)['response']['docs'].map do |result|

        if result['entry_no_tesim'] != nil

          db_entry.id = 1

          db_entry.entry_no = result['entry_no_tesim'].join()

          entry_type_list = result['entry_type_tesim'];

          if entry_type_list != nil
            entry_type_list.each do |tt|
              db_entry_type = DbEntryType.new
              db_entry_type.name = tt
              db_entry.db_entry_types << db_entry_type
            end
          end

          section_type_list = result['section_type_tesim'];

          if section_type_list != nil
            section_type_list.each do |tt|
              db_section_type = DbSectionType.new
              db_section_type.name = tt
              db_entry.db_section_types << db_section_type
            end
          end

          if result['continues_on_tesim'] != nil
            db_entry.continues_on = result['continues_on_tesim'].join()
          end

          summary = result['summary_tesim']

          if summary != nil
            db_entry.summary = summary.join()
          end

          marginalium_list = result['marginalia_tesim'];

          if marginalium_list != nil
            marginalium_list.each do |tt|
              db_marginalium = DbMarginalium.new
              db_marginalium.name = tt
              db_entry.db_marginalia << db_marginalium
            end
          end

          language_list = result['language_tesim'];

          if language_list != nil
            language_list.each do |tt|
              db_language = DbLanguage.new
              db_language.name = tt
              db_entry.db_languages << db_language
            end
          end

          subject_list = result['subject_tesim'];

          if subject_list != nil
            subject_list.each do |tt|
              db_subject = DbSubject.new
              db_subject.name = tt
              db_entry.db_subjects << db_subject
            end
          end

          note_list = result['note_tesim'];

          if note_list != nil
            note_list.each do |tt|
              db_note = DbNote.new
              db_note.name = tt
              db_entry.db_notes << db_note
            end
          end

          editorial_note_list = result['editorial_note_tesim'];

          if editorial_note_list != nil
            editorial_note_list.each do |tt|
              db_editorial_note = DbEditorialNote.new
              db_editorial_note.name = tt
              db_entry.db_editorial_notes << db_editorial_note
            end
          end

          is_referenced_by_list = result['is_referenced_by_tesim'];

          if is_referenced_by_list != nil
            is_referenced_by_list.each do |tt|
              db_is_referenced_by = DbIsReferencedBy.new
              db_is_referenced_by.name = tt
              db_entry.db_is_referenced_bys << db_is_referenced_by
            end
          end

          SolrQuery.new.solr_query('has_model_ssim:EntryDate AND entryDateFor_ssim:' + db_entry.entry_id, 'id, date_role_tesim, date_note_tesim', 100)['response']['docs'].map do |result|

            date_id = result['id'];

            if date_id != nil

              db_entry_date = DbEntryDate.new

              db_entry_date.date_id = date_id

              db_entry_date.id = 1

              SolrQuery.new.solr_query('has_model_ssim:SingleDate AND dateFor_ssim:' + date_id, 'id, date_tesim, date_type_tesim, date_certainty_tesim', 100)['response']['docs'].map do |result2|

                single_date_id = result2['id'];

                if single_date_id != nil

                  db_single_date = DbSingleDate.new

                  db_single_date.single_date_id = single_date_id

                  db_single_date.id = 1 #single_date_id.gsub(/test:/, '').to_i

                  date_certainty_list = result2['date_certainty_tesim'];

                  if date_certainty_list != nil
                    date_certainty_list.each do |tt|
                      db_date_certainty = DbDateCertainty.new
                      db_date_certainty.name = tt
                      db_single_date.db_date_certainties << db_date_certainty
                    end
                  end

                  date = result2['date_tesim']

                  if date != nil
                    db_single_date.date = date.join()
                  end

                  date_type = result2['date_type_tesim']

                  if date_type != nil
                    db_single_date.date_type = date_type.join()
                  end

                  db_entry_date.db_single_dates << db_single_date
                end
              end

              date_role = result['date_role_tesim']

              if date_role != nil
                db_entry_date.date_role = date_role.join()
              end

              date_note = result['date_note_tesim']

              if date_note != nil
                db_entry_date.date_note = date_note.join()
              end

              db_entry.db_entry_dates << db_entry_date
            end
          end

          SolrQuery.new.solr_query('has_model_ssim:RelatedPlace AND relatedPlaceFor_ssim:"' + db_entry.entry_id + '"', 'id, place_same_as_tesim, place_as_written_tesim, place_role_tesim, place_type_tesim, place_note_tesim', 100)['response']['docs'].map do |result|

            related_place_id = result['id'];

            if related_place_id != nil

              db_related_place = DbRelatedPlace.new

              db_related_place.place_id = related_place_id

              db_related_place.id = 1 #related_place_id.gsub(/test:/, '').to_i

              place_same_as = result['place_same_as_tesim']

              if place_same_as != nil
                db_related_place.place_same_as = place_same_as.join()
              end

              place_as_written_list = result['place_as_written_tesim'];

              if place_as_written_list != nil
                place_as_written_list.each do |tt|
                  db_place_as_written = DbPlaceAsWritten.new
                  db_place_as_written.name = tt
                  db_related_place.db_place_as_writtens << db_place_as_written
                end
              end

              place_role_list = result['place_role_tesim'];

              if place_role_list != nil
                place_role_list.each do |tt|
                  db_place_role = DbPlaceRole.new
                  db_place_role.name = tt
                  db_related_place.db_place_roles << db_place_role
                end
              end

              place_type_list = result['place_type_tesim'];

              if place_type_list != nil
                place_type_list.each do |tt|
                  db_place_type = DbPlaceType.new
                  db_place_type.name = tt
                  db_related_place.db_place_types << db_place_type
                end
              end

              place_note_list = result['place_note_tesim'];

              if place_note_list != nil
                place_note_list.each do |tt|
                  db_place_note = DbPlaceNote.new
                  db_place_note.name = tt
                  db_related_place.db_place_notes << db_place_note
                end
              end

              db_entry.db_related_places << db_related_place
            end
          end

          SolrQuery.new.solr_query('has_model_ssim:RelatedAgent AND relatedAgentFor_ssim:"' + db_entry.entry_id + '"', 'id, person_same_as_tesim, person_group_tesim, person_gender_tesim, person_as_written_tesim, person_role_tesim, person_descriptor_tesim, person_descriptor_as_written_tesim, person_note_tesim, person_related_place_tesim, person_related_person_tesim', 100)['response']['docs'].map do |result|

            related_agent_id = result['id'];

            if related_agent_id != nil

              db_related_agent = DbRelatedAgent.new

              db_related_agent.person_id = related_agent_id

              #related_agent_id.unpack('b*').each do | o | db_related_agent.id = o.to_i(2) end
              db_related_agent.id = 1

              person_same_as = result['person_same_as_tesim']

              if person_same_as != nil
                db_related_agent.person_same_as = person_same_as.join()
              end

              person_group = result['person_group_tesim']

              if person_group != nil
                db_related_agent.person_group = person_group.join()
              end

              person_gender = result['person_gender_tesim']

              if person_gender != nil
                db_related_agent.person_gender = person_gender.join()
              end

              person_as_written_list = result['person_as_written_tesim'];

              if person_as_written_list != nil
                person_as_written_list.each do |tt|
                  db_person_as_written = DbPersonAsWritten.new
                  db_person_as_written.name = tt
                  db_related_agent.db_person_as_writtens << db_person_as_written
                end
              end

              person_role_list = result['person_role_tesim'];

              if person_role_list != nil
                person_role_list.each do |tt|
                  db_person_role = DbPersonRole.new
                  db_person_role.name = tt
                  db_related_agent.db_person_roles << db_person_role
                end
              end

              person_descriptor_list = result['person_descriptor_tesim'];

              if person_descriptor_list != nil
                person_descriptor_list.each do |tt|
                  db_person_descriptor = DbPersonDescriptor.new
                  db_person_descriptor.name = tt
                  db_related_agent.db_person_descriptors << db_person_descriptor
                end
              end

              person_descriptor_as_written_list = result['person_descriptor_as_written_tesim'];

              if person_descriptor_as_written_list != nil
                person_descriptor_as_written_list.each do |tt|
                  db_person_descriptor_as_written = DbPersonDescriptorAsWritten.new
                  db_person_descriptor_as_written.name = tt
                  db_related_agent.db_person_descriptor_as_writtens << db_person_descriptor_as_written
                end
              end

              person_note_list = result['person_note_tesim'];

              if person_note_list != nil
                person_note_list.each do |tt|
                  db_person_note = DbPersonNote.new
                  db_person_note.name = tt
                  db_related_agent.db_person_notes << db_person_note
                end
              end

              person_related_place_list = result['person_related_place_tesim'];

              if person_related_place_list != nil
                person_related_place_list.each do |tt|
                  db_person_related_place = DbPersonRelatedPlace.new
                  db_person_related_place.name = tt
                  db_related_agent.db_person_related_places << db_person_related_place
                end
              end

              person_related_person_list = result['person_related_person_tesim'];

              if person_related_person_list != nil
                person_related_person_list.each do |tt|
                  db_person_related_person = DbPersonRelatedPerson.new
                  db_person_related_person.name = tt
                  db_related_agent.db_person_related_people << db_person_related_person
                end
              end

              db_entry.db_related_agents << db_related_agent
            end
          end
        end
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Gets the list of entries (id, entry_no) in the specific folio
  def get_entry_list(folio_id)

    begin

      entry_list = []

      SolrQuery.new.solr_query("folio_ssim:#{folio_id}", 'id, entry_no_tesim', 1800, 'entry_no_si asc')['response']['docs'].map do |result|
        element_list = []
        id = result['id']
        entry_no = result['entry_no_tesim'].join
        element_list << id
        element_list << entry_no
        entry_list << element_list
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

    return entry_list

  end

  # return the numRecords from a solr query
  def count_query(query)
    @query.solr_query(query, 'id', 0)['response']['numFound'].to_i
  end

  # return the facet fields
  def facet_fields
    ['section_type_facet_ssim', 'subject_facet_ssim', 'entry_person_same_as_facet_ssim', 'entry_place_same_as_facet_ssim', 'entry_date_facet_ssim','entry_register_facet_ssim']
  end

  # build the filter query for solr
  def filter_query(model=nil)
    fq = Array.new
        if model.nil?
          unless @section_type_facet.nil?
            fq << "section_type_facet_ssim:\"#{@section_type_facet}\""
          end
          unless @subject_facet.nil?
            fq << "subject_facet_ssim:\"#{@subject_facet}\""
          end
          unless @register_facet.nil?
            fq << "entry_register_facet_ssim:\"#{@register_facet}\""
          end
          unless @person_same_as_facet.nil?
            fq << "entry_person_same_as_facet_ssim:\"#{@person_same_as_facet}\""
          end
          unless @place_same_as_facet.nil?
            fq << "entry_place_same_as_facet_ssim:\"#{@place_same_as_facet}\""
          end
          unless @date_facet.nil?
            fq << "entry_date_facet_ssim:#{@date_facet}*"
          end
        else
          unless @date_facet.nil?
            fq << "date_facet_ssim:#{@date_facet}*"
          end
        end
    if fq.empty?
      fq = nil
    end
    fq
  end

  def facet_hash(solr_result)
    unless solr_result['facet_counts']['facet_fields']['subject_facet_ssim'].nil?
      @subject_facet_hash = Hash[*solr_result['facet_counts']['facet_fields']['subject_facet_ssim'].flatten(1)]
    end
    unless solr_result['facet_counts']['facet_fields']['section_type_facet_ssim'].nil?
      @section_type_facet_hash = Hash[*solr_result['facet_counts']['facet_fields']['section_type_facet_ssim'].flatten(1)]
    end
    unless solr_result['facet_counts']['facet_fields']['entry_person_same_as_facet_ssim'].nil?
      @person_same_as_facet_hash = Hash[*solr_result['facet_counts']['facet_fields']['entry_person_same_as_facet_ssim'].flatten(1)]
    end
    unless solr_result['facet_counts']['facet_fields']['entry_place_same_as_facet_ssim'].nil?
      @place_same_as_facet_hash = Hash[*solr_result['facet_counts']['facet_fields']['entry_place_same_as_facet_ssim'].flatten(1)]
    end
    unless solr_result['facet_counts']['facet_fields']['entry_date_facet_ssim'].nil?
      @date_facet_hash = Hash[*solr_result['facet_counts']['facet_fields']['entry_date_facet_ssim'].flatten(1)]
    end
    unless solr_result['facet_counts']['facet_fields']['entry_register_facet_ssim'].nil?
      @register_facet_hash = Hash[*solr_result['facet_counts']['facet_fields']['entry_register_facet_ssim'].flatten(1)]
    end
  end

  def add_facet_to_hash(solr_result)
    unless solr_result['facet_counts']['facet_fields']['subject_facet_ssim'].nil?
      solr_result['facet_counts']['facet_fields']['subject_facet_ssim'].each_with_index do |st, index|
        if index.even? == true
          if @subject_facet_hash[st]
            @subject_facet_hash[st] += solr_result['facet_counts']['facet_fields']['subject_facet_ssim'][index+1]
          else
            @subject_facet_hash[st] = solr_result['facet_counts']['facet_fields']['subject_facet_ssim'][index+1]
          end
        end
      end
    end
    unless solr_result['facet_counts']['facet_fields']['section_type_facet_ssim'].nil?
      solr_result['facet_counts']['facet_fields']['section_type_facet_ssim'].each_with_index do |st, index|
        if index.even? == true
          if @section_type_facet_hash[st]
            @section_type_facet_hash[st] += solr_result['facet_counts']['facet_fields']['section_type_facet_ssim'][index+1]
          else
            @section_type_facet_hash[st] = solr_result['facet_counts']['facet_fields']['section_type_facet_ssim'][index+1]
          end
        end
      end
    end
    unless solr_result['facet_counts']['facet_fields']['entry_person_same_as_facet_ssim'].nil?
      solr_result['facet_counts']['facet_fields']['entry_person_same_as_facet_ssim'].each_with_index do |st, index|
        if index.even? == true
          if @person_same_as_facet_hash[st]
            @person_same_as_facet_hash[st] += solr_result['facet_counts']['facet_fields']['entry_person_same_as_facet_ssim'][index+1]
          else
            @person_same_as_facet_hash[st] = solr_result['facet_counts']['facet_fields']['entry_person_same_as_facet_ssim'][index+1]
          end
        end
      end
    end
    unless solr_result['facet_counts']['facet_fields']['entry_place_same_as_facet_ssim'].nil?
      solr_result['facet_counts']['facet_fields']['entry_place_same_as_facet_ssim'].each_with_index do |st, index|
        if index.even? == true
          if @place_same_as_facet_hash[st]
            @place_same_as_facet_hash[st] += solr_result['facet_counts']['facet_fields']['entry_place_same_as_facet_ssim'][index+1]
          else
            @place_same_as_facet_hash[st] = solr_result['facet_counts']['facet_fields']['entry_place_same_as_facet_ssim'][index+1]
          end
        end
      end
    end
    unless solr_result['facet_counts']['facet_fields']['entry_date_facet_ssim'].nil?
      solr_result['facet_counts']['facet_fields']['entry_date_facet_ssim'].each_with_index do |st, index|
        if index.even? == true
          if @date_facet_hash[st]
            @date_facet_hash[st] += solr_result['facet_counts']['facet_fields']['entry_date_facet_ssim'][index+1]
          else
            @date_facet_hash[st] = solr_result['facet_counts']['facet_fields']['entry_date_facet_ssim'][index+1]
          end
        end
      end
    end
    unless solr_result['facet_counts']['facet_fields']['entry_register_facet_ssim'].nil?
      solr_result['facet_counts']['facet_fields']['entry_register_facet_ssim'].each_with_index do |st, index|
        if index.even? == true
          if @register_facet_hash[st]
            @register_facet_hash[st] += solr_result['facet_counts']['facet_fields']['entry_register_facet_ssim'][index+1]
          else
            @register_facet_hash[st] = solr_result['facet_counts']['facet_fields']['entry_register_facet_ssim'][index+1]
          end
        end
      end
    end
  end
end

# Writes error message to the log
def log_error(method, file, error)
  time = ''
  # Only add time for development log because production already outputs timestamp
  if Rails.env == 'development'
    time = Time.now.strftime('[%d/%m/%Y %H:%M:%S] ').to_s
  end
  logger.error "#{time}EXCEPTION IN #{file}, method='#{method}' [#{error}]"
end
