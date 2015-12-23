module Solr

  def set_search_result_arrays

    begin

      @section_type_facet_hash = Hash.new 0
      @person_as_written_facet_hash = Hash.new 0
      @place_as_written_facet_hash = Hash.new 0
      @subject_facet_hash = Hash.new 0

      section_type_word_array = []
      subject_word_array = []
      person_as_written_word_array = []
      place_as_written_word_array = []

      search_term2 = @search_term.downcase.gsub(/ /, '*')

      # Get the matching entry ids (from the entries)
      q = "has_model_ssim:Entry AND (entry_type_search:*#{search_term2}* or section_type_search:*#{search_term2}* or summary_search:*#{search_term2}* or marginalia_search:*#{search_term2}* or subject_search:*#{search_term2}* or language_search:*#{search_term2}* or note_search:*#{search_term2}* or editorial_note_search:*#{search_term2}* or is_referenced_by_search:*#{search_term2}*)"

      entry_id_set = Set.new

      SolrQuery.new.solr_query(q, "id", 1000, nil, 0)['response']['docs'].map do |result|
        entry_id_set << result['id']
      end

      # Get the matching entry ids (from the people)
      q = "has_model_ssim:RelatedAgent AND (person_as_written_search:*#{search_term2}* or person_role_search:*#{search_term2}* or person_descriptor_search:*#{search_term2}* or person_descriptor_as_written_search:*#{search_term2}* or person_note_search:*#{search_term2}* or person_same_as_search:*#{search_term2}* or person_related_place_search:*#{search_term2}* or person_related_person_search:*#{search_term2}*)"

      SolrQuery.new.solr_query(q, "relatedAgentFor_ssim", 1000, nil, 0)['response']['docs'].map do |result|
        result['relatedAgentFor_ssim'].each do |related_agent|
          # Check that the relatedAgentFor_ssim is an Entry (as can be a RelatedAgent)
          SolrQuery.new.solr_query("id:#{related_agent}", "has_model_ssim", 1000, nil, 0)['response']['docs'].map do |result2|
            if result2['has_model_ssim'].join == 'Entry'
              entry_id_set << related_agent
            end
          end
        end
      end

      # Get the matching entry ids (from the places)
      q = "has_model_ssim:RelatedPlace AND (place_as_written_search:*#{search_term2}* or place_role_search:*#{search_term2}* or place_type_search:*#{search_term2}* or place_note_search:*#{search_term2}* or place_same_as_search:*#{search_term2}*)"

      SolrQuery.new.solr_query(q, "relatedPlaceFor_ssim", 1000, nil, 0)['response']['docs'].map do |result|
        result['relatedPlaceFor_ssim'].each do |related_place|
          # Check that the relatedPlaceFor_ssim is an Entry (as can be a RelatedPlace)
          SolrQuery.new.solr_query("id:#{related_place}", "has_model_ssim", 1000, nil, 0)['response']['docs'].map do |result2|
            if result2['has_model_ssim'].join == 'Entry'
              entry_id_set << related_place
            end
          end
        end
      end

      # Now we have all the entry ids iterate through and get the facets
      entry_id_set.each do |entry_id|

        local_section_type_word_array = []
        local_subject_word_array = []
        local_person_as_written_word_array = []
        local_place_as_written_word_array = []

        is_valid = true

        SolrQuery.new.solr_query("id:#{entry_id}", "section_type_new_tesim, subject_new_tesim", 1000, nil, 0)['response']['docs'].map do |result|

          # SECTION_TYPE FACET
          # Add all the section types to a local array
          # This local array is added to the facet array later on but only if this document is valid,
          # i.e. includes the facets chosen by the user
          if result['section_type_new_tesim'] != nil
            result['section_type_new_tesim'].each do |section_type|
              local_section_type_word_array << section_type
            end
          end

          # If a section_type_facet has been chosen and there isn't a match
          # # for this entry, the document isn't valid
          # If there is a match, the document is valid and the facet becomes the one chosen by the user
          if @section_type_facet != nil and @section_type_facet != ''
            if !local_section_type_word_array.include? @section_type_facet
              is_valid = false
            else
              local_section_type_word_array = [@section_type_facet]
            end
          end

          # SUBJECT FACET
          if result['subject_new_tesim'] != nil
            result['subject_new_tesim'].each do |subject|
              local_subject_word_array << subject
            end
          end

          if @subject_facet != nil and @subject_facet != ''
            if !local_subject_word_array.include? @subject_facet
              is_valid = false
            else
              local_subject_word_array = [@subject_facet]
            end
          end

          # PERSON_AS_WRITTEN FACET
          SolrQuery.new.solr_query("relatedAgentFor_ssim:#{entry_id}", "person_as_written_tesim", 1000, nil, 0)['response']['docs'].map do |result|
            if result['person_as_written_tesim'] != nil
              result['person_as_written_tesim'].each do |person_as_written|
                local_person_as_written_word_array << person_as_written
              end
            end
          end

          if @person_as_written_facet != nil and @person_as_written_facet != ''
            if !local_person_as_written_word_array.include? @person_as_written_facet
              is_valid = false
            else
              local_person_as_written_word_array = [@person_as_written_facet]
            end
          end

          # PLACE_AS_WRITTEN FACET
          SolrQuery.new.solr_query("relatedPlaceFor_ssim:#{entry_id}", "place_as_written_tesim", 1000, nil, 0)['response']['docs'].map do |result|
            if result['place_as_written_tesim'] != nil
              result['place_as_written_tesim'].each do |place_as_written_tesim|
                local_place_as_written_word_array << place_as_written_tesim
              end
            end
          end

          if @place_as_written_facet != nil and @place_as_written_facet != ''
            if !local_place_as_written_word_array.include? @place_as_written_facet
              is_valid = false
            else
              local_place_as_written_word_array = [@place_as_written_facet]
            end
          end

        end

        if is_valid == true
          section_type_word_array.concat local_section_type_word_array
          subject_word_array.concat local_subject_word_array
          person_as_written_word_array.concat local_person_as_written_word_array
          place_as_written_word_array.concat local_place_as_written_word_array
        else
          entry_id_set.delete(entry_id)
        end
      end

      # Sort the word arrays and create a hash with the facets and facet counts
      if section_type_word_array != nil
        section_type_word_array.sort.each do |word|
          @section_type_facet_hash[word] += 1
        end
      end

      if subject_word_array != nil
        subject_word_array.sort.each do |word|
          @subject_facet_hash[word] += 1
        end
      end

      if person_as_written_word_array != nil
        person_as_written_word_array.sort.each do |word|
          @person_as_written_facet_hash[word] += 1
        end
      end

      if place_as_written_word_array != nil
        place_as_written_word_array.sort.each do |word|
          @place_as_written_facet_hash[word] += 1
        end
      end

      # This is used on the display page
      @number_of_rows = entry_id_set.size

      # Get the data for one page only, e.g. 10 rows
      entry_id_array = entry_id_set.to_a.slice((@page - 1) * @rows_per_page, @rows_per_page)

      entry_id_array.each do |entry_id|

        q = "id:#{entry_id}"

        fl = "entry_type_new_tesim, section_type_new_tesim, summary_tesim, marginalia_tesim, language_new_tesim, subject_new_tesim, note_tesim, editorial_note_tesim, is_referenced_by_tesim"

        SolrQuery.new.solr_query(q, fl, 1)['response']['docs'].map do |result|

          @match_term = @search_term
          if @match_term == '' || @display_type == 'full display' || @display_type == 'summary' then
            @match_term = '.*'
          end

          @element_array = []
          @element_array << entry_id
          get_entry_and_folio_details(entry_id)
          @element_array << get_element(result['entry_type_new_tesim'])
          @element_array << get_element(result['section_type_new_tesim'])
          @element_array << get_element(result['summary_tesim'])
          @element_array << get_element(result['marginalia_tesim'])
          @element_array << get_element(result['language_new_tesim'])
          @element_array << get_element(result['subject_new_tesim'])
          @element_array << get_element(result['note_tesim'])
          @element_array << get_element(result['editorial_note_tesim'])
          @element_array << get_element(result['is_referenced_by_tesim'])
          get_places(entry_id, search_term2)
          get_people(entry_id, search_term2)
          @partial_list_array << @element_array
        end
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Get the place data from solr for a particular entry_id and search term
  def get_places(entry_id, search_term2)

    begin

      q = "relatedPlaceFor_ssim:#{entry_id} "
      if @display_type == 'matched records'
        q = "relatedPlaceFor_ssim:#{entry_id} AND (place_as_written_search:*#{search_term2}* or place_role_search:*#{search_term2}* or place_type_search:*#{search_term2}* or place_note_search:*#{search_term2}* or place_same_as_search:*#{search_term2}*)"
      end
      fl = 'id, place_as_written_tesim, place_role_new_tesim, place_type_new_tesim, place_note_tesim, place_same_as_new_tesim'

      place_as_written_string = ''
      place_role_string = ''
      place_type_string = ''
      place_note_string = ''
      place_same_as_string = ''

      SolrQuery.new.solr_query(q, fl, 10000)['response']['docs'].map do |result|
        place_as_written_string = place_as_written_string + get_place_or_person_string(result['place_as_written_tesim'], place_as_written_string)
        place_role_string = place_role_string + get_place_or_person_string(result['place_role_new_tesim'], place_role_string)
        place_type_string = place_type_string + get_place_or_person_string(result['place_type_new_tesim'], place_type_string)
        place_note_string = place_note_string + get_place_or_person_string(result['place_note_tesim'], place_note_string)
        place_same_as_string = place_same_as_string + get_place_or_person_string(result['place_same_as_new_tesim'], place_same_as_string)
      end

      @element_array << place_as_written_string
      @element_array << place_role_string
      @element_array << place_type_string
      @element_array << place_note_string
      @element_array << place_same_as_string

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Get the person data from solr for a particular entry_id and search term
  def get_people(entry_id, search_term2)

    begin

      q = "relatedAgentFor_ssim:#{entry_id}"
      if @display_type == 'matched records'
        q = "relatedAgentFor_ssim:#{entry_id} AND (person_as_written_search:*#{search_term2}* or person_role_search:*#{search_term2}* or person_descriptor_search:*#{search_term2}* or person_descriptor_as_written_search:*#{search_term2}* or person_note_search:*#{search_term2}* or person_same_as_search:*#{search_term2}* or person_related_place_search:*#{search_term2}* or person_related_person_search:*#{search_term2}*)"
      end
      fl = 'id, person_as_written_tesim, person_role_new_tesim, person_descriptor_new_tesim, person_descriptor_as_written_tesim, person_note_tesim, person_same_as_new_tesim, person_related_place_tesim, person_related_person_tesim'

      person_as_written_string = ''
      person_role_string = ''
      person_descriptor_string = ''
      person_descriptor_as_written_string = ''
      person_note_string = ''
      person_same_as_string = ''
      person_related_place_string = ''
      person_related_person_string = ''

      SolrQuery.new.solr_query(q, fl, 10000)['response']['docs'].map do |result|
        person_as_written_string = person_as_written_string + get_place_or_person_string(result['person_as_written_tesim'], person_as_written_string)
        person_role_string = person_role_string + get_place_or_person_string(result['person_role_new_tesim'], person_role_string)
        person_descriptor_string = person_descriptor_string + get_place_or_person_string(result['person_descriptor_new_tesim'], person_descriptor_string)
        person_descriptor_as_written_string = person_descriptor_as_written_string + get_place_or_person_string(result['person_descriptor_as_written_tesim'], person_descriptor_as_written_string)
        person_note_string = person_note_string + get_place_or_person_string(result['person_note_tesim'], person_note_string)
        person_same_as_string = person_same_as_string + get_place_or_person_string(result['person_same_as_new_tesim'], person_same_as_string)
        person_related_place_string = person_related_place_string + get_place_or_person_string(result['person_related_place_tesim'], person_related_place_string)
        person_related_person_string = person_related_person_string + get_place_or_person_string(result['person_related_person_tesim'], person_related_person_string)
      end

      @element_array << person_as_written_string
      @element_array << person_role_string
      @element_array << person_descriptor_string
      @element_array << person_descriptor_as_written_string
      @element_array << person_note_string
      @element_array << person_same_as_string
      @element_array << person_related_place_string
      @element_array << person_related_person_string

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Helper method for getting the person / place data
  def get_place_or_person_string(input_array, element_string)

    begin

      element_temp = get_element(input_array)

      result_string = ''

      if element_temp != ''
        if element_string != '' then
          result_string = result_string + ', '
        end
        result_string = result_string + element_temp
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

    return result_string

  end

  # This method uses the entry_id to get the title of the search result, i.e. 'Entry, Folio (Register)' and folio_id
  def get_entry_and_folio_details(entry_id)

    begin

      # Get the entry_no and folio_id for the entry_id
      SolrQuery.new.solr_query('id:' + entry_id, 'entry_no_tesim, folio_ssim', 1)['response']['docs'].map do |result|
        entry_no = result['entry_no_tesim'].join
        folio_id = result['folio_ssim'].join
        preflabel = ''
        # Get the preflabel for the folio_id
        # From the preflabel, can form the title, i.e. 'Entry, Folio (Register)'
        SolrQuery.new.solr_query('id:' + folio_id, 'preflabel_tesim', 1)['response']['docs'].map do |result|
          preflabel = result['preflabel_tesim'].join
        end
        # Remove 'Abp Reg' from the beginning of the preflabel and split the remaining string
        # to get the register and folio
        preflabel = preflabel.sub 'Abp Reg', ''
        register = preflabel.split(' ')[0].to_s
        folio = preflabel.sub(register, '')
        # Add the title and folio_id to the array instance
        @element_array << 'Entry ' + entry_no + ', ' + folio + " (Register " + register + ")"
        @element_array << folio_id
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

  end

  # Helper method to check if terms match the search term and if so, whether to put a comma in front of it
  # i.e. this is required if it is not the first term in the string
  def get_element(input_array)

    begin

      str = ''
      is_match = false

      if input_array != nil
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
        elsif is_match == false and @search_term != ''
          str = ''
        end

      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end

    return str
  end

  def get_solr_data(db_entry)

    begin

      SolrQuery.new.solr_query('id:' + db_entry.entry_id, 'entry_no_tesim, entry_type_tesim, section_type_tesim, continues_on_tesim, summary_tesim, marginalia_tesim, language_tesim, subject_tesim, note_tesim, editorial_note_tesim, is_referenced_by_tesim', 1)['response']['docs'].map do |result|

        if result['entry_no_tesim'] != nil

          db_entry.id = 1 #db_entry.entry_id.gsub(/test:/, '').to_i

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

              db_entry_date.id = 1 #date_id.gsub(/test:/, '').to_i

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

      SolrQuery.new.solr_query("folio_ssim:#{folio_id}", 'id, entry_no_tesim', 10000, 'entry_no_si asc')['response']['docs'].map do |result|
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

end

def log_error(method, file, error)
  time = Time.now.strftime('[%d/%m/%Y %H:%M:%S]').to_s
  logger.error "#{time} EXCEPTION IN #{file}, method='#{method}' [#{error}]"
end