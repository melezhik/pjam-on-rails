class Setting < ActiveRecord::Base

    def skip_missing_prerequisites_as_pinto_param
        if skip_missing_prerequisites.nil?
            ''
        else
            skip_missing_prerequisites.split(/\s+/).map { |i| "-k=#{i.chomp}"  }.join " "
        end
    end

end
