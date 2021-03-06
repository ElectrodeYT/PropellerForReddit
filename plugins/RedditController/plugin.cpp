#include <QtQml>
#include <QtQml/QQmlContext>
#include <QQuickItem>

#include "plugin.h"
#include "reddit-auth.h"

#if defined (Q_WS_SIMULATOR)
    QString user_agent = "qt-simulator:propeller.alexanderrichards:v1.0.3-git"
#else
    QString user_agent = "propeller.alexanderrichards:v1.0.3 (Ubuntu Touch)";
#endif

//
// STOLEN FROM QUICKDDIT
//
// REPLACE AT SOME POINT
QByteArray toEncodedQuery(const QHash<QString, QString> &parameters)
{
    QByteArray encodedQuery;
    QHashIterator<QString, QString> i(parameters);
    while (i.hasNext()) {
        i.next();
        encodedQuery += QUrl::toPercentEncoding(i.key()) + '=' + QUrl::toPercentEncoding(i.value()) + '&';
    }
    encodedQuery.chop(1); // chop the last '&'
    return encodedQuery;
}

//
// PARTIALLY STOEN FROM STACKOVERFLOW
//
QString secondsToString(qint64 time_seconds) {
    const qint64 DAY = 86400;
    QTime t = QTime(0,0).addSecs(time_seconds % DAY);
    qint64 days = time_seconds / DAY;
    qint64 hours = t.hour();
    qint64 minutes = t.minute();
    qint64 seconds = t.second();
    // We go with the highest, non zero one
    if(days) {
        return QString("%1 days ago").arg(days);
    } else if(hours) {
        return QString("%1 hours ago").arg(hours);
    } else if(minutes) {
        return QString("%1 minutes ago").arg(minutes);
    } else if(seconds) {
        return QString("%1 seconds ago").arg(seconds);
    } else {
        return QString("Just now");
    }
}

void RedditControllerPlugin::registerTypes(const char *uri) {
    //@uri RedditController
    qmlRegisterSingletonType<RedditController>(uri, 1, 0, "RedditController", [](QQmlEngine*, QJSEngine*) -> QObject* { return new RedditController; });
}

RedditController::RedditController() {
    qDebug() << "RedditController constructor";
    manager = new QNetworkAccessManager();
    access_token_refresh_timer = new QTimer(this);
    access_token_refresh_timer->setSingleShot(true);
    timeout_timer = new QTimer(this);
    timeout_timer->setSingleShot(true);
}

bool RedditController::initReddit() {
    qDebug() << "init reddit!";
    qmlRegisterInterface<RedditPostContainer>("RedditPostContainer");
    attemptAuth();
    return false;
}


void RedditController::sendRequest(const QString& url, const char* handler, const Request& request) {

}

void RedditController::getPosts(QString subreddit, QObject* parents_of_reddit_posts) {
    Q_ASSERT(isAuthed());
    Q_ASSERT(!isBusy());
    busy = true;
    qDebug() << "getting posts from " + subreddit;

    // Construct the JSON url
    QString url = "https://oauth.reddit.com/" + subreddit + ".json?limit=50&raw_json=1";

    current_request = new Request(Request::RequestType::Normal, manager, this);
    current_request->setAccessToken(access_token);
    current_request->setURL(QUrl(url));
    current_request->setHttpType(Request::HTTPType::GET);

    current_request->send();
    connect(current_request, &Request::request_done, this, &RedditController::onPostsRequestReceived);
}

void RedditController::getMorePosts(QString subreddit, QString after) {
    Q_ASSERT(isAuthed());
    Q_ASSERT(!isBusy());
    busy = true;
    qDebug() << "getting more posts from " + subreddit;

    // Construct the JSON url
    QString url = "https://oauth.reddit.com/" + subreddit + ".json?limit=50&raw_json=1&after=" + after;

    current_request = new Request(Request::RequestType::Normal, manager, this);
    current_request->setAccessToken(access_token);
    current_request->setURL(QUrl(url));
    current_request->setHttpType(Request::HTTPType::GET);

    current_request->send();
    connect(current_request, &Request::request_done, this, &RedditController::onPostsRequestReceived);
}

