# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_qype-fm_session',
  :secret      => 'b93156ce1151fca6d9c86da222d5d195175720c7e99997f6efefc7c65d245e04bb5483d879eba593a84815c1b0c868a2efcd306986d1e855e5af2970752ec113'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
