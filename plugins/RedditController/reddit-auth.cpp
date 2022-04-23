#include <QtQml>
#include <QtQml/QQmlContext>
#include "../../qt-json/json.h"

#include "plugin.h"
#include "reddit-auth.h"


void RedditController::attemptAuth() {
    Q_ASSERT(!busy);
    // Construct request
    current_request = new Request(Request::RequestType::AccessTokenFetch, manager, this);
    current_request->setURL(QUrl("https://www.reddit.com/api/v1/access_token"));
    current_request->setDeviceId(device_id);
    current_request->setClientSecret("");
    current_request->setHttpType(Request::HTTPType::POST);
    if(refresh_token == "") {
        // Add the grant_type and device_id parameters
        current_request->addParameter("grant_type", "https://oauth.reddit.com/grants/installed_client");
        current_request->addParameter("device_id", device_id);
    } else {
        // Attempt a refresh token auth
        current_request->addParameter("grant_type", "refresh_token");
        current_request->addParameter("refresh_token", refresh_token);
    }
    // Setup timeout timer
    timeout_timer->start(5000);
    connect(timeout_timer, &QTimer::timeout, this, &RedditController::onInternalRequestTimeout);

    current_request ->send();
    qDebug() << "before connect";
    connect(current_request , SIGNAL(request_done(QNetworkReply*)), SLOT(onAccessTokenRequestDone(QNetworkReply*)));
    qDebug() << "after connect";
}

bool RedditController::handleOAuthLogin(const QString& url) {
    Q_ASSERT(!busy);
    QUrlQuery url_query(url);
    // Check if we have an error
    QString error = url_query.queryItemValue("error", QUrl::PrettyDecoded);
    if(error != "") {
        qDebug() << "OAUTH returned an error: " << error;
        return false;
    }
    // Now we can read the code
    QString code = url_query.queryItemValue("code", QUrl::PrettyDecoded);
    if(code == "") { qDebug() << "code not existant"; return ""; }
    qDebug() << "code: " << code;
    // The code can contain "#_" at the end, so if it does we ax it
    if(code.endsWith("#_", Qt::CaseSensitive)) {
        code.remove(code.size() - 2, 2);
    }
    qDebug() << "truncated code: " << code;
    // We can now deauth, and reauth with the new oauth code
    authed = false;

    current_request = new Request(Request::RequestType::AccessTokenFetch, manager, this);
    current_request->setURL(QUrl("https://www.reddit.com/api/v1/access_token"));
    current_request->setDeviceId(device_id);
    current_request->setHttpType(Request::HTTPType::POST);
    current_request->addParameter("code", code);
    current_request->addParameter("redirect_uri", "http://propeller/");
    current_request->addParameter("grant_type", "authorization_code");

    // Setup timeout timer
    timeout_timer->start(5000);
    connect(timeout_timer, &QTimer::timeout, this, &RedditController::onInternalRequestTimeout);

    current_request->send();
    connect(current_request , SIGNAL(request_done(QNetworkReply*)), SLOT(onAccessTokenRequestDone(QNetworkReply*)));
    return true;
}

void RedditController::onAccessTokenRequestDone(QNetworkReply* reply) {
    timeout_timer->stop();
    if(reply->error() == QNetworkReply::NoError) {
        qDebug() << "access token request returned no error: " << reply->error();
    } else {
        qDebug() << "access token requested returned error: " << reply->error();
        emit requestFailed(reply->errorString());
        return;
    }
    const QString replyString = QString::fromUtf8(reply->readAll());
    qDebug() << "full reply: ";
    qDebug() << replyString;

    if(reply->error() != QNetworkReply::NoError) { return; }

    bool parse_ok;

    // Try to parse the JSON
    const QVariantMap replyJson = QtJson::parse(replyString, parse_ok).toMap();
    if(replyJson.contains("error")) {
        qDebug() << "error fetching access token: " << replyJson.value("error").toString();
        emit requestFailed(replyJson.value("error").toString());
        return;
    }
    if(replyJson.contains("access_token")) {
        access_token = replyJson.value("access_token").toString();
    } else {
        access_token = "";
    }

    if(replyJson.contains("refresh_token")) {
        refresh_token = replyJson.value("refresh_token").toString();
    } else {
        refresh_token = "";
    }

    emit refreshTokenChanged(refresh_token);
    if(replyJson.contains("expires_in")) {
        access_token_refresh_timer->start(replyJson.value("expires_in").toUInt() * 999); // Slightly less so that we refresh before the token expires
        connect(access_token_refresh_timer, SIGNAL(timeout()), SLOT(onAccessTokenRefreshTimerFire()));
    }
    qDebug() << "Access token: " << access_token;
    if(!refresh_token.isEmpty()) {
        qDebug() << "Refresh token: " << refresh_token;
    }
    if(!access_token.isEmpty()) {
        authed = true;
        emit authedChanged();
    }
}

void RedditController::onAccessTokenRefreshTimerFire() {
    qDebug() << "access token refresh timer fired";

    if(refresh_token.isEmpty()) {
        // We basically just fetch a new access token
        // Construct request
        Request* request = new Request(Request::RequestType::AccessTokenFetch, manager, this);
        request->setURL(QUrl("https://www.reddit.com/api/v1/access_token"));
        request->setDeviceId(device_id);
        request->setClientSecret("");
        request->setHttpType(Request::HTTPType::POST);
        request->addParameter("grant_type", "https://oauth.reddit.com/grants/installed_client");
        request->addParameter("device_id", device_id);
        request->send();
        qDebug() << "before refresh connect";
        connect(request, SIGNAL(request_done(QNetworkReply*)), SLOT(onAccessTokenRequestDone(QNetworkReply*)));
        qDebug() << "after refresh connect";
    } else {
        Request* request = new Request(Request::RequestType::AccessTokenFetch, manager, this);
        request->setURL(QUrl("https://www.reddit.com/api/v1/access_token"));
        request->setDeviceId(device_id);
        request->setClientSecret("");
        request->setHttpType(Request::HTTPType::POST);
        request->addParameter("grant_type", "refresh_token");
        request->addParameter("refresh_token", refresh_token);
        request->send();
        qDebug() << "before refresh connect";
        connect(request, SIGNAL(request_done(QNetworkReply*)), SLOT(onAccessTokenRequestDone(QNetworkReply*)));
        qDebug() << "after refresh connect";
    }
}