void RedditController::getSubredditSearch(QString search) {
    Q_ASSERT(isAuthed());
    Q_ASSERT(!isBusy());
    busy = true;
    qDebug() << "searching for subreddits; search text=" + search;

    QString url = "https://oauth.reddit.com/subreddits/search/.json?limit=50&q=\"" + search + "\"";
    current_request = new Request(Request::RequestType::Normal, manager, this);
    current_request->setAccessToken(access_token);
    current_request->setURL(QUrl(url));
    current_request->setHttpType(Request::HTTPType::GET);

    current_request->send();
    connect(current_request, &Request::request_done, this, &RedditController::onSubredditSearchRequestReceived);
}

void RedditController::getPostsFromSubredditSearch(QString subreddit, QString search) {
    Q_ASSERT(isAuthed());
    Q_ASSERT(!isBusy());
    busy = true;
    qDebug() << "getting more search results from " + subreddit;

    // Construct the JSON url
    QString url = "https://oauth.reddit.com/" + subreddit + "/search.json?limit=50&raw_json=1&restrict_sr=on&q=\"" + search + "\"";

    current_request = new Request(Request::RequestType::Normal, manager, this);
    current_request->setAccessToken(access_token);
    current_request->setURL(QUrl(url));
    current_request->setHttpType(Request::HTTPType::GET);

    current_request->send();
    connect(current_request, &Request::request_done, this, &RedditController::onPostsRequestReceived);
}

void RedditController::getMorePostsFromSubredditSearch(QString subreddit, QString search, QString after) {
    Q_ASSERT(isAuthed());
    Q_ASSERT(!isBusy());
    busy = true;
    qDebug() << "getting posts from " + subreddit;

    // Construct the JSON url
    QString url = "https://oauth.reddit.com/" + subreddit + "/search.json?limit=50&raw_json=1&restrict_sr=on&q=\"" + search + "\"&after=" + after;

    current_request = new Request(Request::RequestType::Normal, manager, this);
    current_request->setAccessToken(access_token);
    // current_request->setAccessToken("");
    current_request->setURL(QUrl(url));
    current_request->setHttpType(Request::HTTPType::GET);

    current_request->send();
    connect(current_request, &Request::request_done, this, &RedditController::onPostsRequestReceived);
}

void RedditController::getCommentsFromPost(QString post_id) {
    Q_ASSERT(isAuthed());
    Q_ASSERT(!isBusy());
    busy = true;
    qDebug() << "getting comments from " + post_id;

    // The code can contain "t3_" at the beginning (type identifer), so if it does we ax it
    if(post_id.startsWith("t3_", Qt::CaseSensitive)) {
        post_id.remove(0, 3);
    }

    // Construct the JSON url
    QString url = "https://oauth.reddit.com/comments/" + post_id + ".json?limit=50&raw_json=1";
    qDebug() << "comment url: " << url;
    current_request = new Request(Request::RequestType::Normal, manager, this);
    current_request->setAccessToken(access_token);
    // current_request->setAccessToken("");
    current_request->setURL(QUrl(url));
    current_request->setHttpType(Request::HTTPType::GET);

    current_request->send();
    connect(current_request, &Request::request_done, this, &RedditController::onCommentsRequestReceived);
}

void RedditController::cancelRequest() {
    if(current_request) {
        current_request->cancelRequest();
        current_request->disconnect();
        delete current_request;
        current_request = NULL;
    }
}

QString RedditController::getBestThumbnail(QtJson::JsonObject json) {
    // If a GIF version exists, we want to use that
    // TODO: bodge the QML to make MP4 work, since they should be smaller & higher quality
    if(json.contains("variants") && json["variants"].toMap().contains("gif")) {
        return json["variants"].toMap()["gif"].toMap()["source"].toMap()["url"].toString();
    }
    // else, we just return the source image
    return json["source"].toMap()["url"].toString();
}

