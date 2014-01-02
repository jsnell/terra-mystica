{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/register.js",],
    title => 'Register New Account',
    content => read_then_close(*DATA)
}

__DATA__
    <div id="error"></div>
    <form id="userinfo" action="/app/register/request/">
      <table>
        <tr><td>Username<td><input name="username" id="username"></input>
        <tr><td>Email Address<td><input name="email" id="email"></input>
        <tr><td>Password<td><input name="password1" type="password" id="password1"></input>
        <tr><td>Verify password<td><input name="password2" type="password" id="password2"></input>
        <tr><td><td><input type="button" value="Register" onclick="javascript:register()"></input>
      </table>
    </form>
    <div id="usage" style="display: block">
    <p>
      The username should consist only of the letters A-Z and a-z, the
      digits 0-9, and the punctuation characters <code>.</code>
      <code>_</code> and <code>-</code> .
    <p>
    <p>
      A valid email address is required, both for administration like
      password resets, and for facilitating email play. The address
      might be shown to any users playing in the same match, but not
      to any outsiders.
    </p>
    </div>
    <div id="validate" style="display: none">
      <p style="color: green">
        Request sent.
      <p>
      Your account will be created as soon as we can validate your
      email address. You should have received an email with the
      subject "Account activation for Terra Mystica". Please click on
      the link in that message to activate your account.

      <p>
      Haven't received the email? Please check:
      <ul>
        <li> That the email is not in your spam folder
        <li> That you entered the correct email address above
      </ul>
    </div>
