class SettingsController < ApplicationController


    load_and_authorize_resource param_method: :settings_params

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
            @settings.update_pinto_config
            flash[:notice] = "settings have been successfully saved"
            redirect_to root_url
        else
            flash[:alert] = "error has been occured when save settings"
            render 'new'
        end
    end

    def update 
        @settings = Setting.take
	params = settings_params
	params.delete :jabber_password if params[:jabber_password].nil? or params[:jabber_password].empty?

        if @settings.update(params)
            @settings.update_pinto_config
            flash[:notice] = "settings have been successfully updated;"
            redirect_to root_url
        else
            flash[:alert] = "error has been occured when updating settings"
            render 'edit'
        end
    end


private

  def settings_params
      params.require(:setting).permit( 
            :perl5lib, :skip_missing_prerequisites, :pinto_downsteram_repositories, 
            :verbose,
            :force_mode,
            :jabber_host,
            :jabber_login,
            :jabber_password
     )
  end

end
