module SCM::Factory
    def self.create component
        case component.scm_type
        when 'git'
            SCM::Git.new component
        when 'svn'
            SCM::Svn.new component
        else
            raise "unknown scm type: #{component.scm_type}"
        end    
    end        
end
