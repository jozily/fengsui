// 烽燧燎原 · 变更副将特效
// 由 skills/fengsui_effect_deputy.lua 通过 doSuperLightBox 调用：
//   loadData({ main, deputy, changed, isHidden, kingdom, title, tier })
//
// 构图就是「这一对将」：主将在左、副将在右，成对亮起；
// 只有被换掉的那一张（changed）做入场与定型动效，另一张静态陪衬。
// 收尾统一走 finish()，并校验 item === root 以防覆盖后到的新特效。

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
  property string changed: "deputy" // "main" | "deputy"
  property bool isHidden: false
  property string kingdom: "qun"
  property string title: ""
  property string tier: "full"
  property bool dataReady: false

  readonly property real cardScale: 1.55
  readonly property real pairOffset: 84 // 两张卡中心相对屏幕中心的偏移

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

  readonly property var changedCard: root.changed === "main" ? mainCard : deputyCard
  readonly property var otherCard: root.changed === "main" ? deputyCard : mainCard
  readonly property real changedTargetX: root.cardX(root.changed === "main" ? -pairOffset : pairOffset)

  // 两张卡的中心横坐标 → 元素 x（缩放以中心为原点，故用未缩放的 93/2 对齐）
  function cardX(offset) {
    return root.width / 2 + offset - 93 / 2;
  }

  function finish() {
    if (roomScene.bigAnim.item === root) {
      roomScene.bigAnim.source = "";
    }
  }

  // 把每个元素摆到「入场前」的状态；被换的那张从自己那一侧滑进来
  function resetCards() {
    root.opacity = 1;
    dim.opacity = 0;
    ring.opacity = 0;
    ring.scale = 1.22;
    bond.opacity = 0;
    sweep.opacity = 0;
    sweep.curr = 0;
    sweep.scale = 0.92;
    titleText.opacity = 0;
    titleText.y = root.height / 2 + 131;

    mainCard.y = root.height / 2 - 65;
    deputyCard.y = root.height / 2 - 65;
    mainCard.scale = root.cardScale;
    deputyCard.scale = root.cardScale;
    mainCard.opacity = 0;
    deputyCard.opacity = 0;

    if (root.changed === "main") {
      mainCard.x = -93 - 170;
      mainCard.scale = 1.64;
      deputyCard.x = root.cardX(pairOffset);
    } else {
      deputyCard.x = root.width + 170;
      deputyCard.scale = 1.64;
      mainCard.x = root.cardX(-pairOffset);
    }
  }

  function loadData(d) {
    d = d || {};
    root.mainName = d.main || "anjiang";
    root.deputyName = d.deputy || "anjiang";
    root.changed = d.changed === "main" ? "main" : "deputy";
    root.isHidden = d.isHidden === true;
    root.kingdom = d.kingdom || "qun";
    root.title = d.title || "";
    root.tier = d.tier || "full";
    root.dataReady = true;
    root.resetCards();
    if (root.tier === "lite") {
      liteSeq.restart();
    } else {
      fullSeq.restart();
    }
  }

  // 兜底：300ms 内没收到参数就直接收尾，宁可不播，也不要闪出错误的武将。
  Timer {
    interval: 300
    running: true
    repeat: false
    onTriggered: {
      if (!root.dataReady) root.finish();
    }
  }

  // 暗场
  Rectangle {
    id: dim
    anchors.fill: parent
    color: "black"
    opacity: 0
  }

  // 势力色细边，框住这一对将
  Rectangle {
    id: ring
    width: 93 * root.cardScale + root.pairOffset * 2 + 44
    height: 130 * root.cardScale + 44
    anchors.centerIn: parent
    color: "transparent"
    radius: 14
    border.width: 2
    border.color: root.kColor
    opacity: 0
    scale: 1.22
  }

  // 主将
  GeneralCardItem {
    id: mainCard
    scale: root.cardScale
    opacity: 0
    z: 2
    dataModel: Ltk.createGeneralCardModel(
      root.mainKnown ? root.mainName : "diaochan",
      { detailed: false, known: root.mainKnown })
  }

  // 副将（被换掉的那张就是它，除非换的是主将）
  GeneralCardItem {
    id: deputyCard
    scale: root.cardScale
    opacity: 0
    z: 2
    dataModel: Ltk.createGeneralCardModel(
      root.deputyKnown ? root.deputyName : "diaochan",
      { detailed: false, known: root.deputyKnown })
  }

  // 两卡之间的「合」线
  Rectangle {
    id: bond
    width: root.pairOffset * 2 - 93 * root.cardScale + 2
    height: 2
    anchors.centerIn: parent
    color: root.kColor
    opacity: 0
    z: 3
  }

  // 橙金光带（复用包内 anim/transformation，41 帧）
  Image {
    id: sweep
    width: 211 * 1.7
    height: 304 * 1.7
    x: root.width / 2 - width / 2
    y: root.height / 2 - height / 2
    fillMode: Image.PreserveAspectFit
    opacity: 0
    scale: 0.92
    z: 4
    property int curr: 0
    source: "../../image/anim/transformation/" + curr + ".png"
  }

  GlowText {
    id: titleText
    text: root.title
    visible: root.title !== ""
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height / 2 + 131
    font.family: Config.libianName
    font.pixelSize: root.changed === "main" ? 34 : 30
    font.bold: true
    color: "#FDF6E3"
    glow.color: root.kColor
    glow.spread: 0.7
    opacity: 0
    z: 5
  }

  SequentialAnimation {
    id: fullSeq
    running: false

    // 0 – 160 暗场 + 边框聚气 + 陪衬卡亮起
    ParallelAnimation {
      NumberAnimation { target: dim; property: "opacity"; to: 0.55; duration: 160 }
      NumberAnimation { target: ring; property: "opacity"; to: 0.85; duration: 160 }
      NumberAnimation { target: ring; property: "scale"; to: 1.0; duration: 240
                         easing.type: Easing.OutCubic }
      NumberAnimation { target: root.otherCard; property: "opacity"; to: 1; duration: 200 }
    }

    // 160 – 620 被换的将从自己那一侧滑入
    ParallelAnimation {
      NumberAnimation { target: root.changedCard; property: "x"; to: root.changedTargetX
                        duration: 460; easing.type: Easing.OutCubic }
      NumberAnimation { target: root.changedCard; property: "opacity"; to: 1; duration: 180 }
      NumberAnimation { target: bond; property: "opacity"; to: 0.9; duration: 260 }
    }

    // 620 – 1080 光带扫过 + 新将定型（回弹）
    ParallelAnimation {
      NumberAnimation { target: sweep; property: "opacity"; to: 0.95; duration: 80 }
      NumberAnimation { target: sweep; property: "curr"; to: 40; duration: 440 }
      NumberAnimation { target: sweep; property: "scale"; to: 1.06; duration: 440
                        easing.type: Easing.OutCubic }
      NumberAnimation { target: root.changedCard; property: "scale"; to: root.cardScale
                        duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
      NumberAnimation { target: ring; property: "opacity"; to: 0; duration: 380 }
    }

    // 1080 – 1220 光带收势
    NumberAnimation { target: sweep; property: "opacity"; to: 0; duration: 140 }

    // 1220 – 1400 名号
    ParallelAnimation {
      NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: 180 }
      NumberAnimation { target: titleText; property: "y"; to: root.height / 2 + 119
                        duration: 220; easing.type: Easing.OutCubic }
    }
    PauseAnimation { duration: 280 }

    ParallelAnimation {
      NumberAnimation { target: root; property: "opacity"; to: 0; duration: 200 }
      NumberAnimation { target: dim; property: "opacity"; to: 0; duration: 200 }
    }
    ScriptAction { script: root.finish() }
  }

  // 轻量档：不给暗场、不给名号，只留「滑入 + 光带」
  SequentialAnimation {
    id: liteSeq
    running: false

    ParallelAnimation {
      NumberAnimation { target: root.changedCard; property: "x"; to: root.changedTargetX
                        duration: 300; easing.type: Easing.OutCubic }
      NumberAnimation { target: root.changedCard; property: "opacity"; to: 1; duration: 140 }
      NumberAnimation { target: root.otherCard; property: "opacity"; to: 0.9; duration: 140 }
      NumberAnimation { target: sweep; property: "opacity"; to: 0.85; duration: 60 }
      NumberAnimation { target: sweep; property: "curr"; to: 40; duration: 320 }
    }
    ParallelAnimation {
      NumberAnimation { target: sweep; property: "opacity"; to: 0; duration: 120 }
      NumberAnimation { target: root.changedCard; property: "scale"; to: root.cardScale
                        duration: 240; easing.type: Easing.OutBack }
    }
    PauseAnimation { duration: 100 }
    NumberAnimation { target: root; property: "opacity"; to: 0; duration: 150 }
    ScriptAction { script: root.finish() }
  }
}
