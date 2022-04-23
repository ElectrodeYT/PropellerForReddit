var client_id = "JH68M2Oa5sitdIQNvojHWw";
var http = new XMLHttpRequest();

function makeid(length) {
    var result           = '';
    var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var charactersLength = characters.length;
    for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() *
 charactersLength));
   }
   return result;
}

function initReddit() {
    console.log("RedditController onCompleted()")

    console.log(RedditController)

    RedditController.http = new XMLHttpRequest();

    if(RedditController == null) {
        console.log("RedditController == null, so cant continue");
        return;
    }

    // Generate a device ID
    console.log("default device id: " + RedditController.device_id);
    RedditController.device_id = makeid(30);
    console.log("generated device id: " + RedditController.device_id);

    var auth_url = "http://reddit.com/api/v1/access_token";
    var auth_params = "grant_type=https://oauth.reddit.com/grants/installed_client&device_id=" + RedditController.device_id

    // Open HTTP
    RedditController.http.open("POST", auth_url, false);

    // Setup XMLHttpRequest to reddit's specs
    RedditController.http.setRequestHeader("User-Agent", "ubuntu-touch:propeller.alexanderrichards:v1.0.0-git (by anon)");
    // Try to connect to reddit and authenticate
    RedditController.http.setRequestHeader("Authorization", "Basic " + Qt.btoa(RedditController.clientId + ":none"))

    RedditController.http.send(auth_params);

    console.log("got reddit response code " + RedditController.http.status);
    console.log("entire response headers: ");
    console.log(RedditController.http.getAllResponseHeaders())
    console.log("entire response itself: ");
    console.log(RedditController.http.responseText);
}

var test = "no";
function testJSSingleness() {
    console.log("test was " + test);
    test = "yes";
}

function attemptSet() {
    RedditController.test_from_js = "yes";
}
