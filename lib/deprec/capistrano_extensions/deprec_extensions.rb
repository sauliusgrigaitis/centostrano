
require 'capistrano'

module Deprec
  DEPREC_TEMPLATES_BASE = File.join(File.dirname(__FILE__), '..', 'recipes', 'templates')

  def render_template_to_file(template_name, destination_file_name, templates_dir = DEPREC_TEMPLATES_BASE)
    template_name += '.conf' if File.extname(template_name) == ''
    
    file = File.join(templates_dir, template_name)
    buffer = render :template => File.read(file)

    temporary_location = "/tmp/#{template_name}"
    put buffer, temporary_location
    sudo "cp #{temporary_location} #{destination_file_name}"
    delete temporary_location
  end
  
  def append_to_file_if_missing(filename, value, options={})
    # XXX sort out single quotes in 'value' - they'l break command!
    # XXX if options[:requires_sudo] and :use_sudo then use sudo
    sudo <<-END
      grep '#{value}' #{filename} > /dev/null 2>&1 || 
      test ! -f #{filename} ||
      echo '#{value}' >> #{filename}
    END
  end

end

Capistrano.plugin :deprec, Deprec