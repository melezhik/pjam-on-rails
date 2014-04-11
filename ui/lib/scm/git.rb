class SCM::Git < Struct.new( :component, :path )

    def last_revision
        cmd = "cd #{path} && git log -1 --pretty=format:'%h' 2>&1"
        unless component[:git_folder].nil?
            cmd << " #{component[:git_folder]}"
        end
        `#{cmd}`.chomp
    end

    def changes_cmd revision
        cmd = "cd #{path} && git log #{component.revision} #{revision}"
        unless component[:git_folder].nil?
            cmd << " #{component[:git_folder]}"
        end
        cmd
    end

    def checkout_cmd
        cmd = "git clone -b #{component[:git_branch] || 'master'} #{component.url} #{path}"
        unless component[:git_folder].nil?
            cmd << " && ls -l #{path}/#{component[:git_folder]}"
        end
    end

end

