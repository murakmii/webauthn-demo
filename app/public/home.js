$(function() {
  $("#home a").click(function() {
    fetch("/logout", { method: "POST" })
      .then(function(response) {
        return response.json();
      })
      .then(function() {
        document.location = "/"
      });
  });
});
