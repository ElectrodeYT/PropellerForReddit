import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import RedditController 1.0
import Ubuntu.Components 1.3


Page {
    id: searchPage
    anchors.fill: parent

    property string subreddit: ""
    property string after_token: ""

    header: PageHeader {
        id: header
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
                    deleteAllPosts();
                    RedditController.cancelRequest();
                    RedditController.getPostsFromSubredditSearch(subreddit, text);
                }
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
                if(flickableItem.atYEnd && !RedditController.isBusy && !loadingProgressBar.visible && after_token !== "") {
                    loadingProgressBar.enabled = true;
                    RedditController.getMorePostsFromSubredditSearch(subreddit, searchBar.text, after_token);
                }
            }

            ColumnLayout {
                width: frame.availableWidth
                id: column
                spacing: units.gu(1)

            }


        }
    }

    Connections {
        target: RedditController
        onPostsReceived: {
            if(!active) { return; }
            var redditPostComponent = Qt.createComponent("qrc:/RedditPost.qml");
            if(redditPostComponent.status !== Component.Ready) {
                console.log("Error loading component: ", redditPostComponent.errorString());
                return;
            }
            after_token = posts.after;
            for(let i = 0; i < posts.dist; i++) {
                var redditPostObject = redditPostComponent.createObject(column, {
                                                                            postName: posts.posts[i],
                                                                            postSelfText: posts.posts_selftext[i],
                                                                            postPreview: posts.posts_desc[i],
                                                                            postSubreddit: posts.posts_subreddit[i],
                                                                            postUser: posts.posts_user[i],
                                                                            postThumbnail: posts.posts_thumbnail_url[i],
                                                                            postHasThumbnail: posts.posts_has_thumbnail[i],
                                                                            postVideo: posts.posts_video[i],
                                                                            postIsImagePost: posts.posts_image[i],
                                                                            postIsLinkPost: posts.posts_link[i],
                                                                            postTimeAgoString: posts.posts_timeagostring[i],
                                                                            postThumbnailWidth: posts.posts_thumbnail_rect[i].x,
                                                                            postThumbnailHeight: posts.posts_thumbnail_rect[i].y,
                                                                            postID: posts.posts_id[i],
                                                                            postFlair: posts.posts_flair[i],
                                                                            pageScore: posts.posts_score[i],
                                                                            hasBeenUpvoted: posts.posts_upvoted[i],
                                                                            hasBeenDownvoted: posts.posts_downvoted[i]
                });
            }
            loadingProgressBar.enabled = false;
        }
    }

    function deleteAllPosts() {
        for(var i = column.children.length; i > 0 ; i--) {
          column.children[i-1].destroy();
        }
        after_token = "";
    }
}
