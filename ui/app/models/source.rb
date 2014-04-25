require 'uri'
class Source < ActiveRecord::Base

    belongs_to :project
    validates :url, presence: true

    def enabled?
        state == true
    end

    def _indexed_url
        res = nil
        if scm_type == 'svn'
            begin
                res = URI.split(url)[2] + (URI.split(url)[5]).sub(/\/$/,"")
            rescue URI::InvalidURIError => ex
                res = url
            end
        elsif scm_type == 'git'
            res = url + ' ' + ( git_branch || 'master' ) + ' ' + ( git_folder || '' )
        end
        res
    end

end
