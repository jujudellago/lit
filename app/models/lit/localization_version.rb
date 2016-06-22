module Lit
  class LocalizationVersion
    
    include Mongoid::Document
    include Mongoid::Timestamps
    

    field :localization_id, type: Integer
    field :translated_value, type: String

    
    
 #   serialize :translated_value

    ## ASSOCIATIONS
    belongs_to :localization

    def to_s
      translated_value
    end
  end
end
