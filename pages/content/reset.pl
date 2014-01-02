{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/reset.js" ],
    title => 'Reset Password',
    content => read_then_close(*DATA)
}

__DATA__
    <div id="error"></div>
    <form id="userinfo" action="/app/reset/request/">
      <table>
        <tr><td>Email Address<td><input name="email" id="email"></input>
        <tr><td>New Password<td><input name="password" type="password" id="password"></input>
        <tr><td><td><input type="button" value="Reset Password" onclick="javascript:resetPassword()"></input>
      </table>
    </form>
    <div id="usage" style="display: block"></div>
    <div id="validate" style="display: none">
      <p>
      A password reset email has been sent to the indicated address.

      <p>
      Haven't received the email? Please check:
      <ul>
        <li> That the email is not in your spam folder
        <li> That you entered the correct email address above
      </ul>
    </div>
