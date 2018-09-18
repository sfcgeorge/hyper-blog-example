json.extract! session, :id, :email, :password, :created_at, :updated_at
json.url session_url(session, format: :json)
