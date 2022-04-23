import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.12
import Ubuntu.Components 1.3
import RedditController 1.0
import "."

RowLayout {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignLeft

    property string subredditName: "r/hot"

    Label {
        text: subredditName
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Ensure the reddit controller isnt doing anything
            RedditController.cancelRequest();
            var postsPage = Qt.createComponent("PostsPage.qml");
            if(postsPage.status !== Component.Ready) {
                console.log("Error loading component: ", openRedditPostComponent.errorString());
                return;
            }
            postsPage.parent = pageStack.parent;
            var newPage = postsPage.createObject(null, { "subreddit": subredditName } )
            newPage.parent = pageStack.parent;
            pageStack.push(newPage);
        }
    }
}
