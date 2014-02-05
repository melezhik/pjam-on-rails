require 'erubis'

class Setting < ActiveRecord::Base

    def skip_missing_prerequisites_as_pinto_param
        if skip_missing_prerequisites.nil?
            ''
        else
            skip_missing_prerequisites.split(/\s+/).map { |i| "--skip-missing-prerequisite=#{i.chomp}"  }.join " "
        end
    end

    def perl5lib_as_shell_variable
        if perl5lib.nil? or perl5lib.empty?
            ''
        else
            'PERL5LIB=' + (perl5lib.split(/\s+/).join ':')
        end
    end

    def pinto_repo_root
        "#{Rails.public_path}/repo"
    end

    def pinto_config
        "#{pinto_repo_root}/.pinto/config/pinto.ini"
    end

    def pinto_config_erb
        "#{Rails.root}/templates/pinto.ini.erb"
    end

    def update_pinto_config
        template = File.read(pinto_config_erb)
        template = Erubis::Eruby.new(template)
        File.open( pinto_config, 'w') { |file| file.write( template.result(:settings => self )) }
    end

end
