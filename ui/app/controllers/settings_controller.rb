class SettingsController < ApplicationController

    def new
        Setting.new
    end

    def edit
        begin
        @settings = Setting.take!
        rescue ActiveRecord::RecordNotFound => ex
           @settings = Setting.new        
        end
    end

    def create
        @settings = Setting.new settings_params 
        if @settings.save
            flash[:notice] = "settings have been successfully saved"
            redirect_to root_url
        else
            flash[:alert] = "error has been occured when save settings"
            render 'new'
        end
    end

    def update 
        @settings = Setting.take
        if @settings.update(settings_params)
            flash[:notice] = "settings have been successfully updated"
            redirect_to root_url
        else
            flash[:alert] = "error has been occured when updating settings"
            render 'edit'
        end
    end


private

  def settings_params
      params.require(:setting).permit( :perl5lib, :skip_missing_prerequisites, :pinto_downsteram_repositories, :force_mode )
  end

end
