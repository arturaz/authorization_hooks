module AuthorizationHooks
  mattr_accessor \
    :reset_user_session_message,
    :do_not_save_location_in
  
  # Message that is shown in flash[:error] when session gets corrupted.  
  self.reset_user_session_message = "Please relogin."
  # Do not save last location in these routes.
  self.do_not_save_location_in = [:login, :logout, :new_user]
end
