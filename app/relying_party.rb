module WebAuthnDemo
  class RelyingParty < Sinatra::Base
    register WebAuthnDemo::BasicConfiguration
    helpers WebAuthnDemo::Helpers

    configure do
      set :origin, (ENV["WEBAUTHN_ORIGIN"] || "http://localhost:9292")
      set :db, {}
    end

    get "/" do
      if logged_in?
        redirect "/home"
      else
        erb :index
      end
    end

    get "/home" do
      if logged_in?
        erb :home, locals: { user_id: logged_in_user_id }
      else
        redirect "/"
      end
    end

    post "/logout" do
      logout!
      JSON.generate(result: "ok")
    end

    get "/signup" do
      erb :signup
    end

    get "/login" do
      if logged_in?
        redirect "/home"
      else
        erb :login
      end
    end
    
    # Registration用Challenge生成API
    post "/start_registration" do
      user_id = params[:user_id]

      verify_registerable_user_id!(user_id)

      settings.db[user_id] = {
        user_handle:   SecureRandom.uuid,
        registered:    false, 
        credential_id: nil,
        public_key:    nil,
        sign_count:    nil,
      }

      session[:user_id]   = user_id
      session[:challenge] = SecureRandom.hex(16)

      JSON.generate(
        user_handle: settings.db[user_id][:user_handle],
        challenge:   session[:challenge],
      )
    end

    # Registration用API
    post "/registration" do
      user_id = session[:user_id]

      verify_registerable_user_id!(user_id)
      verify_client_data_json!(type: "webauthn.create")
      
      auth_data = verify_attestation_object!

      settings.db[user_id][:registered]    = true
      settings.db[user_id][:credential_id] = auth_data.credential_id
      settings.db[user_id][:public_key]    = auth_data.credential_public_key
      settings.db[user_id][:sign_count]    = auth_data.sign_count

      JSON.generate(result: "ok")
    end

    # Authentication用Challenge生成API
    post "/start_authentication" do
      user_id = params[:user_id]
    
      session[:user_id]   = user_id
      session[:challenge] = SecureRandom.hex(16)

      JSON.generate(
        challenge: session[:challenge],
        credential_id: Base64.strict_encode64(find_registered!(user_id)[:credential_id]),
      )
    end

    # Authentication用API
    post "/authentication" do
      user_id     = session[:user_id]
      registered  = find_registered!(user_id)
      user_handle = params[:user_handle]["tempfile"].read

      if (!user_handle.empty? && user_handle != registered[:user_handle]) ||
         registered[:credential_id] != Base64.urlsafe_decode64(params[:id])
      
        raise "認証に失敗しました"
      end

      hash = verify_client_data_json!(type: "webauthn.get")

      raw_auth_data = params[:authenticator_data]["tempfile"].read
      auth_data     = verify_authenticator_data!(raw_auth_data)
      
      public_key = registered[:public_key]
      signature  = params[:signature]["tempfile"].read

      if public_key.verify("sha256", signature, raw_auth_data + hash)
        verify_sign_count!(registered, auth_data)

        session[:logged_in_user_id] = user_id
        JSON.generate(result: "ok")
      else
        raise "認証に失敗しました"
      end
    end
  end
end
