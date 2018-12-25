$(function() {
  $(document.login.start).on("click", function() {
    $("#error").hide();

    var userId = document.login.user_id.value;

    fetch("/start_authentication", { 
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
      body: "user_id=" + encodeURIComponent(userId)
    })
      .then(function(response) {
        return response.json();
      })
      .then(function(json) {
        if (json.error) {
          throw Error(json.error);
        }

        return navigator.credentials.get({ 
          publicKey: {
            challenge        : new TextEncoder().encode(json.challenge),
            allowCredentials : [
              { type: "public-key", id: base64js.toByteArray(json.credential_id) }
            ]
          }
        });
      })
      .then(function(cred) {
        var form_data = new FormData();
        form_data.append("id", cred.id);
        form_data.append("authenticator_data", new Blob([cred.response.authenticatorData]));
        form_data.append("client_data_json", new Blob([cred.response.clientDataJSON]));
        form_data.append("signature", new Blob([cred.response.signature]));
        form_data.append("user_handle", new Blob([cred.response.userHandle]));

        return fetch("/authentication", { method: "POST", body: form_data })
      })
      .then(function(response) {
        return response.json();
      })
      .then(function(result) {
        if (result.error) {
          throw Error(result.error);
        }

        document.location = "/"
      })
      .catch(function(error) {
        $("#error").show().text(error.message);
      });

    return false;
  });
});
