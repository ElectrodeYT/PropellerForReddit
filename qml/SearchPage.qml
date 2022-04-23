import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import RedditController 1.0
import Ubuntu.Components 1.3


Page {
    id: searchPage

    property string after_token: ""

    header: PageHeader {
        contents: Item {
            anchors.fill: parent
            TextField {
                id: searchBar
                anchors.fill: parent
                anchors.topMargin: units.gu(1)
                anchors.bottomMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)

                onAccepted: {
                    loadingProgressBar.enabled = true;
                    deleteAllSubredditListings();
                    if(RedditController.isBusy) { RedditController.cancelRequest(); }
                    RedditController.getSubredditSearch(text);
                }
            }
        }
    }

    Frame {
        anchors.fill: parent
        anchors.topMargin: header.height
        height: root.height - header.height
        id: frame
        ScrollView {
            anchors.fill: parent
            id: scrollView
            flickableItem.contentWidth: parent.availableWidth
            flickableItem.bottomMargin: 0;
            flickableItem.onContentYChanged:   {
                if(flickableItem.atYEnd && !RedditController.isBusy && !loadingProgressBar.visible) {
                    loadingProgressBar.enabled = true;
                }
            }

            ColumnLayout {
                width: frame.availableWidth
                id: column
                spacing: units.gu(3)

            }


        }
    }

    ProgressBar {
        id: loadingProgressBar
        enabled: false
        visible: enabled
        indeterminate: true
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    Connections {
        target: RedditController
        onSubredditsSearchReceived: {
            console.log(subreddits);
            var subredditComponent = Qt.createComponent("qrc:/SubredditSearchEntry.qml");
            if(subredditComponent.status !== Component.Ready) {
                console.log("Error loading component: ", subredditComponent.errorString());
                return;
            }
            console.log(subredditComponent)
            after_token = subreddits.after;
            for(let i = 0; i < subreddits.dist; i++) {
                console.log("subreddit: " + subreddits.subreddits[i]);
                var redditPostObject = subredditComponent.createObject(column, {
                    subredditName: subreddits.subreddits[i]
                });
            }
            loadingProgressBar.enabled = false;
        }
    }

    function deleteAllSubredditListings() {
        for(var i = column.children.length; i > 0 ; i--) {
          column.children[i-1].destroy();
        }
    }
}
