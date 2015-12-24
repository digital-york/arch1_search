module Terms

  include Qa::Authorities::WebServiceBase

  class FolioFaceTerms < TermsBase
    def terms_list
      'folio_faces'
    end
  end

  class CertaintyTerms < TermsBase
    def terms_list
      'certainty'
    end
  end

  class CurrencyTerms < TermsBase
    def terms_list
      'currencies'
    end
  end

  class DateRoleTerms < TermsBase
    def terms_list
      'date_roles'
    end
  end

  class DateTypeTerms < TermsBase
    def terms_list
      'date_types'
    end
  end

  class DescriptorTerms < TermsBase
    def terms_list
      'descriptors'
    end
  end

  class FolioTerms < TermsBase
    def terms_list
      'folio_types'
    end
  end

  class FormatTerms < TermsBase
    def terms_list
      'formats'
    end
  end

  class LanguageTerms < TermsBase
    def terms_list
      'languages'
    end
  end

  class EntryTypeTerms < TermsBase
    def terms_list
      'entry_types'
    end
  end

  class PersonRoleTerms < TermsBase
    def terms_list
      'person_roles'
    end
  end

  class PlaceRoleTerms < TermsBase
    def terms_list
      'place_roles'
    end
  end

  class PlaceTypeTerms < TermsBase
    def terms_list
      'place_types'
    end
  end

  class SingleDateTerms < TermsBase
    def terms_list
      'single_dates'
    end
  end

  class SubjectTerms < TermsBase
    def terms_list
      "Borthwick Institute for Archives Subject Headings for the Archbishops' Registers"
    end
  end

  class SectionTypeTerms < TermsBase
    def terms_list
      'section_types'
    end
  end
end