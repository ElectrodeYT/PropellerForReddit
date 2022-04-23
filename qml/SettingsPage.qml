import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import RedditController 1.0
import Ubuntu.Components 1.3


Page {
    anchors.fill: parent
    header: PageHeader {
        id: header
        title: "Settings"
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
                // console.log("scrollbar pos: " + flickableItem.contentY  + " contentHeight: " + (flickableItem.contentHeight) + " header height: " + header.height);
                if(flickableItem.atYEnd && !RedditController.isBusy && !loadingProgressBar.visible && after_token !== "") {
                    console.log("getting more posts");
                    RedditController.getMorePosts(subreddit, after_token);
                    loadingProgressBar.visible = true;
                }
            }

            ColumnLayout {
                //anchors.left: parent.left
                //anchors.right: parent.right
                //Layout.fillWidth: true
                //width: parent.parent.availableWidth
                width: frame.availableWidth
                id: column
                //anchors.fill: parent
                spacing: units.gu(1)


                Label {
                    Layout.fillWidth: true
                    text: settings.oauth_token
                }
            }


        }
    }
}
