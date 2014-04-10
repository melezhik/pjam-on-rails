require 'uri'
class Source < ActiveRecord::Base

    belongs_to :project
    validates :url, presence: true

    def enabled?
        state == true
    end

    def _indexed_url
        if scm_type == 'svn'
            URI.split(url)[2] + (URI.split(url)[5]).sub(/\/$/,"")
        elsif scm_type == 'git'
            url + '/tree/' + ( git_branch || 'master' ) + '/' + ( git_folder || '' )
        end
    end

end
