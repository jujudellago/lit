module Lit
  class LocalizationVersion
    
    include Mongoid::Document
    include Mongoid::Timestamps
    

    field :localization_id, type: Integer
    field :translated_value, type: String

    index({ localization_id: 1 }, {  name: "localization_version_id_index" })
    
    
 #   serialize :translated_value

    ## ASSOCIATIONS
    belongs_to :localization

    def to_s
      translated_value
    end
  end
end
