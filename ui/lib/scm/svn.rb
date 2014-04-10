require 'crack'
class SCM::Svn < Struct.new( :component )

    def last_revision
        xml = `svn --xml info #{component.url}`.force_encoding("UTF-8")
        repo_info = Crack::XML.parse xml
        repo_info["info"]["entry"]["commit"]["revision"]
    end

    def check_repository_cmd
        "svn info #{component.url}"
    end


    def changes_cmd revision
        "svn log #{component.url} -r #{component.revision}:#{revision} && svn diff #{component.url} -r #{component.revision}:#{revision}"
    end

    def checkout_cmd path
        "svn export --force -q #{component.url} #{path}"
    end
end

