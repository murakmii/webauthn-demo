module WebAuthnDemo
  module BasicConfiguration
    def self.registered(app)
      app.set :lock, true
      app.set :show_exceptions, false

      app.use Rack::Session::Pool

      app.before do
        if request.env["rack.multiprocess"]
          raise "WebAuthn demo doesn't support multi process environment" 
        end
      end
  
      app.error do
        JSON.generate(
          error:
            if env["sinatra.error"].class == BinData::ValidityError
              "送信データに不備があります"
            else
              env["sinatra.error"].message
            end
        )
      end
    end
  end
end

