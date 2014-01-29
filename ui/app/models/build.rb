class Build < ActiveRecord::Base

    belongs_to :project

    has_many :logs

#    validates :comment, presence: true , length: { minimum: 10 }
    
    def local_path
        "builds/#{id}"
    end

    def has_logs?
        logs.empty? == false
    end


    def recent_log_entries
         logs.order(created_at: :desc).limit(recent_log_entries_number).reverse
    end

    def all_log_entries
         logs
    end

    def recent_log_entries_number
        100
    end

    def locked?
        locked == true
    end


    def short_comment
        (comment.split "\n").first + ' ... '
    end
end

