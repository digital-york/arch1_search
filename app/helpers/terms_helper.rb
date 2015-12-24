module TermsHelper
  class Geo
    def adminlevel(term1, term2)
      al = ''
      if term1 != ''
        al = term1
      end
      if term2 != ''
        if al != ''
          al += ', '
        end
        if term1 != term2
          al += term2
        end
      end
      al
    end
  end
end