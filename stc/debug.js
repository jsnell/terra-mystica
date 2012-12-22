var stored_exception = null;

function handleException (e) {
    stored_exception = e;
    var p = document.getElementById("error");
    p.innerHTML += e;
}
