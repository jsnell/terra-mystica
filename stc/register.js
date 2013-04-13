function register() {
    $("error").innerHTML = "";

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
                if (state.error) {
                    throw state.error;
                }
            }
        });    
    } catch (e) {
        handleException(e);
    }
}