void RedditController::addComment(RedditCommentsContainer& comments, QtJson::JsonObject json, int depth) {
    QString body = json["body_html"].toString();
    QString id = json["id"].toString();
    QString author = "u/" + json["author"].toString();
    int ups = json["ups"].toInt();
    int downs = json["downs"].toInt();
    int score = json["score"].toInt();
    bool upvoted = json["likes"].toBool();
    bool downvoted = !json["likes"].toBool();
    if(json["likes"].isNull()) { upvoted = false; downvoted = false; }
    comments.comments.push_back(body);
    comments.comments_id.push_back(id);
    comments.comments_name.push_back(author);
    comments.comments_depth.push_back(depth);
    comments.comments_ups.push_back(ups);
    comments.comments_downs.push_back(downs);
    comments.comments_score.push_back(score);
    comments.comments_upvoted.push_back(upvoted);
    comments.comments_downvoted.push_back(downvoted);
    // Check if we have any replies
    if(json.contains("replies")) {
        foreach(QVariant child, json["replies"].toMap()["data"].toMap()["children"].toList()) {
            QtJson::JsonObject comment_container = child.toMap();
            if(comment_container["kind"].toString() == "more") {
                qDebug() << "TODO: handle the more comments tag bit";
                break;
            }
            QtJson::JsonObject data = comment_container["data"].toMap();
            addComment(comments, data, depth + 1);
        }
    }
}

