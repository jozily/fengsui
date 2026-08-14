// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Pages.Popups

GraphicsBox {
  id: root

  property var choices: []
  property var allChoices: []
  property string prompt: ""
  property string result: ""

  readonly property real viewportWidth: Ltk.roomScene ? Ltk.roomScene.width : Config.winWidth
  readonly property real viewportHeight: Ltk.roomScene ? Ltk.roomScene.height : Config.winHeight
  readonly property int columnCount: Math.max(2, Math.min(6, Math.floor((width - 28) / 104)))
  readonly property var displayNames: orderedChoices()

  title.text: Ltk.processPrompt(prompt)
  width: Math.min(720, Math.max(300, viewportWidth - 32))
  height: Math.min(440, Math.max(170, viewportHeight * 0.58))

  function flatten(values) {
    const result = [];
    (values || []).forEach(value => {
      if (Array.isArray(value))
        result.push(...flatten(value));
      else
        result.push(value);
    });
    return result;
  }

  function orderedChoices() {
    const available = choices || [];
    const result = [];
    flatten(allChoices).forEach(name => {
      if (available.includes(name) && !result.includes(name))
        result.push(name);
    });
    available.forEach(name => {
      if (!result.includes(name))
        result.push(name);
    });
    return result;
  }

  GridView {
    id: cardGrid
    anchors.fill: parent
    anchors.topMargin: 42
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    anchors.bottomMargin: 12
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    cellWidth: width / root.columnCount
    cellHeight: 58
    model: root.displayNames

    ScrollBar.vertical: ScrollBar {
      policy: cardGrid.contentHeight > cardGrid.height
        ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
    }

    delegate: Item {
      id: tileContainer
      required property string modelData
      width: cardGrid.cellWidth
      height: cardGrid.cellHeight

      Rectangle {
        id: tile
        anchors.centerIn: parent
        width: Math.min(94, parent.width - 8)
        height: 46
        radius: 3
        clip: true
        color: "#d9c79d"
        border.width: root.result === tileContainer.modelData ? 3 : 1
        border.color: root.result === tileContainer.modelData ? "#f5d878" : "#7b542e"

        Image {
          anchors.fill: parent
          anchors.margins: 2
          source: SkinBank.getCardPicture(tileContainer.modelData)
          fillMode: Image.PreserveAspectCrop
          sourceClipRect: Qt.rect(6, 48, 88, 46)
        }

        Rectangle {
          anchors.fill: parent
          color: tileHover.hovered ? "#22ffffff" : "transparent"
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 22
          color: "#99000000"
        }

        Text {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: 3
          text: Lua.tr(tileContainer.modelData)
          color: "#fff4d2"
          font.family: Config.li2Name
          font.pixelSize: 14
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }

        HoverHandler {
          id: tileHover
          cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
          gesturePolicy: TapHandler.WithinBounds
          onTapped: {
            root.result = tileContainer.modelData;
            root.close();
          }
        }
      }
    }
  }
}
