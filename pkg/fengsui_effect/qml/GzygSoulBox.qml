// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Fk
import Fk.Components.Common
import LunarLtk.Components
import LunarLtk.Pages.Popups
import LunarLtk

GraphicsBox {
  id: root

  property var cards: []
  property var availableCards: []
  property string result: ""
  property var kingdoms: [
    "all", "wei", "shu", "wu", "qun", "wild", "dual"
  ]
  property string currentKingdom: "all"
  property var cardsByKingdom: ({
    all: [],
    wei: [],
    shu: [],
    wu: [],
    qun: [],
    wild: [],
    dual: [],
  })
  property var displayCards: cardsByKingdom[currentKingdom] || []
  property int columns: Math.min(7, Math.max(4, displayCards.length))
  property int rows: Math.max(1, Math.ceil(Math.max(displayCards.length, 1) / 7))
  property string currentUIPackage: {
    const ui = (Config.enabledUIPackages && Config.enabledUIPackages["lunarltk"])
      ? Config.enabledUIPackages["lunarltk"]
      : "default";
    if (ui !== "default" && ui !== "lunarltk-qsgs-ui") return "default";
    return ui;
  }
  property bool sunGodAvailable: Fs.exists(
    Cpp.path + "/packages/lunarltk-qsgs-ui/image/selfArea/buttons/choice-button-left.png"
  )
  property bool useSunGodUI: currentUIPackage === "lunarltk-qsgs-ui" && sunGodAvailable

  title.text: ""
  width: Math.max(40 + columns * 100, kingdomBar.implicitWidth + 30)
  height: 86 + Math.min(2.2, rows) * 140

  function rebuildCardsByKingdom() {
    const grouped = {
      all: [],
      wei: [],
      shu: [],
      wu: [],
      qun: [],
      wild: [],
      dual: [],
    };
    cards.forEach(general => {
      const data = Ltk.getGeneralData(general);
      const kingdom = data && data.kingdom;
      const sub = data && data.subkingdom;
      grouped.all.push(general);
      if (sub) {
        grouped.dual.push(general);
        if (grouped[kingdom])
          grouped[kingdom].push(general);
        if (grouped[sub])
          grouped[sub].push(general);
      } else if (grouped[kingdom]) {
        grouped[kingdom].push(general);
      }
    });
    cardsByKingdom = grouped;

    let preferred = "";
    if (result && result !== "yigui-chooce") {
      const selectedData = Ltk.getGeneralData(result);
      if (
        selectedData &&
        grouped[selectedData.kingdom] &&
        grouped[selectedData.kingdom].length > 0
      ) {
        preferred = selectedData.kingdom;
      }
    }
    if (
      !preferred &&
      grouped[currentKingdom] &&
      grouped[currentKingdom].length > 0
    ) {
      preferred = currentKingdom;
    }
    if (!preferred) {
      for (const kingdom of kingdoms) {
        if (grouped[kingdom] && grouped[kingdom].length > 0) {
          preferred = kingdom;
          break;
        }
      }
    }
    currentKingdom = preferred || "all";
  }

  onCardsChanged: rebuildCardsByKingdom()
  onResultChanged: rebuildCardsByKingdom()
  Component.onCompleted: rebuildCardsByKingdom()

  component QsgsKingdomTabButton: Item {
    id: qsgsRoot
    property bool enabled: true
    property bool selected: false
    property alias text: imgText.text
    signal clicked

    property real imgScale: 222 / 65

    height: 28
    width: Math.max(imgText.width + 1.2 * height, height * imgScale)
    opacity: enabled ? (selected ? 1 : 0.82) : 0.55
    scale: selected ? 1.05 : 1

    Image {
      id: leftImg
      source: Cpp.path + "/packages/lunarltk-qsgs-ui/image/selfArea/buttons/choice-button-left.png"
      height: qsgsRoot.height
      fillMode: Image.PreserveAspectFit
    }

    Image {
      id: rightImg
      source: Cpp.path + "/packages/lunarltk-qsgs-ui/image/selfArea/buttons/choice-button-right.png"
      height: qsgsRoot.height
      anchors.right: parent.right
      fillMode: Image.PreserveAspectFit
    }

    Image {
      source: Cpp.path + "/packages/lunarltk-qsgs-ui/image/selfArea/buttons/choice-button-middle.png"
      anchors.left: leftImg.right
      anchors.right: rightImg.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
    }

    Glow {
      source: imgText
      anchors.fill: imgText
      color: "black"
      spread: 0.9
      radius: 2.5
    }

    Text {
      id: imgText
      text: "Button"
      color: "#eee9d4"
      font.pixelSize: 12
      font.bold: true
      font.letterSpacing: 1
      width: implicitWidth
      anchors.verticalCenter: parent.verticalCenter
    }

    Component.onCompleted: {
      if (height * imgScale - (imgText.width + 1.2 * height) > 0 && imgText.text.length > 1) {
        if (imgText.text.length > 3) {
          imgText.width = height * imgScale * 0.75;
        } else if (imgText.text.length === 3) {
          imgText.width = height * imgScale * 0.55;
        } else if (imgText.text.length === 2) {
          imgText.width = height * imgScale * 0.42;
        }
        imgText.font.letterSpacing = 0;
        const pureWidth = imgText.width - imgText.implicitWidth;
        imgText.font.letterSpacing = pureWidth / (imgText.text.length - 1);
        imgText.width = imgText.implicitWidth - imgText.font.letterSpacing;
      }
      imgText.x = qsgsRoot.width / 2 - imgText.width / 2 + 2;
    }

    BrightnessContrast {
      anchors.fill: parent
      source: parent
      brightness: hover.hovered ? 0.3 : -0.4
      contrast: hover.hovered ? 0 : -0.4
      visible: qsgsRoot.enabled && hover.hovered
    }

    HoverHandler {
      id: hover
      cursorShape: qsgsRoot.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    MouseArea {
      anchors.fill: parent
      enabled: qsgsRoot.enabled
      onClicked: qsgsRoot.clicked()
    }

    Desaturate {
      anchors.fill: qsgsRoot
      source: qsgsRoot
      desaturation: 1.0
      visible: !qsgsRoot.enabled
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: 2
      color: "transparent"
      radius: height / 2
      border.width: qsgsRoot.selected ? 2 : 0
      border.color: "#E4D5A0"
      visible: qsgsRoot.selected
    }

    Behavior on opacity {
      NumberAnimation {
        duration: 120
        easing.type: Easing.OutQuad
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: 120
        easing.type: Easing.OutQuad
      }
    }
  }

  Row {
    id: kingdomBar
    anchors.top: parent.top
    anchors.topMargin: 10
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 12

    Repeater {
      model: root.kingdoms

      Item {
        id: kingdomTab
        required property string modelData
        property string kingdom: modelData
        property bool selected: root.currentKingdom === kingdom
        property bool hasCards: (root.cardsByKingdom[kingdom] || []).length > 0
        width: root.useSunGodUI ? qsgsTab.width : defaultTab.width
        height: root.useSunGodUI ? qsgsTab.height : defaultTab.height

        MetroButton {
          id: defaultTab
          width: (kingdomTab.kingdom === "all"
            || kingdomTab.kingdom === "dual")
            ? 74 : 54
          height: 34
          visible: !root.useSunGodUI
          enabled: kingdomTab.hasCards
          text: kingdomTab.kingdom === "all"
            ? qsTr("\u5168\u90e8")
            : kingdomTab.kingdom === "wild"
              ? qsTr("\u91ce")
              : kingdomTab.kingdom === "dual"
                ? qsTr("\u53cc\u52bf\u529b")
                : Lua.tr(kingdomTab.kingdom)
          backgroundColor: kingdomTab.selected
            ? "white" : "black"
          textColor: kingdomTab.selected ? "black" : "white"
          border.color: kingdomTab.selected ? "#E4D5A0" : "white"
          border.width: kingdomTab.selected ? 3 : 2
          opacity: enabled ? 1 : 0.2

          onClicked: {
            if (!enabled) return;
            root.currentKingdom = kingdomTab.kingdom;
          }
        }

        QsgsKingdomTabButton {
          id: qsgsTab
          visible: root.useSunGodUI
          enabled: kingdomTab.hasCards
          selected: kingdomTab.selected
          text: kingdomTab.kingdom === "all"
            ? qsTr("\u5168\u90e8")
            : kingdomTab.kingdom === "wild"
              ? qsTr("\u91ce")
              : kingdomTab.kingdom === "dual"
                ? qsTr("\u53cc\u52bf\u529b")
                : Lua.tr(kingdomTab.kingdom)

          onClicked: {
            if (!enabled) return;
            root.currentKingdom = kingdomTab.kingdom;
          }
        }
      }
    }
  }

  Rectangle {
    id: cardArea
    anchors.top: kingdomBar.bottom
    anchors.topMargin: 16
    anchors.left: parent.left
    anchors.leftMargin: 15
    anchors.right: parent.right
    anchors.rightMargin: 15
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 15

    color: "#88EEEEEE"
    radius: 10

    GridView {
      anchors.fill: parent
      anchors.margins: 5
      clip: true
      cellWidth: 98
      cellHeight: 135
      model: root.displayCards

      delegate: GeneralCardItem {
        required property string modelData
        dataModel: Ltk.createGeneralCardModel(modelData)
        selectable: root.availableCards.includes(modelData)

        onClicked: {
          if (!selectable) return;
          root.result = modelData;
          root.close();
        }

        onRightClicked: {
          Ltk.roomScene.showInfoPopup(
            Qt.createComponent(
              "LunarLtk.Pages.InfoPopups",
              "GeneralDetail"),
            { generals: [modelData] });
        }
      }
    }
  }
}
