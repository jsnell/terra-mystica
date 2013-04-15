function register() {
    $("error").innerHTML = "";
    $("validate").style.display = "none";

    try {
        var fields = ["username", "email", "password1", "password2"];
        var error = "";

        fields.each(function (field) {
            $(field).style.backgroundColor = "#fff";
        });

        fields.each(function (field) {
            if ($(field).value == "") {
                $(field).style.backgroundColor = "#fbb";
                error += "Field " + field + " must be non-empty<br>";
            }
        });

        if ($("password1").value != $("password2").value) {
            error += "The passwords don't match"
        }

        if (error != "") {
            throw error;
        }

        $("userinfo").request({
            method:"post",
            onSuccess: function(transport) {
                state = transport.responseText.evalJSON();
                if (state.error.length) {
                    $("error").innerHTML = state.error.join("\n");
                } else {
                    $("validate").style.display = "block";
                    $("usage").style.display = "none";
                }
            }
        });    
    } catch (e) {
        handleException(e);
    }
}
