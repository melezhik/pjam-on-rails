class Build < ActiveRecord::Base

    belongs_to :project

    has_many :logs, :dependent => :destroy
    has_many :snapshots, :dependent => :destroy

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
        70
    end

    def short_comment
        (comment.split "\n").first + ' ... '
    end

    def ancestor
         if parent_id.nil?
             Build.limit(1).order( id: :desc ).where('project_id = ? AND id < ? AND has_stack = ? ', project_id, id, true ).first
         else
             Build.limit(1).order( id: :desc ).where('project_id = ? AND id = ? ', project_id, parent_id ).first
         end
    end

    def precedent
         Build.limit(1).order( id: :desc ).where('project_id = ? AND id < ?', project_id, id ).first
    end

    def has_parent?
        parent_id.nil? == false
    end

    def has_ancestor?
        ! ancestor.nil?
    end

    def locked?
        locked == true
    end

    def stackable?
        has_stack == true
    end

    def released?
        released == true
    end

    def succeeded?
        state == 'succeeded'
    end
end

