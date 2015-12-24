# added (ja)
class BrowseController < ApplicationController

  layout 'default_layout'
  include RegisterFolioHelper

  def index
    reset_session_variables
  end

  # browse/registers
  def registers
    reset_session_variables

    if params['register_id'].nil? or params['register_id'] == ''
      # Get collections
      @coll_list = get_collections
    else

      session[:register_id] = params[:register_id]
      session[:register_name] = get_register_name(session[:register_id])

      # Set the folio and image session variables when a folio is chosen from the drop-down list
      if params[:set_folio] == 'true'
        set_folio_and_image_drop_down
      end

      # Set the @folio_list for the folio drop-down
      set_folio_list

      @fol_list = get_order(session[:register_id])
      session[:length] = @fol_list.size()

      if session[:last_folio_id] == nil
        session[:last_folio_id] == ''
        set_first_and_last_folio
      end

      if params['folio'].nil? or params['folio'] == '' or params['folio'] == '0' or params['folio'].to_i > session[:length]
        session[:folio] = '1'
        session[:folio_id] = @fol_list[0]
        get_entries(session[:folio_id])
      else
        session[:folio] = params['folio'].to_i
        session[:folio_id] = @fol_list[params['folio'].to_i - 1]
        get_entries(session[:folio_id])
      end

      unless session[:entries_exist].nil?
        # Create a new DbEntry model from the database tables
        @db_entry = DbEntry.new
        if params['entry_no'].nil?
          @db_entry.entry_id = session[:entries_exist][0]
        else
          @db_entry.entry_id = session[:entries_exist][params[:entry_no].to_i - 1]

        end

        # Populate db_entry with data from Solr
        get_solr_data(@db_entry)

        # @entry_list is used to get the tabs for the view page
        @entry_list = get_entry_list(session[:folio_id])
      end

    end
  end

  # browse/people
  def people
    reset_session_variables
    @search_array = PersonTerms.new('subauthority').internal_all
    # Limit by alphabet
    unless params['letter'].nil? or params['letter'] =='All' or params['letter'].size() != 1
      unless params['letter'] =='All'
        session[:letter] = params['letter']
      end
      arr = []
      @search_array.each do | alpha |
        if alpha['label'][0].downcase == params['letter'].downcase
          arr << alpha
        end
      end
      @search_array = arr
    end
  end

  # browse/groups
  def groups
    reset_session_variables
    @search_array = GroupTerms.new('subauthority').internal_all
    # Limit by alphabet
    unless params['letter'].nil? or params['letter'] =='All' or params['letter'].size() != 1
      unless params['letter'] =='All'
        session[:letter] = params['letter']
      end
      arr = []
      @search_array.each do | alpha |
        if alpha['label'][0].downcase == params['letter'].downcase
          arr << alpha
        end
      end
      @search_array = arr
    end
  end

  # browse/places
  def places
    reset_session_variables
    @search_array = PlaceTerms.new('subauthority').internal_all
    # Limit by alphabet
    unless params['letter'].nil? or params['letter'] =='All' or params['letter'].size() != 1
      unless params['letter'] =='All'
        session[:letter] = params['letter']
      end
      arr = []
      @search_array.each do | alpha |
        if alpha['label'][0].downcase == params['letter'].downcase
          arr << alpha
        end
      end
      @search_array = arr
    end
  end

  # browse/subjects
  def subjects
    # Get the top-level list (this is a hash which contains the 2nd level and 3rd level lists)
    @top_level_list = SubjectTerms.new('subauthority').get_subject_list_top_level
  end

  def reset_session_variables
    session[:folio] = nil
    session[:folio_id] = nil
    session[:length] = nil
    session[:first_folio_id] = nil
    session[:last_folio_id] = nil
    session[:register_name] = nil
    session[:alt] = nil
    session[:entries_exist] = nil
    session[:letter] = nil
  end

  #whitelist params

end