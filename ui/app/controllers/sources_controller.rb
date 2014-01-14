class SourcesController < ApplicationController

    def create
        @project = Project.find params[:project_id]
        @source = @project.sources.create( params[:source].permit( :url, :scm_type ) )
        redirect_to project_path @project
    end

    def destroy

        @project = Project.find(params[:project_id])
        @source = @project.sources.find(params[:id])
        @source.destroy
        @message = "source # #{params[:id]} successfully deleted"
        render erb: @message
    end
    
    # used to set order in sources list; lift the source to 1 level up
    def up
        @project = Project.find(params[:project_id])
        @source = @project.sources.find(params[:id])

        change = true
        i = 0
        @project.sources_ordered.reverse.each do |s|
            i+=1
            if s[:id] == @source[:id]
                    change = true
            elsif change == true
                    sn = s[:sn]
                    s.update({ :sn => i-1 })
                    @source.update({ :sn => i })
                    change = false
            else
                    s.update({ :sn => i })
            end

        end

        redirect_to [:edit, @project]
    end

end