void RedditController::onPostsRequestReceived(QNetworkReply* reply) {
    qDebug() << "onPostsRequestReceived() top";
    RedditPostContainer posts;
    posts.after = "";
    if(!reply) {
        qDebug() << "reddit request timed out";
        emit postsReceived(QVariant::fromValue(posts));
        busy = false;
        return;
    }
    QString replyString = reply->readAll();
    if(reply->error() != QNetworkReply::NoError) {
        qDebug() << "reddit returned error when fetching posts";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit postsReceived(QVariant::fromValue(posts));
        busy = false;
        return;
    }
    bool parse_ok;
    const QVariantMap replyJson = QtJson::parse(replyString, parse_ok).toMap();
    if(!parse_ok) {
        qDebug() << "reddit didnt return valid JSON for subreddit";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit postsReceived(QVariant::fromValue(posts));
        busy = false;
        return;
    }

    // Check if this is a listing
    if(!replyJson.contains("kind") || replyJson.value("kind").toString() != "Listing") {
        qDebug() << "reddit didnt return valid listing for subreddit";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit postsReceived(QVariant::fromValue(posts));
        busy = false;
        return;
    }

    QtJson::JsonObject data = replyJson.value("data").toMap();
    posts.after = data["after"].toString();
    posts.dist = data["dist"].toInt(&parse_ok);
    if(!parse_ok) {
        qDebug() << "reddit didnt return valid after or dist for subreddit";
        qDebug() << "full log: ";
        qDebug() << replyString;
        qDebug() << "after: " << posts.after;
        qDebug() << "dist: " << posts.dist;
        qDebug() << "dist string: " << data["dist"].toString();
        posts.after = "";
        emit postsReceived(QVariant::fromValue(posts));
        busy = false;
        return;
    }
    if(!data.contains("children")) {
        qDebug() << "data does not contain children";
    }
    QtJson::JsonObject children = data["children"].toMap();

    // Current UNIX timestamp
    uint64_t unix_timestamp = QDateTime::currentSecsSinceEpoch();

    // The RedditPost component
    int i = 0;
    foreach(QVariant child, data["children"].toList()) {
        QtJson::JsonObject post_container = child.toMap();
        if(!post_container.contains("data")) {
            qDebug() << "post container does not contain data";
        }
        QtJson::JsonObject post = post_container["data"].toMap();
        QString title = post["title"].toString();
        QString subreddit = post["subreddit_name_prefixed"].toString();
        QString user = post["author"].toString();
        QString name = post["name"].toString();
        QString selftext = post["selftext_html"].toString();
        QString preview_text = post["selftext"].toString();
        QString thumbnail = post["thumbnail"].toString();
        QString post_hint = post["post_hint"].toString();
        QString video = "";
        QString flair = post["link_flair_text"].toString();
        QDateTime post_time = QDateTime::fromSecsSinceEpoch(post["created"].toLongLong());
        QString post_time_string = secondsToString(unix_timestamp - post["created"].toLongLong());
        bool is_image_post = (post_hint == "image");
        bool is_link_post = (post_hint == "link");
        bool has_thumbnail = is_link_post;
        QVector2D thumbnail_rect(0, 0);
        int score = post["score"].toInt();
        bool upvoted = post["likes"].toBool();
        bool downvoted = !post["likes"].toBool();
        if(post["likes"].isNull()) { upvoted = false; downvoted = false; }
        // qDebug() << "post " << i << " title: " << title << " self text: " << selftext;

        // If there are any images / if this post only has images then we simply prepend them to the selftext
        // TODO: handle the images in preview properly instead of just using source
        // TODO: handle post_hint better
        //       my guesses:
        //        "image" -> image
        //        "hosted:video" -> reddit video
        //        "rich:video" -> not-reddit hosted video

        // We now source the highest quality possible, (animated) image, video or link preview
        if(is_image_post) {
            // preview_text = "Image Post";
            QVariantList preview_images = post["preview"].toMap()["images"].toList();
            QtJson::JsonObject first_preview_image = preview_images[0].toMap();
            QtJson::JsonObject source = first_preview_image["source"].toMap();
            thumbnail = getBestThumbnail(first_preview_image);
            thumbnail_rect.setX(source["width"].toInt());
            thumbnail_rect.setY(source["height"].toInt());
        } else if(is_link_post) {
            // This is a link, fetch the preview image for the thumbnail
            QVariantList preview_images = post["preview"].toMap()["images"].toList();
            QtJson::JsonObject first_preview_image = preview_images[0].toMap();
            QtJson::JsonObject source = first_preview_image["source"].toMap();
            thumbnail = getBestThumbnail(first_preview_image);
            thumbnail_rect.setX(source["width"].toInt());
            thumbnail_rect.setY(source["height"].toInt());
            preview_text = "Link";
        } else if(post_hint == "hosted:video") {
            // Fetch the main url and add it as the video url
            video = post["media"].toMap()["reddit_video"].toMap()["dash_url"].toString();
            preview_text = "Video Post";

            // Get the thumbnail
            QVariantList preview_images = post["preview"].toMap()["images"].toList();
            QtJson::JsonObject first_preview_image = preview_images[0].toMap();
            QtJson::JsonObject source = first_preview_image["source"].toMap();
            thumbnail = getBestThumbnail(first_preview_image);
            thumbnail_rect.setX(source["width"].toInt());
            thumbnail_rect.setY(source["height"].toInt());
            has_thumbnail = true;
        } else if(post_hint == "rich:video") {
            // there is a html embed in oembed
            QtJson::JsonObject oembed = post["media"].toMap()["oembed"].toMap();
            selftext = oembed["html"].toString();
            if(oembed.contains("thumbnail_url") && !oembed["thumbnail_url"].isNull()) {
                thumbnail = oembed["thumbnail_url"].toString();
                thumbnail_rect.setX(oembed["thumbnail_width"].toInt());
                thumbnail_rect.setY(oembed["thumbnail_height"].toInt());
                has_thumbnail = true;
            }
            preview_text = "External Video";
        } else if(post_hint == "") {
            // This subreddit does not have thumbnails enabled, and as such we cant rely on
            // the post_hint attribute to create a thumbnail.
            // TODO: auto-detect thumbnail without post_hint
        } else if(post_hint != "") {
            qDebug() << "unknown post hint: " << post_hint;
        }

        if(thumbnail == "nsfw") {
            has_thumbnail = false;
            thumbnail = "";
            preview_text = "[Spoiler]";
        } else if(thumbnail == "self") {
            has_thumbnail = false;
            thumbnail = "";
        }

        posts.posts.push_back(title);
        posts.posts_dec.push_back(preview_text);
        posts.posts_id.push_back(name);
        posts.posts_selftext.push_back("<html>" + selftext + "</html>");
        posts.posts_subreddit.push_back(subreddit);
        posts.posts_user.push_back(user);
        posts.posts_thumbnail_url.push_back(thumbnail);
        posts.posts_has_thumbnail.push_back(has_thumbnail);
        posts.posts_video.push_back(video);
        posts.posts_image.push_back(is_image_post);
        posts.posts_link.push_back(is_link_post);
        posts.posts_datetime.push_back(post_time);
        posts.posts_timeagostring.push_back(post_time_string);
        posts.posts_thumbnail_rect.push_back(thumbnail_rect);
        posts.posts_flair.push_back(flair);
        posts.posts_score.push_back(score);
        posts.posts_upvoted.push_back(upvoted);
        posts.posts_downvoted.push_back(downvoted);
        i++;
    }

    qDebug() << "before";
    if(current_request) {
        current_request->disconnect();
        delete current_request;
        current_request = NULL;
    }
    qDebug() << "after";
    busy = false;
    emit postsReceived(QVariant::fromValue(posts));
}

