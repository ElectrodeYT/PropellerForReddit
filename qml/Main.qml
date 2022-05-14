import QtQuick 2.7
import Ubuntu.Components 1.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import RedditController 1.0

import "."

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'propeller.alexanderrichards'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    property bool failed: false
    property bool done: false

    onActiveChanged: {
        if(active) {
            console.log("should have logged out");
            if(RedditController.isAuthed) {
                pageStack.push(Qt.resolvedUrl("PostsPage.qml"));
            }
        }
    }

    ToolTip {
        id: infoBanner
        x: parent.width / 2 - width / 2
        y: parent.height - 150

        function show(text) {
            infoBanner.timeout = 3000
            infoBanner.text = text
            infoBanner.visible = true
        }
    }

    PageStack {
        id: pageStack

        Component.onCompleted: {
            settings.loggingIn = false;
            RedditController.refresh_token = settings.refreshToken;
            RedditController.initReddit();
        }
    }

    BusyIndicator {
        running: !failed && !done
        anchors.centerIn: parent
    }

    Label {
        anchors.centerIn: parent
        visible: failed
        text: "failed to connect to reddit"
        id: errorLabel
        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
    }

    Settings {
        id: settings

        property string refreshToken: ""
        property bool loggedInWithUser: false
        property bool loggingIn: false
    }

    Connections {
        target: RedditController
        onAuthedChanged: {
            if(!active || done) { return; }
            if(RedditController.isAuthed) {
                done = true;
                console.log("attempting to open postspage");
                pageStack.push(Qt.resolvedUrl("PostsPage.qml"));
                infoBanner.show("Connected to Reddit");
            }
        }
        onRequestTimedOut: {
            if(!active) { return; }
            errorLabel.text = "Request timed out";
            failed = true;
        }
        onRequestFailed: {
            if(!active) { return; }
            if(!failed) {
                errorLabel.text = "Failed to authenticate with Reddit: " + error_string;
                failed = true;
            }
        }
        onRefreshTokenChanged: {
            settings.refreshToken = new_token;
        }
    }
}
