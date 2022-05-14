import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.12
import QtGraphicalEffects 1.0
import Ubuntu.Components 1.3
import RedditController 1.0
import "."


RowLayout {
    property string commentAuthor: "u/default user"
    property string commentText: "default comment text"
    property string commentID: "not_valid_id"
    property int commentDepth: 0

    property int commentUps: 420
    property int commentDowns: 69
    property int commentScore: 351

    property bool hasBeenUpvoted: false
    property bool hasBeenDownvoted: false

    property var colorArray: [ "darkgreen", "darkblue", "darkred" ]

    Layout.fillWidth: true
    Repeater {
        model: commentDepth
        delegate: Rectangle {
            Layout.fillHeight: true
            width: units.gu(0.2)
            Layout.leftMargin: units.gu(0.2)
            color: colorArray[index % 3]
        }
    }

    ColumnLayout {
        Label {
            Layout.fillWidth: true
            text: commentAuthor
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            elide: Label.ElideRight
            verticalAlignment: Label.AlignTop
            horizontalAlignment: Label.AlignLeft
            textSize: Label.Small
        }

        Label {
            Layout.fillWidth: true
            text: commentText
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            elide: Label.ElideRight
            verticalAlignment: Label.AlignTop
            horizontalAlignment: Label.AlignLeft
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
                        console.log("upvote");
                        if(hasBeenUpvoted) { hasBeenUpvoted = false; commentScore--; RedditController.submitCommentVote(commentID, 0); }
                        else if(hasBeenDownvoted) { hasBeenDownvoted = false; hasBeenUpvoted = true; commentScore += 2; RedditController.submitCommentVote(commentID, 1); }
                        else { hasBeenUpvoted = true; commentScore++; RedditController.submitCommentVote(commentID, 1); }
                    }
                }
            }

            Label {
                text: commentScore.toString()
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
                        console.log("downvote");
                        if(hasBeenDownvoted) { hasBeenDownvoted = false; commentScore++; RedditController.submitCommentVote(commentID, 0); }
                        else if(hasBeenUpvoted) { hasBeenUpvoted = false; hasBeenDownvoted = true; commentScore -= 2; RedditController.submitCommentVote(commentID, -1); }
                        else { hasBeenDownvoted = true; commentScore--; RedditController.submitCommentVote(commentID, -1); }
                    }
                }
            }
        }
    }
}
