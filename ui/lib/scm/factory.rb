module SCM::Factory
    def self.create component
        case component.scm_type
        when 'git'
            SCM::Svn.new component
        when 'svn'
            SCM::Git.new component
        else
            raise "unknown scm type: #{component.scm_type}"
        end    
    end        
end
