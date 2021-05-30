# frozen_string_literal: true

module Common
  # Parses Json with keys as symbols
  class JsonRequestBody
    def self.parse_symbolize(json_str)
      JSON.parse(json_str).transform_keys(&:to_sym)
    end

    def self.symbolize(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
