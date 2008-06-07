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
          if request.post?
            save_params
            session[:post_last_location] = session[:last_location]
            session[:last_referer] = request.env["HTTP_REFERER"]
            session[:last_location] = post_after_authorization_url
          end
          flash[:notice] ||= ::AuthorizationHooks.flash_notice
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
        session[:last_location] = request.env["REQUEST_URI"]
        true
      end
      
      def save_params
	session[:params] = params.except(:controller, :action, 
          :authenticity_token).to_hash
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
      
      # Creates a form that is used to redirect post data automatically
      def redirection_form
        # Get redirection URL
        redirection_url = session[:post_last_location] || root_url
        session[:post_last_location] = nil

        # Get redirection params
        redirection_params = session[:params] || {}
        session[:params] = nil

        # Restore referer
        if session[:last_referer]
          session[:last_location] = session[:last_referer] 
          session[:last_referer] = nil
        end    

        form_id = "redirection_form"
        html = form_tag(redirection_url, :id => form_id) + "\n"
        redirection_params.formify.each do |k, v|
          html += hidden_field_tag(k, v) + "\n"
        end
        html + submit_tag(::AuthorizationHooks.redirection_submit_label) + 
          "</form>" + javascript_tag("document.getElementById(" +
            form_id.to_json + ").submit()")
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
    :save_last_location, :save_params, :renew_session
end

ActionView::Base.send :include, Arturaz::AuthorizationHooks::HelperMethods
