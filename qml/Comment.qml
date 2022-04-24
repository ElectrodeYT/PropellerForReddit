import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.12
import Ubuntu.Components 1.3

import "."


RowLayout {
    property string commentAuthor: "u/default user"
    property string commentText: "default comment text"
    property int commentDepth: 0
    Layout.fillWidth: true
    Repeater {
        model: commentDepth
        delegate: ToolSeparator{
            orientation: Qt.Vertical
            Layout.fillHeight: true
            padding: 0
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
        ToolSeparator {
            orientation: Qt.Horizontal
            Layout.fillWidth: true
        }
    }
}
