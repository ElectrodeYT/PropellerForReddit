// Note:
// Reddit authentication relies on an "access" and "refresh" token to identify each device. This is annoying, as the refresh token is the one you want to keep super ultra private, as the access token cant be
// refreshed without it, and the refresh token has no expiry.
// While we do send the "DO_NOT_TRACK_THIS_DEVICE" device_id (partly because i didnt want to figure out the best way to generate a ID, partly because privacy),
// we have exactly 0 control over any tracking.
// More importantly, because manually checking if we can use a feature is annoying, we ask for just about every permission an app can get.
// We dont actually use most of these, but it does mean that if someone got the refresh token it would basically be just as bad as if someone got your password.
//
// Versions before <1.0.2 accidentally printed them to the UT Logs, but even if they didnt, as they are stored plaintext, it is trivial to get them anyway (ignoring AppArmor, as you would need an app that can read other apps data)
// As we do need them in plaintext/a reversible way anyway, there is basically no way around this without just not using a account.
// Because of this, if you (somehow) are a moderator of a multi-million user subreddit, I would not recommend loging in on anything except on a trusted device. Even then, I would personally not log in on anything rooted / jailbroken.
// This app is not inherintely less safe than the reddit website, or a reddit app on a different device running Android/iOS, because of AppArmor, but it is still worth noting this.

// Also: Reddit logins never actually give the app the password, so your password is safe on any device, running any os, running any app, providing they are not hooking the webbrowser, or using a oudated
// flow of authentication.

// TL;DR: if you are super security paranoid on the levels of stallmann, clear your logs of versions <1.0.2, although it probably wont ever actually be anything important.
