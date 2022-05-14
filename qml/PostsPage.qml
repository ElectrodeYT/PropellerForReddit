import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import RedditController 1.0
import Ubuntu.Components 1.3

Page {
    id: postsPage
    anchors.fill: parent

    property string subreddit : ""

    property string after_token : ""
    property int count : 0

    header: PageHeader {
        id: header
        title: i18n.tr(subreddit == "" ? "Front Page" : subreddit)

        trailingActionBar.actions: [
            Action {
                iconName: "find"
                text: "Search Posts"
                onTriggered: {
                    console.log("opening post search page");
                    // Ensure the reddit controller isnt doing anything
                    RedditController.cancelRequest();
                    var postsPage = Qt.createComponent("PostsSearchPage.qml");
                    if(postsPage.status !== Component.Ready) {
                        console.log("Error loading component: ", openRedditPostComponent.errorString());
                        return;
                    }
                    postsPage.parent = pageStack.parent;
                    var newPage = postsPage.createObject(null, { "subreddit": subreddit } )
                    newPage.parent = pageStack.parent;
                    pageStack.push(newPage);
                }
            },
            Action {
                iconName: "find"
                text: "Search Subreddits"
                onTriggered: {
                    console.log("opening search page");
                    if(loadingProgressBar.visible) {
                        // Abort present reddit request
                        RedditController.cancelRequest()
                    }
                    pageStack.push(Qt.resolvedUrl("SearchPage.qml"));
                }
            },
            // TODO: something that actually requires Settings
            // left here so i dont have to write it again later
            /*Action {
                text: "Settings"
                onTriggered: {
                    console.log("opening search page");
                    if(loadingProgressBar.visible) {
                        // Abort present reddit request
                        RedditController.cancelRequest()
                    }
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
                }
            },*/
            Action {
                text: "Refresh"
                onTriggered: {
                    RedditController.cancelRequest();
                    deleteAllRedditPosts();
                    RedditController.getPosts(subreddit, column);
                    loadingProgressBar.enabled = true
                }
            },
            Action {
                text: "Login"
                enabled: RedditController.refresh_token == ""
                visible: enabled
                onTriggered: {
                    console.log("opening login page");
                    if(loadingProgressBar.visible) {
                        // Abort present reddit request
                        RedditController.cancelRequest()
                    }
                    deleteAllRedditPosts();
                    pageStack.push(Qt.resolvedUrl("LoginPage.qml"));
                }
            },
            Action {
                text: "Logout"
                enabled: RedditController.refresh_token != ""
                visible: enabled
                onTriggered: {
                    console.log("triggering logout");
                    RedditController.cancelRequest();
                    RedditController.refresh_token = "";
                    deleteAllRedditPosts();
                    RedditController.initReddit();
                }
            }

        ]
        trailingActionBar.numberOfSlots: 0


    }

    ProgressBar {
        id: loadingProgressBar
        enabled: true
        visible: enabled
        indeterminate: true
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: units.gu(2)
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
            flickableItem.onAtYEndChanged:   {
                if(flickableItem.atYEnd && !RedditController.isBusy && !loadingProgressBar.enabled && after_token !== "") {
                    RedditController.getMorePosts(subreddit, after_token);
                    loadingProgressBar.enabled = true;
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
        onAuthedChanged: {
            RedditController.getPosts(subreddit, column);
            loadingProgressBar.enabled = true;
        }

        onRequestFailed: {

        }
    }

    Component.onCompleted: {
        RedditController.getPosts(subreddit, column);
        loadingProgressBar.enabled = true;
    }

    function deleteAllRedditPosts() {
        for(var i = column.children.length; i > 0 ; i--) {
          column.children[i-1].destroy();
        }
        after_token = "";
    }
}
