class Build < ActiveRecord::Base
    belongs_to :project
    has_many :logs
    
    def local_path
        "builds/#{id}"
    end

    def has_logs?
        logs.empty? == false
    end


    def recent_log_entries
         logs.limit(recent_log_entries_number)
    end

    def all_log_entries
         logs
    end

    def recent_log_entries_number
        10
    end
end

