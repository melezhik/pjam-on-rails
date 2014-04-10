class SCM::Git < Struct.new( :component )

    def last_revision
        cmd = check_repository_cmd
        cmd << "git log -1 --pretty=format:'%h'"
        unless component[:git_folder].nil?
            cmd << " #{component[:git_folder]}"
        end
    end

    def check_repository_cmd
        cmd = "rm -rf  /tmp/.pjam/#{component.local_path} && mkdir -p /tmp/.pjam/#{component.local_path} && cd /tmp/.pjam/#{component.local_path} && "
        cmd << "git init && git remote add -t #{component[:git_branch] || 'master'} origin #{component[:url]} && git pull origin"
        unless component[:git_folder].nil?
            cmd << "&& ls -l #{component[:git_folder]}"
        end
        cmd
    end

    def changes_cmd revision
        cmd = check_repository_cmd + " && git log #{component.revision} #{revision}"
        unless component[:git_folder].nil?
            cmd << " #{component[:git_folder]}"
        end
        cmd << " && rm -rf /tmp/.pjam/#{component.local_path}"
        cmd
    end

    def checkout_cmd path
        if component[:git_folder].nil?
            cmd = "git clone -b #{component[:git_branch] || 'master'} #{component[:url]} #{path}"
        else
            cmd = "git clone -b #{component[:git_branch] || 'master'} #{component[:url]} #{path}/git-repo/ && cp -r #{path}/git-repo/* #{path}/ && rm -rf #{path}/git-repo/"
        end
    end

end

