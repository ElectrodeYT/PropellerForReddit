var redditPostComponent

function createPosts() {
    // TODO: actual reddit API shit
    redditPostComponent = Qt.createComponent("../RedditPost.qml")
    if(redditPostComponent.status == Component.Ready) {
        console.log("creating posts without delay")
        finishCreatePosts()
    } else if(redditPostComponent.status == Component.Error) {
        console.log("Error loading component: ", redditPostComponent.errorString())
    } else {
        redditPostComponent.statusChanged.connect(finishCreatePosts)
        console.log("registered post component status change callback")
    }
}

function finishCreatePosts() {
    console.log("finishCreatePosts() top")
    if(redditPostComponent.status == Component.Ready) {
        for(let i = 0; i < 50; i++) {
            var postTitle = "Test Post " + i
            var redditPostObject = redditPostComponent.createObject(column, {postName: postTitle, postDisplayWidth: postsPage.width })
        }
    } else if(redditPostComponent.status == Component.Error) {
        console.log("Error loading component: ", redditPostComponent.errorString())
    }
}
