module Arturaz
  module AuthorizationHooks
    module ControllerInstanceMethods
      # Reset user session and demand relogin
      def reset_user_session
        reset_session
        flash[:error] = ::AuthorizationHooks.reset_user_session_message
        redirect_to login_url
      end

      # Is user authorized?
      def authorized?
        session[:authorized]
      end

      # Check if user is authorized
      def check_authorization
        unless authorized?
          save_last_location
          begin
            redirect_to login_url
          rescue ::ActionController::DoubleRenderError
            # Do nothing about it, just ignore...
          end

          false
        else
          true
        end
      end

      # Return last location where user was so we can do it like this:
      # <code>
      # redirect_to last_location
      # </code>
      def last_location
        session[:last_location] || root_url
      end

      # Save last location where user was to session
      def save_last_location
        catch :do_not_save do
          # Don't save these urls
          ::AuthorizationHooks.do_not_save_location_in.each do |page|
            url = send "#{page}_url", :only_path => true
            throw :do_not_save if request.env["REQUEST_URI"].include?(url)
          end

          session[:last_location] = request.env["REQUEST_URI"]
        end

        true
      end

      # Renew session expiration date after each request. So that keep me logged in 
      # for 2 weeks will always be 2 weeks from last request.
      def renew_session
        ::ActionController::Base.session_options[:session_expires] =
          session[:expires_in].from_now unless session[:expires_in].nil?
      end
    end
    
    module HelperMethods
      # Is user authorized (logged in)?
      def authorized?
        controller.send :authorized?
      end
    end
  end
end

ActionController::Base.class_eval do
  include Arturaz::AuthorizationHooks::ControllerInstanceMethods
  
  rescue_from ::CGI::Session::CookieStore::TamperedWithCookie,
    :with => :reset_user_session
  
  after_filter :save_last_location, :renew_session
  protected :reset_user_session, :authorized?, :check_authorization,
    :save_last_location, :renew_session
end

ActionView::Base.send :include, Arturaz::AuthorizationHooks::HelperMethods
