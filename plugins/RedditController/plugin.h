#ifndef REDDITCONTROLLER_PLUGIN_H
#define REDDITCONTROLLER_PLUGIN_H

#include <QQmlExtensionPlugin>
#include <QNetworkAccessManager>
#include <QTimer>
#include <QVector>
#include <QEventLoop>
#include <stdint.h>
#include "../../qt-json/json.h"

static const QString client_id = "JH68M2Oa5sitdIQNvojHWw";

class RedditControllerPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);
};


class Request : public QObject {
    Q_OBJECT
public:
    enum RequestType {
        Normal,
        AccessTokenFetch
    };

    enum HTTPType {
        GET,
        POST
    };

    explicit Request(const RequestType& type, QNetworkAccessManager* man, QObject* parent = 0) : QObject(parent), reply(0), request_type(type), manager(man) { }

    ~Request() {
        // we do not want to yeet manager
    }

    void addParameter(const QString& left, const QString& right) {
        parameters.insert(left, right);
    }
    void setClientSecret(const QString& id) { client_secret = id; }
    void setAccessToken(const QString& token) { access_token = token; }
    void setDeviceId(const QString& id) { device_id = id; }
    void setHttpType(const HTTPType& type) { http_type = type; }
    void setURL(const QUrl& url) { request_url = url; }
    void send();
    void cancelRequest();

    // Basic auth stuff
    bool useBasicAuth;

signals:
    void request_done(QNetworkReply* reply);
private slots:
    void on_request_done();

private:
    QNetworkReply* reply;
    // The API spec _technically_ requires both, but we
    // dont have a client secret as we are a installed application
    // We "send" both for completeness
    QString client_secret;

    // Device ID to send to reddit
    QString device_id;

    // The Reddit access token
    QString access_token;

    // The parameters to use
    QHash<QString, QString> parameters;

    // The type of request
    RequestType request_type;
    HTTPType http_type;

    // Request destination
    QUrl request_url;

    // Timeout timer used to fail requests
    // TODO

    QNetworkAccessManager* manager;
    QNetworkRequest request;
};

// TODO: unstupidify this
// honestly i dont know why i thought this was a good idea
// but it works so hey
class RedditPostContainer {
    Q_GADGET

    Q_PROPERTY(QString after MEMBER after CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts MEMBER posts CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_desc MEMBER posts_dec CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_id MEMBER posts_id CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_selftext MEMBER posts_selftext CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_subreddit MEMBER posts_subreddit CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_user MEMBER posts_user CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_thumbnail_url MEMBER posts_thumbnail_url CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_has_thumbnail MEMBER posts_has_thumbnail CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_video MEMBER posts_video CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_image MEMBER posts_image CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_link MEMBER posts_link CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_datetime MEMBER posts_datetime CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_timeagostring MEMBER posts_timeagostring CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_thumbnail_rect MEMBER posts_thumbnail_rect CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_flair MEMBER posts_flair CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_score MEMBER posts_score CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_upvoted MEMBER posts_upvoted CONSTANT FINAL)
    Q_PROPERTY(QVariantList posts_downvoted MEMBER posts_downvoted CONSTANT FINAL)
    Q_PROPERTY(int dist MEMBER dist CONSTANT FINAL);
public:
    QString after = "";
    QVariantList posts;
    QVariantList posts_dec;
    QVariantList posts_id;
    QVariantList posts_selftext;
    QVariantList posts_subreddit;
    QVariantList posts_user;
    QVariantList posts_thumbnail_url;
    QVariantList posts_has_thumbnail;
    QVariantList posts_video;
    QVariantList posts_image;
    QVariantList posts_link;
    QVariantList posts_datetime;
    QVariantList posts_timeagostring;
    QVariantList posts_thumbnail_rect;
    QVariantList posts_flair;
    QVariantList posts_score;
    QVariantList posts_upvoted;
    QVariantList posts_downvoted;
    int dist = 0;
};

Q_DECLARE_METATYPE(RedditPostContainer)

class RedditSubredditsSearchContainer {
    Q_GADGET
    Q_PROPERTY(QString after MEMBER after CONSTANT FINAL)
    Q_PROPERTY(QVariantList subreddits MEMBER subreddits CONSTANT FINAL)
    Q_PROPERTY(int dist MEMBER dist CONSTANT FINAL);
public:
    QString after = "";
    QVariantList subreddits;
    int dist = 0;
};

