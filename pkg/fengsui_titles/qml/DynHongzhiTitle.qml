import QtQuick
import QtQuick.Window

// 动·鸿志凌空：在静态横幅基础上烘焙一张 36 帧「水墨晕染」图集（dynhongzhi_atlas.png），
// 模仿官方双阴糕手的 atlas + Canvas 逐帧切格做法。墨团在水中晕开扩散、飞白墨点明灭，
// 与墨卷云山底图呼应。未就绪时显示静态海报（dynhongzhi_poster.png），
// 服务器设置其他名称时显示纯文本回退。
Item {
  id: badge
  property string title: "动·鸿志凌空"
  property bool motionEnabled: true
  property real phase: 0.5
  implicitWidth: 110
  implicitHeight: 30
  readonly property real displayScale: Math.max(0, Math.min(width / implicitWidth,
                                                          height / implicitHeight))
  readonly property string displayTitle: title.replace(/^【|】$/g, "")
  readonly property bool standard: displayTitle === "动·鸿志凌空"
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

    Image {
      id: poster
      objectName: "dynhongzhiPoster"
      anchors.fill: parent
      source: "../images/dynhongzhi_poster.png"
      fillMode: Image.PreserveAspectFit
      smooth: true; mipmap: true
      visible: !frameCanvas.ready
    }

    Canvas {
      id: frameCanvas
      objectName: "dynhongzhiAtlas"
      width: 440; height: 120
      transformOrigin: Item.TopLeft
      scale: frame.width / 440
      layer.enabled: true
      layer.mipmap: true
      property bool ready: false
      readonly property url atlas: Qt.resolvedUrl("../images/dynhongzhi_atlas.png")
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
        ready = true;
      }
    }

    // 服务器改名或图集加载失败时的纯文本回退。
    Rectangle {
      anchors.fill: parent
      radius: 3 * badge.displayScale
      gradient: Gradient {
        GradientStop { position: 0; color: "#2e3138" }
        GradientStop { position: 1; color: "#1b1d22" }
      }
      border.color: "#9aa3b0"
      border.width: Math.max(1, badge.displayScale)
      visible: !badge.standard
      Text {
        objectName: "dynhongzhilingkongFallback"
        anchors.fill: parent
        anchors.margins: 3 * badge.displayScale
        text: badge.displayTitle
        textFormat: Text.PlainText
        font.family: "serif"
        font.bold: true
        font.pixelSize: 13 * badge.displayScale
        color: "#eef1f5"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }
    }
  }

  NumberAnimation {
    objectName: "dynhongzhiClock"
    target: badge; property: "phase"
    from: 0; to: 1
    duration: 3000
    loops: Animation.Infinite
    running: badge.motionEnabled && badge.visible && badge.standard
  }
}
