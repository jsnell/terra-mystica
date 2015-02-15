{
    layout => 'sidebar',
    scripts => [ "/stc/common.js" ],
    title => 'Login',
    content => read_then_close(*DATA)
}

__DATA__
    <div id="error"></div>
    <script>
      if (document.location.hash == "#failed") {
         document.getElementById("error").innerHTML = "Login failed"
      }
      if (document.location.hash == "#invalid-user") {
         document.getElementById("error").innerHTML = "Login failed, invalid username"
      }
      if (document.location.hash == "#required") {
         document.getElementById("error").innerHTML = "Login required for operation"
      }
    </script>
    <form id="userinfo" action="/app/login/" method="POST">
      <table>
        <tr><td>Username<td><input name="username" id="username"></input>
        <tr><td>Password<td><input name="password" type="password" id="password"></input>
        <tr><td><td><input type="submit" value="login"></input>
      </table>
    </form>

    <p>
      Trouble logging in? <a href="/register/">Register</a> an account
      or <a href="/reset/">reset</a> your password.
