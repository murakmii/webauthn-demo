$(function() {


  $(document.signup.start).on("click", function() {
    $("#error").hide();

    var userId = document.signup.user_id.value;

    fetch("/start_registration", { 
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

        return navigator.credentials.create({
          publicKey: {
            challenge: new TextEncoder().encode(json.challenge),
            rp: {
              name: "WebAuthn demo"
            },
            user: {
              id: new TextEncoder().encode(json.user_handle),
              name: userId,
              displayName: userId,
            },
            pubKeyCredParams: [
              { type: "public-key", alg: -7 }
            ]
          }
        });
      })
      .then(function(cred) {
        var form_data = new FormData();
        form_data.append("attestation_object", new Blob([cred.response.attestationObject]));
        form_data.append("client_data_json", new Blob([cred.response.clientDataJSON]));

        return fetch("/registration", { method: "POST", body: form_data })
      })
      .then(function(response) {
        return response.json();
      })
      .then(function(json) {
        if (json.error) {
          throw Error(json.error);
        }

        $("#modal").fadeIn(500);
      })
      .catch(function(error) {
        $("#error").show().text(error.message);
      });

    return false;
  });
});
