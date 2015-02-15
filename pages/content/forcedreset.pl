{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/reset.js" ],
    title => 'Reset Password',
    content => read_then_close(*DATA)
}

__DATA__
    <p>
       Sorry, you have to change your password before you can log in
       again.
    </p>

    <p>
    <b>Q: Why do I have to do this?</b>
    </p>
    <p>
    Somebody has been automatically trying to log in to the site on a large number of accounts using very common passwords, such as 'password' or '123456'. In some cases they've then proceeded to enter (bad) moves for a player whose password they'd guessed.</p>
    <p>
    Your account appears to also use a very weak password (either derived from your username, from the name of this site, or present in lists of very common passwords). To prevent the same from being done to your account (or to stop it, if it's already happening) you will need to change to a better password before anything else can be done with this account.
    </p>

    <p><b>Q: Why do I have to enter my email address here?</b></p>
    <p>
    All password changes are validated by sending an email to one of
    the email addresses you've registered with, to validate that it's
    really the account owner changing the password. 
    </p>

    <div id="error"></div>
    <form id="userinfo" action="/app/reset/request/">
      <table>
        <tr><td>Email Address<td><input name="email" id="email" autocomplete="off"></input>
        <tr><td>New Password<td><input name="password" type="password" id="password" autocomplete="off"></input>
        <tr><td>New Password (again)<td><input name="password_again" type="password" id="password_again" autocomplete="off"></input>
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
