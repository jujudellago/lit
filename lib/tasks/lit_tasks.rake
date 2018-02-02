namespace :lit do
  desc 'Exports translated strings from lit to config/locales/lit.yml file.'
  task export: :environment do
    if yml = Lit.init.cache.export
      PATH = 'config/locales/lit.yml'
      File.new("#{Rails.root}/#{PATH}", 'w').write(yml)
      puts "Successfully exported #{PATH}."
    end
  end
  desc "import existing translations in lit"
  task import: :environment do
    I18n.available_locales.each do |locale|
      loc=Lit::Locale.where(:locale => locale).pluck(:id)
      
      I18n.locale=locale
      Lit::LocalizationKey.each do |lk|
        key=lk.localization_key
        translated_value=I18n.t(key)
        unless translated_value.nil?
          localization=Lit::Localization.where({'$and': [{:locale_id.in=>loc},{:localization_key_id=>lk.id}]}).first
          if localization && localization.translated_value.blank? && translated_value.match(/^(translation missing)+/).nil?
            #localization.update_attribute(:translated_value,translated_value)
            puts "locale: #{locale}, will update key: #{key} with value:#{translated_value}"
          end
            
          
        end        
      end
      
      
    end
    
  end
end
