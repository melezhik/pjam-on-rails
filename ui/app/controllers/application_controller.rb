class ApplicationController < ActionController::Base

    before_action :authenticate_user!
    before_action :configure_permitted_parameters, if: :devise_controller?


    rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
        render :text => exception, :status => 500
    end

    rescue_from CanCan::AccessDenied do |exception|
        redirect_to root_url, :alert => exception.message
    end


    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    #protect_from_forgery with: :exception
    protect_from_forgery with: :null_session

protected

    def configure_permitted_parameters
        devise_parameter_sanitizer.for(:sign_in) << :username
    end

end

