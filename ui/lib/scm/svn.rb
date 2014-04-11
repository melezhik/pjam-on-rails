require 'crack'
class SCM::Svn < Struct.new( :component, :path )

    def last_revision
        xml = `svn --xml info #{component.url}`.force_encoding("UTF-8")
        repo_info = Crack::XML.parse xml
        repo_info["info"]["entry"]["commit"]["revision"]
    end

    def changes_cmd revision
        "svn log #{component.url} -r #{component.revision}:#{revision}"
    end

    def diff_cmd revision
        "svn diff #{component.url} -r #{component.revision}:#{revision}"
    end


    def checkout_cmd
        "svn export --force -q #{component.url} #{path}"
    end
end

