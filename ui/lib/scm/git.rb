class SCM::Git < Struct.new( :component, :path )

    def last_revision
        cmd = "cd #{path}/git-repo/ && git log -1 --pretty=format:'%h' 2>&1"
        unless component[:git_folder].nil?
            cmd << " #{component[:git_folder]}"
        end
        `#{cmd}`.chomp
    end

    def changes_cmd revision
        cmd = "cd #{path}/git-repo/ && git log --abbrev-commit #{component.revision}..#{revision}"
        unless component[:git_folder].nil?
            cmd << " -- #{component[:git_folder]}"
        end
        cmd
    end

    def diff_cmd revision
        cmd = "cd #{path}/git-repo/ && git diff #{component.revision} #{revision}"
        unless component[:git_folder].nil?
            cmd << " -- #{component[:git_folder]}"
        end
        cmd
    end

    def checkout_cmd
        cmd = "git clone -b #{component[:git_branch] || 'master'} #{component.url} #{path}/git-repo/"
        if component[:git_folder].nil?
            cmd << " && cp -r #{path}/git-repo/*  #{path}/ "
        else
            cmd << " && cp -r #{path}/git-repo/#{component[:git_folder]}/*  #{path}/ "
        end
    end

end

