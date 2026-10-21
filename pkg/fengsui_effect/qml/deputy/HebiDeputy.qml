// 烽燧燎原 · 合璧特效（主动把副将换成配对武将）
// 由 skills/fengsui_effect_deputy.lua 挂钩 compat.askToHebiOrTransform 后调用：
//   loadData({ main, deputy, kingdom, skillName, title })
// 构图与「变更副将」同一套语言：主将在左、新副将在右，
// 两张卡各自从外侧相向而来、合拢于中缝，中缝处玉璧炸开。
// 素材：image/Effect/Companion（40 帧玉璧，自带「珠联璧合」篆字）

import QtQuick
import Qt5Compat.GraphicalEffects

import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Components

Item {
  id: root
  anchors.fill: parent

  property string mainName: "anjiang"
  property string deputyName: "anjiang"
  property string kingdom: "qun"
  property string title: ""
  property bool dataReady: false

  readonly property real cardScale: 1.55
  readonly property real pairOffset: 84 // 合拢后的最终偏移
  readonly property real openOffset: 116 // 相向而来时的中间位置

  readonly property color jadeColor: "#5DCAA5"
  readonly property color kColor: {
    switch (root.kingdom) {
      case "wei":  return "#4A90D9";
      case "shu":  return "#D9534F";
      case "wu":   return "#3FA45B";
      case "jin":  return "#8C7BD8";
      case "wild": return "#C08A2E";
      default:     return "#8E8A80";
    }
  }
  readonly property bool mainKnown: root.mainName !== "" && root.mainName !== "anjiang"
  readonly property bool deputyKnown: root.deputyName !== "" && root.deputyName !== "anjiang"

  // 中心横坐标 → 元素 x（缩放以中心为原点，故用未缩放的 93/2 对齐）
  function cardX(offset) {
    return root.width / 2 + offset - 93 / 2;
  }

  function finish() {
    if (roomScene.bigAnim.item === root) {
      roomScene.bigAnim.source = "";
    }
  }

  function resetCards() {
    root.opacity = 1;
    dim.opacity = 0;
    jade.opacity = 0;
    jade.curr = 0;
    seam.opacity = 0;
    bond.opacity = 0;
    titleText.opacity = 0;
    titleText.y = root.height / 2 - 232;

    mainCard.y = root.height / 2 - 65;
    deputyCard.y = root.height / 2 - 65;
    mainCard.scale = root.cardScale;
    deputyCard.scale = root.cardScale;
    mainCard.x = -93 - 180;
    deputyCard.x = root.width + 180;
    mainCard.opacity = 0;
    deputyCard.opacity = 0;
  }

  function loadData(d) {
    d = d || {};
    root.mainName = d.main || "anjiang";
    root.deputyName = d.deputy || "anjiang";
    root.kingdom = d.kingdom || "qun";
    root.title = d.title || "";
    root.dataReady = true;
    root.resetCards();
    hebiSeq.restart();
  }

  Timer {
    interval: 300
    running: true
    repeat: false
    onTriggered: {
      if (!root.dataReady) root.finish();
    }
  }

  Rectangle {
    id: dim
    anchors.fill: parent
    color: "black"
    opacity: 0
  }

  // 玉璧：在卡片之下，作为「璧」的底盘，自带走马篆字
  Image {
    id: jade
    width: 430
    height: 430
    x: root.width / 2 - width / 2
    y: root.height / 2 - height / 2
    fillMode: Image.PreserveAspectFit
    opacity: 0
    z: 1
    property int curr: 0
    source: "../../image/Effect/Companion/Companion" + curr + ".png"
  }

  GeneralCardItem {
    id: mainCard
    scale: root.cardScale
    opacity: 0
    z: 2
    dataModel: Ltk.createGeneralCardModel(
      root.mainKnown ? root.mainName : "diaochan",
      { detailed: false, known: root.mainKnown })
  }

  GeneralCardItem {
    id: deputyCard
    scale: root.cardScale
    opacity: 0
    z: 2
    dataModel: Ltk.createGeneralCardModel(
      root.deputyKnown ? root.deputyName : "diaochan",
      { detailed: false, known: root.deputyKnown })
  }

  // 卡缝处的一线玉光
  Rectangle {
    id: seam
    width: 2
    height: 130 * root.cardScale
    anchors.centerIn: parent
    color: root.jadeColor
    opacity: 0
    z: 3
  }

  // 两卡之间的「合」线（势力色）
  Rectangle {
    id: bond
    width: root.pairOffset * 2 - 93 * root.cardScale + 2
    height: 2
    anchors.centerIn: parent
    color: root.kColor
    opacity: 0
    z: 3
  }

  GlowText {
    id: titleText
    text: root.title
    visible: root.title !== ""
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height / 2 - 232
    font.family: Config.libianName
    font.pixelSize: 36
    font.bold: true
    color: "#DFF7EC"
    glow.color: root.jadeColor
    glow.spread: 0.85
    opacity: 0
    z: 5
  }

  SequentialAnimation {
    id: hebiSeq
    running: false

    // 0 – 160 暗场
    NumberAnimation { target: dim; property: "opacity"; to: 0.5; duration: 160 }

    // 160 – 620 主将与新副将从两侧相向而来
    ParallelAnimation {
      NumberAnimation { target: mainCard; property: "x"; to: root.cardX(-openOffset)
                        duration: 460; easing.type: Easing.OutCubic }
      NumberAnimation { target: deputyCard; property: "x"; to: root.cardX(openOffset)
                        duration: 460; easing.type: Easing.OutCubic }
      NumberAnimation { target: mainCard; property: "opacity"; to: 1; duration: 200 }
      NumberAnimation { target: deputyCard; property: "opacity"; to: 1; duration: 200 }
      NumberAnimation { target: bond; property: "opacity"; to: 0.8; duration: 300 }
    }

    // 620 – 880 合拢成璧
    ParallelAnimation {
      NumberAnimation { target: mainCard; property: "x"; to: root.cardX(-pairOffset)
                        duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: deputyCard; property: "x"; to: root.cardX(pairOffset)
                        duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: bond; property: "opacity"; to: 1; duration: 160 }
    }

    // 880 – 1760 玉璧爆发
    ParallelAnimation {
      NumberAnimation { target: jade; property: "opacity"; to: 1; duration: 120 }
      NumberAnimation { target: jade; property: "curr"; to: 39; duration: 880 }
      SequentialAnimation {
        PauseAnimation { duration: 80 }
        NumberAnimation { target: seam; property: "opacity"; to: 0.9; duration: 120 }
        NumberAnimation { target: seam; property: "opacity"; to: 0; duration: 280 }
      }
      SequentialAnimation {
        PauseAnimation { duration: 140 }
        NumberAnimation { target: mainCard; property: "scale"; to: 1.62; duration: 320
                          easing.type: Easing.OutBack }
        NumberAnimation { target: deputyCard; property: "scale"; to: 1.62; duration: 320
                          easing.type: Easing.OutBack }
      }
    }

    // 1760 – 2000 名号
    ParallelAnimation {
      NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: 200 }
      NumberAnimation { target: titleText; property: "y"; to: root.height / 2 - 220
                        duration: 240; easing.type: Easing.OutCubic }
    }
    PauseAnimation { duration: 300 }

    ParallelAnimation {
      NumberAnimation { target: root; property: "opacity"; to: 0; duration: 240 }
      NumberAnimation { target: dim; property: "opacity"; to: 0; duration: 240 }
    }
    ScriptAction { script: root.finish() }
  }
}
