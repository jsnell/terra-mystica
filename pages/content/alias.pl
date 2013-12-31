{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/alias.js" ],
    title => 'Register Email Alias',
    content => join '', <DATA>
}

__DATA__
    <div id="error"></div>
    <form id="userinfo" action="/app/alias/request/">
      <table>
        <tr><td>Email Address<td><input name="email" id="email"></input>
        <tr><td><td><input type="button" value="Register" onclick="javascript:register()"></input>
      </table>
      <input type="hidden" id="csrf-token" name="csrf-token" value="">
    </form>
    <div id="usage" style="display: block">
    <p>
      You can register multiple email addresses under the same user
      account. 
    </p>
    <p>
      Note that if you want to switch your ongoing games to use the new
      address, you'll need to ask the game admin to do that change on
      a game-by-game basis.
    </p>
    </div>
    <div id="validate" style="display: none">
      <p>
      The email alias will be registered as soon as we can validate the new
      email address. You should have received an email with the
      subject "Email alias validation for Terra Mystica". Please click on
      the link in that message to activate the new address.

      <p>
      Haven't received the email? Please check:
      <ul>
        <li> That the email is not in your spam folder
        <li> That you entered the correct email address above
      </ul>
    </div>
