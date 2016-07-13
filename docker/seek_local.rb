SEEK::Application.configure do
  #This holds a secret phrase, used for encrypting private information in the database
  #GLOBAL_PASSPHRASE=""


  Seek::Config.default :solr_enabled, true
end
