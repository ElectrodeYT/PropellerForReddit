import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.12
import Ubuntu.Components 1.3

import "."


ColumnLayout {
    property string commentAuthor: "u/default user"
    property string commentText: "default comment text"

    Layout.fillWidth: true

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

    ToolSeparator {
        orientation: Qt.Horizontal
        Layout.fillWidth: true
    }
}
