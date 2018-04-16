module Lit
  module ApplicationHelper
    def bootstrap_class_for(flash_type)
      case flash_type
      when 'success'
        'alert-success'   # Green
      when 'error'
        'alert-danger'    # Red
      when 'alert'
        'alert-warning'   # Yellow
      else
        'alert-info'      # Blue
      end
    end

  end
end
