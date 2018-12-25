module WebAuthnDemo
  # Authenticator dataをパースするためのクラス
  class AuthenticatorData < BinData::Record
    endian :big

    # RP IDのハッシュのパースと検証
    string :rp_id_hash, length: 32, 
                        assert: -> {
                          origin = WebAuthnDemo::RelyingParty.settings.origin
                          host   = URI.parse(origin).host
                          value == OpenSSL::Digest::SHA256.digest(host)
                        }

    # 各種フラグのパース
    bit1 :ed, assert: 0
    bit1 :at
    sbit :rfu2, nbits: 3
    bit1 :uv
    bit1 :rfu1
    bit1 :up, assert: 1
    
    uint32 :sign_count

    # Attested credential dataが含まれていればそれもパース
    struct :attested_credential_data, onlyif: -> { include_credential? } do
      string :aaguid, length: 16
      int16  :credential_id_length
      string :credential_id, read_length: :credential_id_length

      # ここまでパースしたら、残りのバイト列を全てCredential public keyとしてパースする
      count_bytes_remaining :bytes_remaining
      string :credential_public_key, read_length: :bytes_remaining
    end

    # @return [Boolean] クレデンシャルを含んでいるかどうか
    def include_credential?
      at == 1
    end

    # @return [String,nil] クレデンシャルID
    def credential_id
      if include_credential?
        attested_credential_data.credential_id.to_s
      else
        nil
      end
    end

    # 公開鍵をCOSE Keyからより使いやすい形式(OpenSSL::PKey::EC)に変換して返す
    # 
    # @return [OpenSSL::PKey::EC,nil]
    def credential_public_key
      return nil unless include_credential?

      cose_key = CBOR.decode(attested_credential_data.credential_public_key.to_s)
      
      unless cose_key[1] == 2 && cose_key[-1] == 1
        raise "楕円曲線暗号かつsecp256r1をパラメータとして生成された公開鍵のみが使用できます"
      end

      bn    = OpenSSL::BN.new("\x04" + cose_key[-2] + cose_key[-3], 2)
      group = OpenSSL::PKey::EC::Group.new("prime256v1")

      ec = OpenSSL::PKey::EC.new(group)
      ec.public_key = OpenSSL::PKey::EC::Point.new(group, bn)
      ec
    end
  end

  module Helpers
    def logged_in?
      !logged_in_user_id.nil?
    end

    def logged_in_user_id
      session[:logged_in_user_id]
    end

    def logout!
      session[:logged_in_user_id] = nil
    end

    # @return [String] 指定ユーザーに対応するクレデンシャルID
    def find_registered!(user_id)
      if settings.db.has_key?(user_id) && settings.db[user_id][:registered]
        settings.db[user_id]
      else
        raise "ユーザーIDが不正です"
      end
    end

    # 登録可能なユーザーIDかどうかをチェックする
    #
    # @param [String, nil] user_id ユーザーID
    def verify_registerable_user_id!(user_id)
      return if user_id.is_a?(String) && 
                user_id.length >= 3 &&
                (!settings.db.has_key?(user_id) || !settings.db[user_id][:registered])

      raise "ユーザーIDが不正です"
    end
    
    # 送信されてきたClient data JSONを検証する
    #
    # @param [String] type "webauthn.create"か"webauthn.get"を指定する
    # @return [String] SHA-256で計算された、Client data jsonのハッシュ値
    def verify_client_data_json!(type:)
      client_data_json = params[:client_data_json]["tempfile"].read

      c = JSON.parse(client_data_json)
      challenge = Base64.urlsafe_decode64(c["challenge"]).to_s

      if challenge.empty? ||
         challenge   != session[:challenge] ||
         c["type"]   != type ||
         c["origin"] != settings.origin

        raise "Client Data JSONが不正です"
      end

      OpenSSL::Digest::SHA256.digest(client_data_json)
    ensure
      # 成否に関係なく、一度検証に使ったChallengeは二度と使えないようにしておく
      session[:challenge] = nil
    end

    # Attestation Objectを検証し、最終的にパース済みのAuthenticator dataを返す
    #
    # @return [WebAuthnDemo::AuthenticatorData]
    def verify_attestation_object!
      attestation_object = CBOR.decode(params[:attestation_object]["tempfile"].read)

      # 必要な場合、ここでattestation_object["fmt"]とattestation_object["attStmt"]を使った
      # 追加の検証を行う

      verify_authenticator_data!(attestation_object["authData"], need_credential: true)
    end

    # Authenticator dataの検証とパースを行う
    #
    # @param [String] auth_data Authenticator dataを表すバイト列
    # @param [Boolean] need_credential クレデンシャルを保持している必要があるかどうか
    # @return [WebAuthnDemo::AuthenticatorData]
    def verify_authenticator_data!(raw_auth_data, need_credential: false)
      auth_data = WebAuthnDemo::AuthenticatorData.read(raw_auth_data)

      # 既に登録されているCredential IDと重複しているならエラーとする
      if need_credential
        settings.db.each do |_, registered|
          next unless registered[:credential_id] == auth_data.credential_id
          raise "Credential IDが不正です"
        end
      end

      auth_data
    end

    # 認証回数を検証する
    #
    # @param [Hash] registered ユーザーの登録情報
    # @param [WebAuthnDemo::AuthenticatorData] auth_data Authenticator data
    def verify_sign_count!(registered, auth_data)
      if (registered[:sign_count] == 0 && auth_data.sign_count == 0) ||
         registered[:sign_count] < auth_data.sign_count
        registered[:sign_count] = auth_data.sign_count
      else
        raise "Authenticatorの認証回数が不正な状態に陥っています"
      end
    end
  end
end
