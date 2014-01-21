require 'ansitags'
class Build < ActiveRecord::Base
    belongs_to :project

    def log_as_html
        log.ansi_to_html
    end
end

