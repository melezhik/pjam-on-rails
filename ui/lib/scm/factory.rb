module SCM::Factory
    def self.create component, path
        case component.scm_type
        when 'git'
            SCM::Git.new component, path
        when 'svn'
            SCM::Svn.new component, path
        else
            raise "unknown scm type: #{component.scm_type}"
        end    
    end        
end
