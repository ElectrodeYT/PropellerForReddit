import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtWebView 1.1
import RedditController 1.0
import Ubuntu.Components 1.3


Page {
    id: loginPage

    property bool loginFailed: false

    header: PageHeader {
        title: "Login"
    }

    Component.onCompleted: {
        settings.loggingIn = true;
        webView.url = "https://www.reddit.com/api/v1/authorize.compact?client_id=JH68M2Oa5sitdIQNvojHWw&response_type=code&state=LOGIN&redirect_uri=http://propeller/&duration=permanent&scope=identity edit flair history modconfig modflair modlog modposts modwiki mysubreddits privatemessages read report save submit subscribe vote wikiedit wikiread"
    }

    WebView {
        id: webView
        anchors.fill: parent
        onUrlChanged: {
            console.log(url);
            var test = /^http:\/\/propeller\//
            if(test.test(url)) {
                console.log("got redirected: " + url);
                loginFailed = !RedditController.handleOAuthLogin(url);
                webView.visible = false;
            }
        }
    }

    Label {
        anchors.centerIn: parent
        enabled: loginFailed
        visible: enabled
        text: "Login has failed; please try again later."
    }

    Connections {
        target: RedditController
        onAuthedChanged: {
            if(RedditController.isAuthed) {
                pageStack.pop();
            }
        }
    }
}
