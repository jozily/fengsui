import QtQuick
import QtQuick.Window

// 极大梦仙尊：在静态横幅基础上烘焙一张 36 帧「斜向流光扫过」图集（bigdream_atlas.png），
// 模仿官方双阴糕手的做法——用 NumberAnimation 驱动 phase，Canvas 每帧从图集切一格绘制。
// 未就绪时显示静态海报（bigdream_poster.png），服务器设置其他名称时显示纯文本回退。
Item {
  id: badge
  property string title: "极大梦仙尊"
  property bool motionEnabled: true
  // 非动画实例停留在流光居中帧。
  property real phase: 0.5
  implicitWidth: 110
  implicitHeight: 30
  readonly property real displayScale: Math.max(0, Math.min(width / implicitWidth,
                                                          height / implicitHeight))
  readonly property string displayTitle: title.replace(/^【|】$/g, "")
  readonly property bool standard: displayTitle === "极大梦仙尊"
  readonly property real zoom: 0.9
  readonly property int frameCount: 36
  readonly property int frameIndex: Math.max(0, Math.min(frameCount - 1, Math.floor(phase * frameCount)))
  onFrameIndexChanged: frameCanvas.requestPaint()

  Item {
    id: frame
    anchors.centerIn: parent
    width: badge.implicitWidth * badge.displayScale * badge.zoom
    height: badge.implicitHeight * badge.displayScale * badge.zoom
    clip: true

    // 图集每格 440x120；等比铺满共享显示框。
    Image {
      id: poster
      objectName: "bigdreamPoster"
      anchors.fill: parent
      source: "../images/bigdream_poster.png"
      fillMode: Image.PreserveAspectFit
      smooth: true; mipmap: true
      visible: !frameCanvas.ready
    }

    Canvas {
      id: frameCanvas
      objectName: "bigdreamAtlas"
      width: 440; height: 120
      transformOrigin: Item.TopLeft
      scale: frame.width / 440
      layer.enabled: true
      layer.mipmap: true
      property bool ready: false
      property int paintedFrame: -1
      readonly property url atlas: Qt.resolvedUrl("../images/bigdream_atlas.png")
      Component.onCompleted: loadImage(atlas)
      onImageLoaded: requestPaint()
      onAvailableChanged: if (available) requestPaint()
      onWidthChanged: if (ready) requestPaint()
      onPaint: {
        if (!isImageLoaded(atlas)) return;
        const ctx = getContext("2d");
        ctx.reset();
        const index = badge.frameIndex;
        const sx = (index % 6) * 440;
        const sy = Math.floor(index / 6) * 120;
        ctx.drawImage(atlas, sx, sy, 440, 120, 0, 0, 440, 120);
        paintedFrame = index;
        ready = true;
      }
    }

    // 服务器改名或图集加载失败时的纯文本回退。
    Rectangle {
      anchors.fill: parent
      radius: 3 * badge.displayScale
      gradient: Gradient {
        GradientStop { position: 0; color: "#123a5c" }
        GradientStop { position: 1; color: "#0a2337" }
      }
      border.color: "#4fc3e8"
      border.width: Math.max(1, badge.displayScale)
      visible: !badge.standard
      Text {
        objectName: "bigdreamingsaintFallback"
        anchors.fill: parent
        anchors.margins: 3 * badge.displayScale
        text: badge.displayTitle
        textFormat: Text.PlainText
        font.family: "serif"
        font.bold: true
        font.pixelSize: 13 * badge.displayScale
        color: "#e6f8ff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }
    }
  }

  NumberAnimation {
    objectName: "bigdreamClock"
    target: badge; property: "phase"
    from: 0; to: 1
    duration: 2400
    loops: Animation.Infinite
    running: badge.motionEnabled && badge.visible && badge.standard
  }
}
