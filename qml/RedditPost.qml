import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.12
import QtGraphicalEffects 1.0
import Ubuntu.Components 1.3
import RedditController 1.0
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

    property int pageScore: 420
    property bool hasBeenUpvoted: false
    property bool hasBeenDownvoted: false

    property string postID: "default-post-id"

    property Flickable flickable

    Layout.alignment: Qt.AlignLeft //| Qt.AlignRight


    // Giant calculation to check if the post is currently in view
    property bool inView: ((scrollView.flickableItem.contentY + scrollView.height) >= (y - units.gu(24))) && (scrollView.flickableItem.contentY < (y + height + units.gu(24)))

    MouseArea {
        anchors.fill: parent
        onClicked: openPost()
        // z: 999999
    }

    ToolSeparator {
        orientation: Qt.Horizontal
        Layout.fillWidth: true
        z: -9999
    }

    Rectangle {

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
        enabled: postIsImagePost // && ((postThumbnail.indexOf(".gif")) !== -1)

        Component.onCompleted: console.log(postThumbnail)

        visible: postIsImagePost // && ((postThumbnail.indexOf(".gif")) !== -1)
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

    RowLayout {
        Layout.alignment: Layout.Left
        Item {
            Layout.maximumWidth: units.gu(2)
            Layout.maximumHeight: units.gu(2)
            Layout.preferredWidth: units.gu(2)
            Layout.preferredHeight: units.gu(2)

            Image {
                source: "qrc:/arrow.svg"
                anchors.fill: parent
                rotation: -90
                id: upVoteImage
                visible: false
            }
            ColorOverlay {
                anchors.fill: upVoteImage
                source: upVoteImage
                rotation: -90
                color: hasBeenUpvoted ? "red" : "darkred"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("page upvote");
                    if(hasBeenUpvoted) { hasBeenUpvoted = false; pageScore--; RedditController.submitCommentVote(postID, 0); }
                    else if(hasBeenDownvoted) { hasBeenDownvoted = false; hasBeenUpvoted = true; pageScore += 2; RedditController.submitCommentVote(postID, 1); }
                    else { hasBeenUpvoted = true; pageScore++; RedditController.submitCommentVote(postID, 1); }
                }
                z: 9999999
            }
        }

        Label {
            text: pageScore.toString()
        }

        Item {
            Layout.maximumWidth: units.gu(2)
            Layout.maximumHeight: units.gu(2)
            Layout.preferredWidth: units.gu(2)
            Layout.preferredHeight: units.gu(2)

            Image {
                source: "qrc:/arrow.svg"
                anchors.fill: parent
                rotation: -90
                id: downVoteImage
                visible: false
            }
            ColorOverlay {
                anchors.fill: downVoteImage
                source: downVoteImage
                rotation: 90
                color: hasBeenDownvoted ? "aqua" : "midnightblue"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("page downvote");
                    if(hasBeenDownvoted) { hasBeenDownvoted = false; pageScore++; RedditController.submitCommentVote(postID, 0); }
                    else if(hasBeenUpvoted) { hasBeenUpvoted = false; hasBeenDownvoted = true; pageScore -= 2; RedditController.submitCommentVote(postID, -1); }
                    else { hasBeenDownvoted = true; pageScore--; RedditController.submitCommentVote(postID, -1); }
                }
                z: 9999999
            }
        }
    }

    signal upvoteSignal()
    signal downvoteSignal()
    signal scoreSignal();

    property var obj;

    onUpvoteSignal: {
        console.log("upvote signal");
        hasBeenUpvoted = obj.hasBeenUpvoted;
    }

    onDownvoteSignal: {
        console.log("downvote signal");
        hasBeenDownvoted = obj.hasBeenDownvoted;
    }

    onScoreSignal: {
        console.log("score signal");
        pageScore = obj.pageScore;
    }

    function openPost() {
        var openRedditPostComponent = Qt.createComponent("OpenedRedditPost.qml");
        if(openRedditPostComponent.status !== Component.Ready) {
            console.log("Error loading component: ", openRedditPostComponent.errorString());
            return;
        }
        console.log("postVideo: " + postVideo);
        obj = openRedditPostComponent.createObject(null, {
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
                                                           "pageID": postID,
                                                           "pageScore": pageScore,
                                                           "hasBeenUpvoted": hasBeenUpvoted,
                                                           "hasBeenDownvoted": hasBeenDownvoted
                                                       } );
        obj.hasBeenUpvotedChanged.connect(upvoteSignal);
        obj.hasBeenDownvotedChanged.connect(downvoteSignal);
        obj.pageScoreChanged.connect(scoreSignal);
        pageStack.push(obj);
    }
}