void RedditController::onSubredditSearchRequestReceived(QNetworkReply* reply){
    qDebug() << "onSubredditSearchRequestReceived";
    RedditSubredditsSearchContainer subreddits;
    if(!reply) {
        qDebug() << "reddit request timed out";
        emit subredditsSearchReceived(QVariant::fromValue(subreddits));
        busy = false;
        return;
    }
    QString replyString = reply->readAll();
    if(reply->error() != QNetworkReply::NoError) {
        qDebug() << "reddit returned error when fetching posts";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit subredditsSearchReceived(QVariant::fromValue(subreddits));
        busy = false;
        return;
    }
    bool parse_ok;
    const QVariantMap replyJson = QtJson::parse(replyString, parse_ok).toMap();
    if(!parse_ok) {
        qDebug() << "reddit didnt return valid JSON for subreddit";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit subredditsSearchReceived(QVariant::fromValue(subreddits));
        busy = false;
        return;
    }

    // Check if this is a listing
    if(!replyJson.contains("kind") || replyJson.value("kind").toString() != "Listing") {
        qDebug() << "reddit didnt return valid listing for subreddit";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit subredditsSearchReceived(QVariant::fromValue(subreddits));
        busy = false;
        return;
    }

    QtJson::JsonObject data = replyJson.value("data").toMap();
    subreddits.after = data["after"].toString();
    subreddits.dist = data["dist"].toInt(&parse_ok);
    if(!parse_ok) {
        qDebug() << "reddit didnt return valid after or dist for subreddit";
        qDebug() << "full log: ";
        qDebug() << replyString;
        qDebug() << "after: " << subreddits.after;
        qDebug() << "dist: " << subreddits.dist;
        qDebug() << "dist string: " << data["dist"].toString();
        subreddits.after = "";
        emit subredditsSearchReceived(QVariant::fromValue(subreddits));
        busy = false;
        return;
    }
    if(!data.contains("children")) {
        qDebug() << "data does not contain children";
    }
    QtJson::JsonObject children = data["children"].toMap();
    int i = 0;
    foreach(QVariant child, data["children"].toList()) {
        QtJson::JsonObject subreddit_container = child.toMap();
        if(!subreddit_container.contains("data")) {
            qDebug() << "post container does not contain data";
        }
        QtJson::JsonObject subreddit = subreddit_container["data"].toMap();

        QString subreddit_name = subreddit["display_name_prefixed"].toString();

        subreddits.subreddits.push_back(subreddit_name);
        i++;
    }
    busy = false;
    emit subredditsSearchReceived(QVariant::fromValue(subreddits));
}

void RedditController::onCommentsRequestReceived(QNetworkReply* reply) {
    qDebug() << "onCommentsRequestReceived() top";
    RedditCommentsContainer comments;
    if(!reply) {
        qDebug() << "reddit request timed out";
        emit postsReceived(QVariant::fromValue(comments));
        busy = false;
        return;
    }
    QString replyString = reply->readAll();
    if(reply->error() != QNetworkReply::NoError) {
        qDebug() << "reddit returned error when fetching comments";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit postsReceived(QVariant::fromValue(comments));
        busy = false;
        return;
    }
    bool parse_ok;
    const QVariantMap replyJson = QtJson::parse(replyString, parse_ok).toMap();
    if(!parse_ok) {
        qDebug() << "reddit didnt return valid JSON for comment request";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit postsReceived(QVariant::fromValue(comments));
        busy = false;
        return;
    }
    if(replyJson.contains("error")) {
        qDebug() << "reddit returned error for comment request: " << replyJson["error"].toString();
        emit commentsReceived(QVariant::fromValue(comments));
        busy = false;
        return;
    }

    // Comments replies contain 2 listings
    QVariantList listings = QtJson::parse(replyString).toList();
    if(listings.count() != 2) {
        qDebug() << "reddit didnt return json array for comment request";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit postsReceived(QVariant::fromValue(comments));
        busy = false;
        return;
    }
    // We are only interrested in the second listing
    // The first one is only a copy of the post
    // TODO: maybe update the post with this listing?
    QtJson::JsonObject comments_listing = listings[1].toMap();

    // Check if this is a listing
    if(!comments_listing.contains("kind") || comments_listing.value("kind").toString() != "Listing") {
        qDebug() << "reddit didnt return valid listing for subreddit";
        qDebug() << "full log: ";
        qDebug() << replyString;
        emit postsReceived(QVariant::fromValue(comments));
        busy = false;
        return;
    }

    QtJson::JsonObject data = comments_listing["data"].toMap();
    comments.dist = data["dist"].toInt(&parse_ok);
    // While comments do contain a "after" and a "dist" entry, they seem to be null at least most of the time
    if(!data.contains("children")) {
        qDebug() << "data does not contain children";
    }
    QtJson::JsonObject children = data["children"].toMap();

    // Current UNIX timestamp
    uint64_t unix_timestamp = QDateTime::currentSecsSinceEpoch();
    foreach(QVariant child, data["children"].toList()) {
        QtJson::JsonObject comment_container = child.toMap();
        if(comment_container["kind"].toString() == "more") {
            qDebug() << "TODO: handle the more comments tag bit";
            break;
        }
        QtJson::JsonObject data = comment_container["data"].toMap();
        addComment(comments, data, 0);
    }
    comments.dist = comments.comments.count();
    qDebug() << "amount of comments: " << comments.dist;
    emit commentsReceived(QVariant::fromValue(comments));
    busy = false;
}