Q_DECLARE_METATYPE(RedditSubredditsSearchContainer)

class RedditCommentsContainer {
    Q_GADGET

    Q_PROPERTY(QVariantList comments MEMBER comments CONSTANT FINAL)
    Q_PROPERTY(QVariantList comments_id MEMBER comments_id CONSTANT FINAL)
    Q_PROPERTY(QVariantList comments_name MEMBER comments_name CONSTANT FINAL)
    Q_PROPERTY(QVariantList comments_depth MEMBER comments_depth CONSTANT FINAL)
    Q_PROPERTY(QVariantList comments_score MEMBER comments_score CONSTANT FINAL)
    Q_PROPERTY(QVariantList comments_ups MEMBER comments_ups CONSTANT FINAL)
    Q_PROPERTY(QVariantList comments_downs MEMBER comments_downs CONSTANT FINAL)
    Q_PROPERTY(QVariantList comments_upvoted MEMBER comments_upvoted CONSTANT FINAL)
    Q_PROPERTY(QVariantList comments_downvoted MEMBER comments_downvoted CONSTANT FINAL)
    Q_PROPERTY(int dist MEMBER dist CONSTANT FINAL);

public:
    QVariantList comments;
    QVariantList comments_id;
    QVariantList comments_name;
    QVariantList comments_depth;
    QVariantList comments_score;
    QVariantList comments_ups;
    QVariantList comments_downs;
    QVariantList comments_upvoted;
    QVariantList comments_downvoted;
    int dist = 0;
};

Q_DECLARE_METATYPE(RedditCommentsContainer);

class RedditController: public QObject {
    Q_OBJECT

public:
    RedditController();
    ~RedditController() = default;

    Q_INVOKABLE bool initReddit();
    Q_INVOKABLE void getPosts(QString subreddit, QObject* parents_of_reddit_posts);
    Q_INVOKABLE void getMorePosts(QString subreddit, QString after);

    Q_INVOKABLE void getSubredditSearch(QString search);

    Q_INVOKABLE void getPostsFromSubredditSearch(QString subreddit, QString search);
    Q_INVOKABLE void getMorePostsFromSubredditSearch(QString subreddit, QString search, QString after);

    Q_INVOKABLE void getCommentsFromPost(QString post_id);

    Q_INVOKABLE void submitCommentVote(QString comment_id, int dir);

    Q_INVOKABLE bool handleOAuthLogin(const QString& url);

    Q_INVOKABLE void cancelRequest();
    Q_PROPERTY(bool isAuthed READ isAuthed NOTIFY authedChanged)
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY busyChanged)

    Q_PROPERTY(QString refresh_token MEMBER refresh_token NOTIFY refreshTokenChanged)

    QString device_id = "DO_NOT_TRACK_THIS_DEVICE";

    QNetworkAccessManager* manager;
    QNetworkRequest request;


    void sendRequest(const QString& url, const char* handler, const Request& request);

    void attemptAuth();

    bool isAuthed() { return authed; }
    bool isBusy() { return busy; }

signals:
    void busyChanged();
    void authedChanged();
    void refreshTokenChanged(const QString& new_token);
    void postsReceived(QVariant posts);
    void subredditsSearchReceived(QVariant subreddits);
    void commentsReceived(QVariant comments);
    void requestTimedOut();
    void requestFailed(QString error_string);

private slots:
    void onAccessTokenRequestDone(QNetworkReply* reply);
    void onAccessTokenRefreshTimerFire();
    void onPostsRequestReceived(QNetworkReply* reply);
    void onSubredditSearchRequestReceived(QNetworkReply* reply);
    void onCommentsRequestReceived(QNetworkReply* reply);
    void onVoteRequestReceived(QNetworkReply* reply);

    void onInternalRequestTimeout();
private:
    QString getBestThumbnail(QtJson::JsonObject json);
    void addComment(RedditCommentsContainer& comments, QtJson::JsonObject json, int depth);

    QString access_token;
    QString refresh_token;
    QTimer* access_token_refresh_timer;

    QTimer* timeout_timer;
    Request* current_request;

    bool busy = false;
    bool authed = false;
};

#endif
