require 'coffee-script'
require 'sass'
require 'less'
require 'sprockets'

module Dugway
  class Theme
    REQUIRED_FILES = %w( layout.html home.html products.html product.html cart.html checkout.html success.html contact.html maintenance.html scripts.js styles.css settings.json screenshot.jpg )
    
    def initialize(source_dir, overridden_customization={})
      @source_dir = source_dir
      @overridden_customization = overridden_customization.stringify_keys
    end
    
    def find_template_by_request(request)
      name = request.file_name
      
      if request.html? && content = read_source_file(name)
        Template.new(name, content)
      elsif name == 'styles.css'
        Template.new(name, sprockets[name].to_s)
      elsif name == 'scripts.js'
        Template.new(name, sprockets[name].to_s, false)
      else
        nil
      end
    end
    
    def find_image_by_env(env)
      Rack::File.new(@source_dir).call(env)
    end
    
    def layout
      @layout ||= read_source_file('layout.html')
    end
    
    def settings
      @settings ||= JSON.parse(read_source_file('settings.json'))
    end
    
    def fonts
      @fonts ||= customization_for_type('fonts')
    end
    
    def customization
      @customization ||= begin
        Hash.new.tap { |customization|
          %w( fonts colors options ).each { |type|
            customization.update(customization_for_type(type))
          }
        
          customization.update(@overridden_customization)
        }
      end
    end
    
    private
    
    def sprockets
      @sprockets ||= begin
        sprockets = Sprockets::Environment.new
        sprockets.append_path @source_dir
        sprockets
      end
    end
    
    def read_source_file(file_name)
      file_path = File.join(@source_dir, file_name)
      
      if File.exist?(file_path)
        File.open(file_path, "rb").read
      else
        nil
      end
    end
    
    def customization_for_type(type)
      Hash.new.tap { |hash|
        if settings.has_key?(type)
          settings[type].each { |setting|
            hash[setting['variable']] = setting['default']
          }
        end
      }
    end
  end
end
