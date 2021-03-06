module AuthorizationHooks
  mattr_accessor \
    :reset_user_session_message,
    :flash_notice,
    :redirection_submit_label
  
  # Message that is shown in flash[:error] when session gets corrupted.  
  self.reset_user_session_message = "Kažkas negero :( Gal gali prisijungti " +
    "iš naujo?"
  self.flash_notice = "Deja, šiam veiksmui atlikti turi būti " +
    "prisijungęs. Neturi paskyros? Nieko, užsiregistruoti tetrunka 10 " +
    "sekundžių ;-)"
  # Label of submit button for post redirection page
  self.redirection_submit_label = "Tęsti"
end
