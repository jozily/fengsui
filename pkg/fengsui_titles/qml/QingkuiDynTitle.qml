import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects

// 动·青魁幽梦：金粉上浮版。
// 画面本体完全静止（无胀缩、无漂移）；雾气三团青绿软雾原地明灭 + 缓慢漂移；
// 金粉：细碎金粒从底部缓缓上浮、渐隐消散（错峰循环，呼应金字/灯笼/金叶）。
// motionEnabled=false 时完全静止（等同静态版）。
Item {
  id: badge
  property string title: "动·青魁幽梦"
  property bool motionEnabled: true
  implicitWidth: 110
  implicitHeight: 30
  readonly property real displayScale: Math.max(0, Math.min(width / implicitWidth,
                                                          height / implicitHeight))
  readonly property string displayTitle: title.replace(/^【|】$/g, "")
  readonly property bool standard: displayTitle === "动·青魁幽梦" || displayTitle === "青魁幽梦"
  readonly property real zoom: 0.9
  readonly property real cropBias: 0.4
  readonly property bool moving: motionEnabled && standard

  Item {
    id: frame
    anchors.centerIn: parent
    width: badge.implicitWidth * badge.displayScale * badge.zoom
    height: badge.implicitHeight * badge.displayScale * badge.zoom
    clip: true

    Image {
      id: artwork
      objectName: "qingkuiDynArtwork"
      width: frame.width
      height: width * 640 / 1920
      y: -(height - frame.height) * badge.cropBias
      source: "../images/qingkui_banner.png"
      fillMode: Image.Stretch
      smooth: true
      mipmap: true
      visible: badge.standard
    }

    // 极轻的明暗呼吸（无位移）。
    BrightnessContrast {
      anchors.fill: artwork
      source: artwork
      brightness: 0
      contrast: 0
      visible: badge.standard
      SequentialAnimation on brightness {
        running: badge.moving
        loops: Animation.Infinite
        NumberAnimation { to: 0.04; duration: 2200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 2200; easing.type: Easing.InOutSine }
      }
    }

    // 雾气氤氲：三团青绿软雾，原地明灭 + 缓慢漂移（画面本体不动，雾在动）。
    Item {
      id: mist
      anchors.fill: parent
      visible: badge.standard

      Item {
        id: blobA
        width: frame.width * 0.62
        height: frame.height * 0.85
        y: frame.height * 0.05
        SequentialAnimation on x {
          running: badge.moving
          loops: Animation.Infinite
          NumberAnimation { to: frame.width * 0.42; duration: 9500; easing.type: Easing.InOutSine }
          NumberAnimation { to: frame.width * 0.02; duration: 9500; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on opacity {
          running: badge.moving
          loops: Animation.Infinite
          NumberAnimation { to: 1; duration: 4700; easing.type: Easing.InOutSine }
          NumberAnimation { to: 0.45; duration: 4700; easing.type: Easing.InOutSine }
        }
        opacity: 0.7
        RadialGradient {
          anchors.fill: parent
          horizontalRadius: width / 2
          verticalRadius: height / 2
          gradient: Gradient {
            GradientStop { position: 0; color: "#2b6ee7c4" }
            GradientStop { position: 0.55; color: "#146ee7c4" }
            GradientStop { position: 1; color: "#006ee7c4" }
          }
        }
      }

      Item {
        id: blobB
        width: frame.width * 0.52
        height: frame.height * 0.8
        y: frame.height * 0.12
        SequentialAnimation on x {
          running: badge.moving
          loops: Animation.Infinite
          NumberAnimation { to: frame.width * 0.06; duration: 11500; easing.type: Easing.InOutSine }
          NumberAnimation { to: frame.width * 0.5; duration: 11500; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on opacity {
          running: badge.moving
          loops: Animation.Infinite
          NumberAnimation { to: 0.5; duration: 5700; easing.type: Easing.InOutSine }
          NumberAnimation { to: 1; duration: 5700; easing.type: Easing.InOutSine }
        }
        opacity: 0.7
        RadialGradient {
          anchors.fill: parent
          horizontalRadius: width / 2
          verticalRadius: height / 2
          gradient: Gradient {
            GradientStop { position: 0; color: "#269df2d8" }
            GradientStop { position: 0.6; color: "#109df2d8" }
            GradientStop { position: 1; color: "#009df2d8" }
          }
        }
      }

      Item {
        id: blobC
        width: frame.width * 0.5
        height: frame.height * 0.72
        y: frame.height * 0.18
        SequentialAnimation on x {
          running: badge.moving
          loops: Animation.Infinite
          NumberAnimation { to: frame.width * 0.14; duration: 13500; easing.type: Easing.InOutSine }
          NumberAnimation { to: frame.width * 0.44; duration: 13500; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on opacity {
          running: badge.moving
          loops: Animation.Infinite
          NumberAnimation { to: 1; duration: 6700; easing.type: Easing.InOutSine }
          NumberAnimation { to: 0.4; duration: 6700; easing.type: Easing.InOutSine }
        }
        opacity: 0.65
        RadialGradient {
          anchors.fill: parent
          horizontalRadius: width / 2
          verticalRadius: height / 2
          gradient: Gradient {
            GradientStop { position: 0; color: "#21c8fbe9" }
            GradientStop { position: 0.6; color: "#0dc8fbe9" }
            GradientStop { position: 1; color: "#00c8fbe9" }
          }
        }
      }
    }

    // 翡翠流光：一道斜向青绿光带匀速单方向扫过（约 6.5s 一趟），提亮扫过处，不往返。
    Item {
      id: jadeSheen
      anchors.fill: parent
      visible: badge.standard
      Rectangle {
        id: jadeBand
        width: frame.width * 0.24
        height: frame.height * 2.6
        y: -frame.height * 0.8
        rotation: 15
        transformOrigin: Item.Center
        gradient: Gradient {
          GradientStop { position: 0; color: "#007fe0c8" }
          GradientStop { position: 0.35; color: "#2b7fe0c8" }
          GradientStop { position: 0.5; color: "#4db8ffe6" }
          GradientStop { position: 0.65; color: "#2b7fe0c8" }
          GradientStop { position: 1; color: "#007fe0c8" }
        }
        x: -frame.width * 0.65
        SequentialAnimation on x {
          running: badge.moving
          loops: Animation.Infinite
          NumberAnimation {
            from: -frame.width * 0.65
            to: frame.width * 1.3
            duration: 6500
            easing.type: Easing.InOutQuad
          }
          PauseAnimation { duration: 1200 }
        }
      }
    }

    // 金粉上浮：细碎金粒从底部升起、渐隐消散，错峰循环。
    // 每粒参数：x 起始位置比例 / 粒径 / 上升秒数 / 起始延迟。
    Repeater {
      model: [
        { x: 0.06, s: 2.2, d: 3.4, delay: 0.0 },
        { x: 0.14, s: 1.6, d: 2.9, delay: 0.7 },
        { x: 0.22, s: 2.6, d: 3.8, delay: 1.5 },
        { x: 0.31, s: 1.5, d: 3.0, delay: 0.3 },
        { x: 0.39, s: 2.0, d: 3.5, delay: 2.1 },
        { x: 0.48, s: 1.4, d: 2.8, delay: 1.1 },
        { x: 0.56, s: 2.4, d: 3.6, delay: 0.5 },
        { x: 0.65, s: 1.6, d: 3.1, delay: 1.8 },
        { x: 0.73, s: 2.1, d: 3.7, delay: 0.9 },
        { x: 0.81, s: 1.5, d: 2.9, delay: 2.4 },
        { x: 0.89, s: 2.3, d: 3.4, delay: 1.3 },
        { x: 0.95, s: 1.4, d: 3.2, delay: 0.2 }
      ]
      delegate: Rectangle {
        id: particle
        required property var modelData
        readonly property double riseMs: modelData.d * 1000
        readonly property double waitMs: modelData.delay * 1000
        width: modelData.s * badge.displayScale
        height: width
        radius: width / 2
        x: frame.width * modelData.x
        y: frame.height + 2
        color: modelData.s > 2.1 ? "#ffe9b8" : "#f2d98c"
        opacity: 0
        SequentialAnimation on y {
          running: badge.moving
          loops: Animation.Infinite
          PauseAnimation { duration: particle.waitMs }
          NumberAnimation { from: frame.height + 2; to: -3; duration: particle.riseMs; easing.type: Easing.InQuad }
          NumberAnimation { from: -3; to: -3; duration: 400 }
        }
        SequentialAnimation on opacity {
          running: badge.moving
          loops: Animation.Infinite
          PauseAnimation { duration: particle.waitMs }
          NumberAnimation { from: 0; to: 0.85; duration: particle.riseMs * 0.18 }
          NumberAnimation { to: 0.7; duration: particle.riseMs * 0.5 }
          NumberAnimation { to: 0; duration: particle.riseMs * 0.32 }
          NumberAnimation { from: 0; to: 0; duration: 400 }
        }
      }
    }

    // 服务器改名或图片加载失败时的纯文本回退。
    Rectangle {
      anchors.fill: parent
      radius: 3 * badge.displayScale
      gradient: Gradient {
        GradientStop { position: 0; color: "#0e2a26" }
        GradientStop { position: 1; color: "#082120" }
      }
      border.color: "#4db89b"
      border.width: Math.max(1, badge.displayScale)
      visible: !badge.standard || artwork.status === Image.Error
      Text {
        objectName: "qingkuiDynFallback"
        anchors.fill: parent
        anchors.margins: 3 * badge.displayScale
        text: badge.displayTitle
        textFormat: Text.PlainText
        font.family: "serif"
        font.bold: true
        font.pixelSize: 13 * badge.displayScale
        color: "#eafff7"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }
    }
  }
}
