import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.12
import QtGraphicalEffects 1.0
import Ubuntu.Components 1.3
import RedditController 1.0
import "."


Page {
    id: openedRedditPage
    anchors.fill: parent
    property string pageTitle: "default-title"
    property string pageText: "Top\n\n\n\n\n\n\n\nThis is the default text."

    property string pageImage: ""
    property bool pageHasImage: false
    property int pageImageWidth: 100
    property int pageImageHeight: 100

    property string pageVideo: ""
    property bool pageHasVideo: false

    property string pageThumbnail: ""
    property bool pageHasThumbnail: false

    property int pageScore: 420
    property bool hasBeenUpvoted: false
    property bool hasBeenDownvoted: false

    property string pageID: ""

    Component.onCompleted: {
        console.log("opened reddit post with id" + pageID);
        RedditController.getCommentsFromPost(pageID);
    }

    Connections {
        target: RedditController
        onCommentsReceived: {
            if(!active) { return; }
            console.log("comments: " + comments + " dist: " + comments.dist);
            var redditCommentComponent = Qt.createComponent("qrc:/Comment.qml");
            if(redditCommentComponent.status !== Component.Ready) {
                console.log("Error loading component: ", redditCommentComponent.errorString());
                return;
            }
            for(var i = 0; i < comments.dist; i++) {
                var redditCommentObject = redditCommentComponent.createObject(commentColumn, {
                                                                               commentAuthor: comments.comments_name[i],
                                                                               commentText: comments.comments[i],
                                                                               commentDepth: comments.comments_depth[i],
                                                                               commentScore: comments.comments_score[i],
                                                                               commentID: ("t1_" + comments.comments_id[i]),
                                                                               hasBeenUpvoted: comments.comments_upvoted[i],
                                                                               hasBeenDownvoted: comments.comments_downvoted[i]
                });
                console.log("create comment " + i + " " + redditCommentObject)
            }
            loadingProgressBar.enabled = false
        }
    }

    MediaPlayer {
        id: mediaPlayer
        source: pageVideo
        // enabled: pageHasVideo
    }

    header: PageHeader {
        id: header
        title: i18n.tr(pageTitle)
    }

    ProgressBar {
        id: loadingProgressBar
        //enabled: true
        visible: enabled
        indeterminate: true
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    Frame {
        id: frame
        anchors.fill: parent
        anchors.topMargin: header.height
        height: parent.height - header.height
        ScrollView {
            id: scrollView
            anchors.fill: parent
            flickableItem.contentWidth: frame.availableWidth
            flickableItem.bottomMargin: 0;
            ColumnLayout {
                id: columnInOpenedPost
                //anchors.fill: parent
                //Layout.fillWidth: true
                //width: Math.min(implicitWidth, scrollView.availableWidth)
                //Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                width: frame.availableWidth

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        id: postTitleLabel
                        text: pageTitle
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        elide: Text.ElideRight
                        textSize: Label.Large
                        Layout.fillWidth: true
                    }

                    AnimatedImage {
                        Layout.fillWidth: true
                        Layout.maximumWidth: units.gu(10)
                        fillMode: Image.PreserveAspectFit
                        source: pageThumbnail
                        visible: pageHasThumbnail

                        onPaintedGeometryChanged: {
                            Layout.preferredHeight = paintedHeight; // Limit the height of the image to not have a giant gap between posts
                        }
                    }
                }

                ToolSeparator {
                    orientation: Qt.Horizontal
                    Layout.fillWidth: true
                }

                Label {
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                    id: pageTextLabel
                    text: pageText
                    enabled: !(pageHasVideo || pageHasImage)
                    visible: enabled
                }

                        // qDebug() << "post " <
                Item {
                    Layout.fillWidth: true
                    Layout.maximumWidth: pageImageWidth * 2
                    Layout.preferredHeight: (pageImageHeight / pageImageWidth) * width
                    enabled: pageHasImage
                    visible: enabled
                    AnimatedImage {
                        enabled: pageHasImage
                        visible: enabled
                        source: pageImage
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        verticalAlignment: Image.AlignTop
                        autoTransform: true
                        id: pageImageItem
                        anchors.fill: parent
                    }
                    BusyIndicator {
                        anchors.centerIn: parent
                        visible: pageImageItem.progress != 1
                    }
                    ProgressBar {
                        visible: (pageImageItem.progress != 1)
                        value: pageImageItem.progress
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
                        }
                    }
                }

                ToolSeparator {
                    orientation: Qt.Horizontal
                    Layout.fillWidth: true
                    enabled: visible
                    visible: pageTextLabel.paintedHeight || pageTextLabel.paintedWidth
                }

                Label {
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                    text: commentColumn.children.length + " comments: "
                }


                ColumnLayout {
                    id: commentColumn
                    spacing: units.gu(1)
                    Layout.fillWidth: true
                }
            }
        }
    }
}