void RedditController::submitCommentVote(QString comment_id, int dir) {
    Request* vote_request = new Request(Request::RequestType::Normal, manager, this);
    vote_request->setAccessToken(access_token);
    vote_request->setURL(QUrl("https://oauth.reddit.com/api/vote"));
    vote_request->setHttpType(Request::HTTPType::POST);
    // vote_request->setDeviceId(device_id);
    vote_request->addParameter("dir", QString::number(dir));
    vote_request->addParameter("id", comment_id);
    vote_request->addParameter("rank", "2");
    vote_request->send();
    connect(vote_request, &Request::request_done, this, &RedditController::onVoteRequestReceived);
    qDebug() << "setting vote status of " << comment_id << " to " << QString::number(dir);
}

void RedditController::onVoteRequestReceived(QNetworkReply* reply) {
    qDebug() << "Reply to vote request: ";
    qDebug() << reply->readAll();
    qDebug() << reply->error();
}

void RedditController::onInternalRequestTimeout() {
    // Cancel the network request; we really do not want the reply to come _after_ the network request timed out
    current_request->cancelRequest();
    current_request->disconnect();
    delete current_request;
    current_request = NULL;
    qDebug() << "internal request timeout fired";
    emit requestTimedOut();
    busy = false;
}

void Request::send() {
    // Some sanity stuff
    Q_ASSERT(reply == 0);
    if(request_type == RequestType::AccessTokenFetch) {
        Q_ASSERT(!device_id.isEmpty());
        Q_ASSERT(http_type == HTTPType::POST);
    }

    // Create request
    request.setUrl(request_url);
    request.setRawHeader("User-Agent", user_agent.toLatin1());
    if(request_type == RequestType::AccessTokenFetch) {
        // Create auth structure
        QByteArray auth_header;
        auth_header = "Basic " + (client_id.toLatin1() + ":" + client_secret.toLatin1()).toBase64();
        request.setRawHeader("Authorization", auth_header);
    } else if(request_type == RequestType::Normal) {
        if(!access_token.isEmpty()) {
            QByteArray auth_header;
            auth_header = "Bearer " + access_token.toLatin1();
            request.setRawHeader("Authorization", auth_header);
        }
    }

    if(http_type == HTTPType::POST) {
        request.setRawHeader("Content-Type", "application/x-www-form-urlencoded");
        reply = manager->post(request, toEncodedQuery(parameters));
    } else if(http_type == HTTPType::GET) {
        reply = manager->get(request);
    } else {
        qDebug() << "Request::send(): invalid http type!";
    }

    reply->setParent(this);
    connect(reply, SIGNAL(finished()), SLOT(on_request_done()));
}

void Request::cancelRequest() {
    reply->disconnect();
    reply->abort();
}

void Request::on_request_done() {
    QByteArray remaining = reply->rawHeader("X-Ratelimit-Remaining");
    QByteArray reset = reply->rawHeader("X-Ratelimit-Reset");
    qDebug() << "Reddit Rate Limit: Remaining: " << remaining.constData() << " Reset: " << reset.constData();

    emit request_done(reply);
}
