import QtQuick
import QtQuick.Window

// 青魁幽梦：用户提供的横幅（1920x640，翡翠烟云水墨风）抠白底转透明后显示。
// 组件设计尺寸与共享显示框一致（110x30），图片按宽度铺满、cropBias 取景：
// 实际内容需垂直裁约 18%，取偏上位置保住人物脸部与「青魁幽梦」文字。zoom 0.9 框内略缩小留边。
Item {
  id: badge
  property string title: "青魁幽梦"
  property bool motionEnabled: true
  implicitWidth: 110
  implicitHeight: 30
  readonly property real displayScale: Math.max(0, Math.min(width / implicitWidth,
                                                          height / implicitHeight))
  readonly property string displayTitle: title.replace(/^【|】$/g, "")
  readonly property bool standard: displayTitle === "青魁幽梦"
  readonly property real zoom: 0.9
  readonly property real cropBias: 0.4

  Item {
    id: frame
    anchors.centerIn: parent
    width: badge.implicitWidth * badge.displayScale * badge.zoom
    height: badge.implicitHeight * badge.displayScale * badge.zoom
    clip: true

    Image {
      id: artwork
      objectName: "qingkuiArtwork"
      width: frame.width
      height: width * 640 / 1920
      y: -(height - frame.height) * badge.cropBias
      source: "../images/qingkui_banner.png"
      fillMode: Image.Stretch
      smooth: true
      mipmap: true
      visible: badge.standard
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
        objectName: "qingkuiFallback"
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
