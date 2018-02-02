module Lit
  class LocalizationKey
    include Mongoid::Document
    include Mongoid::Timestamps
    
    attr_accessor :interpolated_key

    field :localization_key, type: String
    field :is_completed, type: Mongoid::Boolean,  default: false
    field :is_starred, type: Mongoid::Boolean,  default: false


    index({ localization_key: 1 }, {  name: "localization_key_index" })
    

    ## SCOPES
    scope :completed, proc { where(is_completed: true) }
    scope :not_completed, proc { where(is_completed: false) }
    scope :starred, proc { where(is_starred: true) }
    scope :ordered, proc { order('localization_key asc') }
    scope :after, proc { |dt|
      joins(:localizations)
        .where('lit_localization_keys.updated_at >= ?', dt)
        .where('lit_localizations.is_changed = true')
    }
    

    ## ASSOCIATIONS
    has_many :localizations, dependent: :destroy, class_name: '::Lit::Localization'

    ## VALIDATIONS
    validates :localization_key,
              presence: true,
              uniqueness: { if: :localization_key_changed? }

    unless defined?(::ActionController::StrongParameters)
      ## ACCESSIBLE
      attr_accessible :localization_key
    end

    def to_s
      localization_key
    end

    def clone_localizations
      new_created = false
      Lit::Locale.find_each do |locale|
        localizations.where(locale_id: locale.id).first_or_create do |l|
          l.default_value = interpolated_key
          new_created = true
        end
      end
      if new_created
        Lit::LocalizationKey.update_all ['is_completed=?', false], ['id=? and is_completed=?', id, false]
      end
    end

    def mark_completed
     # self.is_completed = localizations.all.changed.count(:id) == localizations.all.count
     self.is_completed = localizations.all.changed.count == localizations.all.count
    end

    def mark_completed!
      save if mark_completed
    end

    def mark_all_completed!
      localizations.update_all(['is_changed=?', true])
      mark_completed!
    end

    def self.order_options
      ['localization_key asc', 'localization_key desc', 'created_at asc', 'created_at desc', 'updated_at asc', 'updated_at desc']
    end

    # it can be overridden in parent application, for example: {:order => "created_at desc"}
    def self.default_search_options
      {}
    end

    def self.search(options={})
        options = options.reverse_merge(default_search_options)
        s = self #.includes(:localizations)
        queries=[]
        Lit.ignored_keys.each do |ik|
          #regex=/^#{ik}./
          
          regex=/^(?!#{ik})+/
          queries<<{:localization_key => regex}
        end
        
        if options[:loc].present?
          loc=Lit::Locale.where(:locale => options[:loc]).pluck(:id)
       #   existing_ids=Lit::Localization.where({:locale_id.in=>loc}).pluck(:localization_key_id)
          existing_ids=Lit::Localization.where({'$and': [{:locale_id.in=>loc},{:translated_value.nin => [nil,""]}]}).collect(&:localization_key_id)
#          all_ids=Lit::Localization.where({:locale_id.in=>locale}).pluck(:localization_key_id)
           # all_ids=Lit::Localization.where({:locale_id.in=>['en']}).pluck(:localization_key_id)
          
          all_keys=Lit.init.cache.keys
          existing_keys=[]
          all_keys.each do |k|
            regex=/^(lit:#{options[:loc]}.)+/
            if k.match(regex)
              existing_keys<<k.gsub(regex,"")
            end
          end
          queries<<{:localization_key.nin => existing_keys}
            





         # s = s.where()
         # queries<<{:'localization_key.id'.nin => existing_ids}
          
        end        
        
        if  options[:key].present? && options[:key_prefix].present?
            regex1=/#{options[:key]}$/
            

            
            regex2=/^#{options[:key_prefix]}./
            

            #regex1=/login$/
            #regex2=/^profile/
            
        #    s.where({"localization_key": regex1}).and({"localization_key": regex2})
            
            
            #Lit::LocalizationKey.in([{"localization_key": regex2},{"localization_key": regex1}])
#           s = s.where({'$and': [{localization_key: regex1}, {localization_key: regex2}]})
           
           queries<<{localization_key: regex1}
           queries<<{localization_key: regex2}
           
           #Lit::LocalizationKey.where({'$and': [{localization_key: regex1}, {localization_key: regex2}]})
           
            
        else
        
         if options[:key].present?
           regex3=/#{options[:key]}$/
           #s=s.where({"localization_key": regex3})
           queries<<{"localization_key": regex3}
         end  
         if options[:key_prefix].present?
           regex4=/^#{options[:key_prefix]}./           
          #   s=s.where({"localization_key": regex4})
           queries<<{"localization_key": regex4}
         end
       end
      # if options[:order] && order_options.include?(options[:order])
      #   column, order = options[:order].split(' ')
      #   s = s.order("#{column} #{order.upcase}")
      # else
      #   s = s.ordered
      # end
      # unless options[:include_completed].to_i == 1
      #    s = s.not_completed
      #  end
        s = s.where({'$and': queries})
      
         s
    end


    def self.old_search(options = {})
      options = options.reverse_merge(default_search_options)
      s = self
      if options[:order] && order_options.include?(options[:order])
        column, order = options[:order].split(' ')
        s = s.order("#{Lit::LocalizationKey.quoted_table_name}.#{connection.quote_column_name(column)} #{order}")
      else
        s = s.ordered
      end
      localization_key_col = Lit::LocalizationKey.arel_table[:localization_key]
      default_value_col = Lit::Localization.arel_table[:default_value]
      translated_value_col = Lit::Localization.arel_table[:translated_value]
      if options[:key_prefix].present?
        q = "#{options[:key_prefix]}%"
        s = s.where(localization_key_col.matches(q))
      end
      if options[:key].present?
        q = "%#{options[:key]}%"
        q_underscore = "%#{options[:key].parameterize.underscore}%"
        cond = localization_key_col.matches(q).or(
            default_value_col.matches(q).or(
                translated_value_col.matches(q)
            )
        ).or(localization_key_col.matches(q_underscore))
        s = s.joins([:localizations]).where(cond)
      end
      unless options[:include_completed].to_i == 1
        s = s.not_completed
      end
      s
    end
  end
end
