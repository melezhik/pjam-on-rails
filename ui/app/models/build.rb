class Build < ActiveRecord::Base

    belongs_to :project

    has_many :logs, :dependent => :destroy
    has_many :snapshots, :dependent => :destroy

#    validates :comment, presence: true , length: { minimum: 10 }
    
    def local_path
        "builds/#{id}"
    end

    def components 
       snapshots.order( id: :asc )
    end

    def main_component  
       snapshots.where(' is_distribution_url = ? ', true ).first
    end

    def component_by_indexed_url indexed_url
       snapshots.where(' indexed_url = ? ', indexed_url ).first
    end

    def has_main_component?
        ! main_component.nil?
    end

    def has_components?
        ! snapshots.empty?
    end

    def has_logs?
        logs.empty? == false
    end


    def recent_log_entries
         logs.order( :id => :desc ).limit(recent_log_entries_number).reverse
    end

    def all_log_entries
         logs.order( :id => :asc )
    end

    def recent_log_entries_number
        70
    end

    def short_comment
        "#{comment[0..70]} ... "
    end

    def ancestor
         Build.limit(1).order( id: :desc ).where(' project_id = ? AND id < ? AND has_stack = ? ', project_id, id, true ).first
    end

    def precedent
         Build.limit(1).order( id: :desc ).where(' project_id = ? AND id < ? ', project_id, id ).first
    end

    def has_parent?
        parent_id.nil? == false
    end

    def has_ancestor?
        ancestor.nil? == false
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

