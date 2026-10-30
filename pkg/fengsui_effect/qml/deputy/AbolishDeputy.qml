// 烽燧燎原 · 废除副将特效
// loadData({ general, title })：显示被废除的原副将，铁链交叉后盖上“废”。
import QtQuick
import Qt5Compat.GraphicalEffects
import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Components

Item {
  id: root
  anchors.fill: parent
  property string generalName: "anjiang"
  property string removedName: "anjiang"
  property string title: ""
  property bool dataReady: false

  function finish() {
    if (roomScene.bigAnim.item === root) roomScene.bigAnim.source = ""
  }
  function loadData(d) {
    d = d || {}
    root.generalName = d.general || "anjiang"
    root.removedName = d.removed || "anjiang"
    root.title = d.title || ""
    root.dataReady = true
    root.resetAnim()
    abolishSeq.restart()
  }
  function resetAnim() {
    root.opacity = 1
    dim.opacity = 0
    deputyCard.opacity = 0
    deputyCard.scale = 1.35
    removedCard.opacity = 0
    removedCard.scale = 1.35
    chains.opacity = 0
    chains.scale = 0.7
    abolishSeal.opacity = 0
    abolishSeal.scale = 0.72
    abolishText.opacity = 0
    abolishText.scale = 1.8
  }

  GeneralCardItem {
    id: deputyCard
    anchors.verticalCenter: parent.verticalCenter
    x: root.width / 2 + 25
    scale: 1.35
    opacity: 0
    z: 2
    dataModel: Ltk.createGeneralCardModel(
      root.generalName !== "" && root.generalName !== "anjiang" ? root.generalName : "diaochan",
      { detailed: false, known: root.generalName !== "" && root.generalName !== "anjiang" })

    // 士兵牌用带废字印记的整卡图（blank_*_abolished.png，自带铁链+废印）。
    // 主图已还原为干净原版（供移除副将使用），废除特效在这里叠加废字版。
    Image {
      anchors.fill: parent
      anchors.margins: -1
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
      z: 10
      visible: root.generalName === "blank_shibing" || root.generalName === "blank_nvshibing"
      source: root.generalName === "blank_nvshibing"
        ? "../../image/abolish/blank_nvshibing_abolished.png"
        : "../../image/abolish/blank_shibing_abolished.png"
    }
  }

  GeneralCardItem {
    id: removedCard
    anchors.verticalCenter: parent.verticalCenter
    x: root.width / 2 - 165
    scale: 1.35
    opacity: 0
    z: 2
    dataModel: Ltk.createGeneralCardModel(
      root.removedName !== "" && root.removedName !== "anjiang" ? root.removedName : "diaochan",
      { detailed: false, known: root.removedName !== "" && root.removedName !== "anjiang" })
  }

  Rectangle { id: dim; anchors.fill: parent; color: "#090507"; opacity: 0; z: 1 }

  // 两条带有链节纹理的铁链交叉覆盖副将牌（士兵牌已用整卡废字图时隐藏，避免重复）。
  Item {
    id: chains
    anchors.centerIn: deputyCard
    width: 220; height: 220
    z: 4
    opacity: 0
    scale: 0.7
    visible: root.generalName !== "blank_shibing" && root.generalName !== "blank_nvshibing"
    Repeater {
      model: 2
      delegate: Item {
        width: 250; height: 28
        anchors.centerIn: parent
        rotation: index === 0 ? 45 : -45
        Rectangle {
          anchors.fill: parent
          color: "#211719"
          radius: 10
          border.width: 4
          border.color: "#8E3030"
        }
        Row {
          anchors.centerIn: parent
          spacing: 11
          Repeater {
            model: 6
            delegate: Rectangle {
              width: 25; height: 13; radius: 7
              color: "transparent"
              border.width: 3
              border.color: "#D58B67"
              rotation: (index % 2 === 0) ? 0 : 90
            }
          }
        }
      }
    }
  }

  // 用户提供的血链交错废印，覆盖在被废除的副将牌上（士兵牌已用整卡废字图时隐藏）。
  Image {
    id: abolishSeal
    anchors.centerIn: deputyCard
    width: 185
    height: 278
    fillMode: Image.PreserveAspectFit
    source: "../../image/abolish/abolish_seal.png"
    opacity: 0
    scale: 0.72
    z: 4
    visible: root.generalName !== "blank_shibing" && root.generalName !== "blank_nvshibing"
  }

  GlowText {
    id: abolishText
    anchors.centerIn: deputyCard
    text: "废"
    font.pixelSize: 126
    font.bold: true
    color: "#C51624"
    glow.color: "#4C0308"
    glow.spread: 0.9
    opacity: 0
    visible: false
    z: 5
  }

  GlowText {
    id: titleText
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height / 2 + 128
    text: root.title
    visible: root.title !== ""
    font.family: Config.libianName
    font.pixelSize: 32
    font.bold: true
    color: "#F6E7D4"
    glow.color: "#B51D2A"
    opacity: 0
    z: 6
  }

  Timer {
    interval: 300; running: true; repeat: false
    onTriggered: { if (!root.dataReady) root.finish() }
  }

  SequentialAnimation {
    id: abolishSeq
    running: false
    ParallelAnimation {
      NumberAnimation { target: dim; property: "opacity"; to: 0.68; duration: 170 }
      NumberAnimation { target: deputyCard; property: "opacity"; to: 1; duration: 220 }
      NumberAnimation { target: removedCard; property: "opacity"; to: 1; duration: 220 }
      NumberAnimation { target: deputyCard; property: "scale"; to: 1.55; duration: 260; easing.type: Easing.OutBack }
    }
    ParallelAnimation {
      NumberAnimation { target: chains; property: "opacity"; to: 1; duration: 180 }
      NumberAnimation { target: chains; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutBack }
      NumberAnimation { target: abolishSeal; property: "opacity"; to: 1; duration: 180 }
      NumberAnimation { target: abolishSeal; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutBack }
    }
    ParallelAnimation {
      NumberAnimation { target: abolishText; property: "opacity"; to: 1; duration: 140 }
      NumberAnimation { target: abolishText; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack }
    }
    ParallelAnimation {
      NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: 180 }
      PauseAnimation { duration: 320 }
    }
    PauseAnimation { duration: 360 }
    ParallelAnimation {
      NumberAnimation { target: root; property: "opacity"; to: 0; duration: 220 }
      NumberAnimation { target: dim; property: "opacity"; to: 0; duration: 220 }
    }
    ScriptAction { script: root.finish() }
  }
}
