require 'namae'

module MdsClientRuby
  module Author
    # parse author string into CSL format
    def get_one_author(author)
      return "" if author.blank?

      names = Namae.parse(author)
      if names.present?
        name = names.first

        { "family" => name.family,
          "given" => name.given }.compact
      else
        { "literal" => author }
      end
    end

    # parse array of author strings into CSL format
    def get_authors(authors)
      Array(authors).map { |author| get_one_author(author) }
    end

    # parse array of author hashes into CSL format
    def get_hashed_authors(authors)
      Array(authors).map { |author| get_one_hashed_author(author) }
    end

    def get_one_hashed_author(author)
      raw_name = author.fetch("creatorName", nil)

      author_hsh = get_one_author(raw_name)
      author_hsh["ORCID"] = get_name_identifier(author)
      author_hsh.compact
    end

    def get_name_identifier(author)
      name_identifier = author.fetch("nameIdentifier", nil)
      name_identifier_scheme = author.fetch("nameIdentifierScheme", "orcid").downcase
      if name_identifier.present? && name_identifier_scheme == "orcid"
        "http://orcid.org/#{name_identifier}"
      else
        nil
      end
    end

    def get_credit_name(author)
      [author['given'], author['family']].compact.join(' ').presence || author['literal']
    end

    def get_full_name(author)
      [author['family'], author['given']].compact.join(', ')
    end
  end
end
