require 'tnw_common/solr/solr_query'
require 'tnw_common/tna/tna_search'

class BrowseController < ApplicationController

  layout 'default_layout'

  def index
    reset_session_variables
  end

  def get_series_index(series_id, series_list)
    series_list.each_with_index do |s, index|
      if s[1] == series_id
        return index
      end
    end
    0
  end

  # browse/registers
  def registers
    begin
      reset_session_variables

      if (browse_params['collection'].nil? or browse_params['collection'] == '') and (browse_params['register_id'].nil? or browse_params['register_id'] == '')
         # Get collections
        @coll_list = get_collections()
      elsif browse_params['collection'] != nil and (browse_params['register_id'].nil? or browse_params['register_id'] == '')
        @coll_list = get_collections(browse_params['collection'])
        session[:collection] = browse_params['collection']
      else
        session[:register_id] = browse_params['register_id']
        session[:register_name] = get_register_name(session[:register_id])

        # Set the folio and image session variables when a folio is chosen from the drop-down list
        if browse_params['set_folio'] == 'true'
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

        if browse_params['folio'].nil? or browse_params['folio'] == '' or browse_params['folio'] == '0' or browse_params['folio'].to_i > session[:length]
          session[:folio] = '1'
          session[:folio_id] = @fol_list[0]
          get_entries(session[:folio_id])
        else
          session[:folio] = browse_params['folio'].to_i
          session[:folio_id] = get_id(@fol_list[browse_params['folio'].to_i - 1])
          get_entries(session[:folio_id])
        end

        # set folio_image / alt_image (UV)
        images = get_images_for_folio(session[:folio_id])
        session[:folio_image] = images[:folio_image] unless images[:folio_image].blank?
        session[:alt_image]   = images[:alt_image] unless images[:alt_image].blank?

        unless session[:entries_exist].nil?
          # Create a new DbEntry model from the database tables
          @db_entry = DbEntry.new
          if browse_params['entry_no'].nil?
            @db_entry.entry_id = session[:entries_exist][0]
          else
            @db_entry.entry_id = session[:entries_exist][browse_params['entry_no'].to_i - 1]

          end

          # Populate db_entry with data from Solr
          get_solr_data(@db_entry)

          # @entry_list is used to get the tabs for the view page
          @entry_list = get_entry_list(session[:folio_id])
        end
      end
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  # browse/departments
  def departments
    solr_server = TnwCommon::Solr::SolrQuery.new(SOLR[Rails.env]['url'])
    tna_search = TnwCommon::Tna::TnaSearch.new(solr_server)
    begin
      reset_session_variables

      # if no department_id provided, display all departments
      if params[:department_id].blank?
        @department_list = tna_search.get_all_departments()
      else
        @department_id = params[:department_id]
        @department_name = tna_search.get_department_desc(session[:department_id])

        @series_list = tna_search.get_all_series(params[:department_id])
        unless @series_list.nil? or @series_list.length()==0
          @first_series_id = @series_list[0][1]
          @last_series_id = @series_list[@series_list.length()-1][1]
        end
        if params['series'].nil? or params['series'] == ''
          @series_id = @series_list[0][1]
        else
          @series_id = params['series']
        end
        @series_index = get_series_index(@series_id, @series_list)
        @document_list = tna_search.get_ordered_documents_from_series(@series_id)
        if params['document_id'].nil? or params['document_id'] == ''
            @current_document = @document_list.length()==0? {}: tna_search.get_document_json(@document_list[0][:id])
        else
            @current_document = tna_search.get_document_json(params['document_id'])
        end
      end
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end


  # browse/people
  def people
    begin
      reset_session_variables
      # Show all or only indexed
      if browse_params['all'].nil? or browse_params['all'] == 'no'
        session[:all] = 'no'
        @search_array = PersonTerms.new('subauthority').internal_all_used
      elsif browse_params['all'] == 'yes'
        session[:all] = browse_params['all']
        @search_array = PersonTerms.new('subauthority').internal_all
      end

      # Limit by alphabet
      unless browse_params['letter'].nil? or browse_params['letter'] =='All' or browse_params['letter'].size() != 1
        unless browse_params['letter'] =='All'
          session[:letter] = browse_params['letter']
        end
        arr = []
        @search_array.each do | alpha |
          if alpha['label'][0].downcase == browse_params['letter'].downcase
            arr << alpha
          end
        end
        @search_array = arr
      end
  rescue => error
    log_error(__method__, __FILE__, error)
    raise
  end
  end

  # browse/groups
  def groups
    begin
      reset_session_variables
      # Show all or only indexed
      if browse_params['all'].nil? or browse_params['all'] == 'no'
        session[:all] = 'no'
        @search_array = GroupTerms.new('subauthority').internal_all_used
      elsif browse_params['all'] == 'yes'
        session[:all] = browse_params['all']
        @search_array = GroupTerms.new('subauthority').internal_all
      end

      # Limit by alphabet
      unless browse_params['letter'].nil? or browse_params['letter'] =='All' or browse_params['letter'].size() != 1
        unless browse_params['letter'] =='All'
          session[:letter] = browse_params['letter']
        end
        arr = []
        @search_array.each do | alpha |
          if alpha['label'][0].downcase == browse_params['letter'].downcase
            arr << alpha
          end
        end
        @search_array = arr
      end
    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  # browse/places
  def places
    begin
      reset_session_variables
      # Show all or only indexed
      if browse_params['all'].nil? or browse_params['all'] == 'no'
        session[:all] = 'no'
        @search_array = PlaceTerms.new('subauthority').internal_all_used
      elsif browse_params['all'] == 'yes'
        session[:all] = browse_params['all']
        @search_array = PlaceTerms.new('subauthority').internal_all
      end
      @search_hash = Hash.new

      @search_array.each do | place |

        if place['countrycode'].nil?
          if @search_hash[place['parentADM1']].nil?
            @search_hash[place['parentADM1']] = {place['parentADM2'] => [place] }
          else
            if @search_hash[place['parentADM1']][place['parentADM2']].nil?
              @search_hash[place['parentADM1']][place['parentADM2']] = [place]
            else
              arr = @search_hash[place['parentADM1']][place['parentADM2']]
              arr << place
              @search_hash[place['parentADM1']][place['parentADM2']] = arr
            end
          end
        else
          if @search_hash[place['countrycode']].nil?
            @search_hash[place['countrycode']] = {place['parentADM1'] => [place] }
          else
            if @search_hash[place['countrycode']][place['parentADM1']].nil?
              @search_hash[place['countrycode']][place['parentADM1']] = [place]
            else
              arr = @search_hash[place['countrycode']][place['parentADM1']]
              arr << place
              @search_hash[place['countrycode']][place['parentADM1']] = arr
            end
          end
        end
      end

      # Limit by adm2
      unless browse_params['letter'].nil? or browse_params['letter'] =='All'
        unless browse_params['letter'] =='All'
          unless @search_hash['England'][browse_params['letter']].nil?
            session[:letter] = browse_params['letter']
          end
        end
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  # browse/subjects
  def subjects
    begin
      # Get the top-level list (this is a hash which contains the 2nd level and 3rd level lists)
      if browse_params['all'].nil? or browse_params['all'] == 'no'
        session[:all] = 'no'
        @top_level_list = SubjectTerms.new('subauthority').get_subject_list_top_level_used
      elsif browse_params['all'] == 'yes'
        session[:all] = browse_params['all']
        @top_level_list = SubjectTerms.new('subauthority').get_subject_list_top_level
      end

    rescue => error
      log_error(__method__, __FILE__, error)
      raise
    end
  end

  def reset_session_variables
    session[:collection] = nil
    session[:folio] = nil
    session[:folio_id] = nil
    session[:length] = nil
    session[:first_folio_id] = nil
    session[:last_folio_id] = nil
    session[:register_name] = nil
    session[:alt] = nil
    session[:entries_exist] = nil
    session[:letter] = nil
    session[:all] = nil
    session[:folio_image] = nil
    session[:alt_image] = nil

    session[:department] = nil
    session[:series] = nil
    session[:series_id] = nil
    session[:first_series_id] = nil
    session[:last_series_id] = nil
    session[:department_name] = nil
  end

  #whitelist params
  private
  # Using a private method to encapsulate the permissible parameters
  # is just a good pattern since you'll be able to reuse the same
  # permit list between create and update. Also, you can specialize
  # this method with per-user checking of permissible attributes.
  def browse_params
    params.permit(:letter, :collection, :register_id, :set_folio,:folio, :folio_id,:entry_no, :all)
  end

end