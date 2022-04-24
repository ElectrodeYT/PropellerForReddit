import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.12
import Ubuntu.Components 1.3

import "."


ColumnLayout {
    property string postName: "default-postname"
    property string postPreview: "default text post preview"
    property string postSelfText: "default text post content"

    property string postThumbnail: ""
    property string postVideo: ""
    property bool postHasThumbnail: false
    property bool postIsImagePost: false
    property bool postIsLinkPost: false

    property string postSubreddit: "default sub"
    property string postUser: "default user"
    property string postFlair: "default flair"

    property date postDate: new Date()
    property string postTimeAgoString: "default time ago"

    property int postThumbnailWidth: 1000
    property int postThumbnailHeight: 1000

    property string postID: "default-post-id"

    property Flickable flickable

    Layout.alignment: Qt.AlignLeft //| Qt.AlignRight


    // Giant calculation to check if the post is currently in view
    property bool inView: ((scrollView.flickableItem.contentY + scrollView.height) >= y) && (scrollView.flickableItem.contentY < (y + height))

    ToolSeparator {
        orientation: Qt.Horizontal
        Layout.fillWidth: true
    }
    // Title & small image preview
    RowLayout {
        Layout.alignment: Qt.AlignLeft
        AnimatedImage {
            enabled: postHasThumbnail && !postIsImagePost
            visible: enabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: units.gu(6)
            Layout.maximumWidth: units.gu(6)
            Layout.alignment: Qt.AlignLeft
            source: postThumbnail
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
        }
        Label {
            text: i18n.tr(postSubreddit + " - u/" + postUser + "\n" + postTimeAgoString)
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            verticalAlignment: Label.AlignTop
            horizontalAlignment: Label.AlignLeft
            Layout.fillWidth: true
            maximumLineCount: 4
            elide: Text.ElideRight
            textSize: Label.Small
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        }
    }
    Frame {
        enabled: postFlair != ""
        visible: enabled
        leftPadding: units.gu(1) / 2
        rightPadding: units.gu(1) / 2
        topPadding: units.gu(1) / 2
        bottomPadding: units.gu(1) / 2
        background: Rectangle {
            color: "transparent"
            border.color: "#21be2b"
            radius: units.gu(1)
        }

        Label {
            enabled: postFlair != ""
            visible: enabled
            text: postFlair
            textSize: Label.Small
        }
    }

    Label {
        text: i18n.tr(postName)
        textSize: Label.Large
        verticalAlignment: Label.AlignTop
        horizontalAlignment: Label.AlignLeft
        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
        Layout.row: 0
        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        Layout.fillWidth: true
        maximumLineCount: 2
        elide: Text.ElideRight
        // width: Math.min(implicitWidth, (rowLayoutInPost.availableWidth - openPostButton.implicitWidth))
    }
    // Text preview
    Label {
        text: postPreview
        Layout.fillWidth: true
        Layout.row: 1
        maximumLineCount: 4
        elide: Text.ElideRight
        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        enabled: postPreview !== ""
        visible: enabled
    }

    // Image preview
    Item {
        Layout.fillWidth: true
        Layout.maximumWidth: postThumbnailWidth * 2
        //Layout.preferredHeight: postImage.paintedHeight
        Layout.preferredHeight: (postThumbnailHeight / postThumbnailWidth) * width
        Layout.alignment: Qt.AlignTop | Qt.AlignVCenter
        enabled: postIsImagePost
        visible: postIsImagePost
        AnimatedImage {
            enabled: postIsImagePost && inView
            visible: enabled
            source: inView ? postThumbnail : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
            verticalAlignment: Image.AlignTop
            autoTransform: true
            id: postImage
            anchors.fill: parent
            onStatusChanged: playing = (status == AnimatedImage.Ready)
        }
        BusyIndicator {
            anchors.centerIn: parent
            visible: (postImage.progress != 1) && inView
        }
        ProgressBar {
            visible: (postImage.progress != 1) && inView
            value: postImage.progress
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }
    }

    // Vote container
    Item {

    }

    function openPost() {
        var openRedditPostComponent = Qt.createComponent("OpenedRedditPost.qml");
        if(openRedditPostComponent.status !== Component.Ready) {
            console.log("Error loading component: ", openRedditPostComponent.errorString());
            return;
        }
        console.log("postVideo: " + postVideo);
        pageStack.push(openRedditPostComponent.createObject(null, {
                                                                "pageTitle": postName,
                                                                "pageText": postSelfText,
                                                                "pageImage": postThumbnail,
                                                                "pageHasImage": postIsImagePost,
                                                                "pageVideo": postVideo,
                                                                "pageHasVideo": postVideo !== "",
                                                                "pageThumbnail": postThumbnail,
                                                                "pageHasThumbnail": postHasThumbnail,
                                                                "pageImageWidth": postThumbnailWidth,
                                                                "pageImageHeight": postThumbnailHeight,
                                                                "pageID": postID
                                                            } ));
    }

    MouseArea {
        anchors.fill: parent
        onClicked: openPost()
        z: 999999
    }
}



