class Setting < ActiveRecord::Base

    def skip_missing_prerequisites_as_pinto_param
        if skip_missing_prerequisites.nil?
            ''
        else
            skip_missing_prerequisites.split(/\s+/).map { |i| "--skip-missing-prerequisites=#{i.chomp}"  }.join " "
        end
    end

    def pinto_repo_root
        "#{Rails.public_path}/repo"
    end

end
