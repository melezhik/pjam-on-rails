class SourcesController < ApplicationController

    def create

        @project = Project.find params[:project_id]
        @source = @project.sources.create( params[:source].permit( :url, :scm_type ) )

        begin
            @project.sources.find(@project[:distribution_source_id])
        rescue ActiveRecord::RecordNotFound => ex
            @project.update({:distribution_source_id => @source[:id]})
        end

        if @project.save
            flash[:notice] = "source ID:#{@source[:id]} has been successfully created"
        else
            flash[:alert] = "error has been occured when creating source: #{@project.errors.full_messages.join ' '}"
        end
        redirect_to edit_project_path @project

    end

    def destroy

        @project = Project.find(params[:project_id])
        @source = @project.sources.find(params[:id])
        url = @source.url
        @source.destroy
        flash[:notice] = "source ID:#{params[:id]}; Url: #{url} has been successfully deleted"
        redirect_to edit_project_path @project
    end

    def edit
        @project = Project.find(params[:project_id])
        @source = @project.sources.find(params[:id])
    end

    def update 
        @project = Project.find(params[:project_id])
        @source = @project.sources.find(params[:id])
        
        if @source.update(source_params)
            flash[:notice] = "source ID: #{@source.id} has been successfully reordered"
            redirect_to [ :edit, @project, @source ]
        else
            flash[:alert] = "error has been occured when reorder source ID: #{@source.id}"
            render 'edit'
        end
    end


    def on
        @project = Project.find(params[:project_id])
        @source = @project.sources.find(params[:id])
        if @source.update({:state => true })
            flash[:notice] = "source ID:#{params[:id]}; Url: #{@source.url} has been sucessfully enabled"
            redirect_to [:edit, @project]
        else
            flash[:alert] = "error has been occured when enabling source ID:#{params[:id]}; Url: #{@source.url}"
            render :edit            
        end
    end

    def off
        @project = Project.find(params[:project_id])
        @source = @project.sources.find(params[:id])
        if @source.update({:state => false})
            flash[:notice] = "source ID:#{params[:id]}; Url: #{@source.url}  has been sucessfully disabled"
            redirect_to [:edit, @project]
        else
            flash[:alert] = "error has been occured when disabling source ID:#{params[:id]}; Url: #{@source.url}"
            render :edit            
        end
    end

private

  def source_params
      params.require( :source ).permit( :sn )
  end

end
