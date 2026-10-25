import QtQuick
import QtQuick.Window

// 大梦仙尊：用户提供的成品横幅（透明PNG，2172x724）按原字节显示，不抠图、不改字。
// 组件设计尺寸与共享显示框一致（110x30），图片按宽度铺满：
// 上下透明留边吸收大部分溢出，实际内容仅裁约3.4%。
// 服务器设置其他名称时使用纯文本回退，不显示图片内固定的原名。
Item {
  id: badge
  property string title: "大梦仙尊"
  property bool motionEnabled: true
  implicitWidth: 110
  implicitHeight: 30
  readonly property real displayScale: Math.max(0, Math.min(width / implicitWidth,
                                                          height / implicitHeight))
  readonly property string displayTitle: title.replace(/^【|】$/g, "")
  readonly property bool standard: displayTitle === "大梦仙尊"
  // 溢出窗口的取位：0=贴顶，1=贴底；0.4125 让上下内容裁切均衡。
  readonly property real cropBias: 0.4125

  Item {
    id: frame
    anchors.centerIn: parent
    width: badge.implicitWidth * badge.displayScale
    height: badge.implicitHeight * badge.displayScale
    clip: true

    Image {
      id: artwork
      objectName: "dreamingsaintArtwork"
      width: frame.width
      height: width * 724 / 2172
      y: -(height - frame.height) * badge.cropBias
      source: "../images/dream_banner.png"
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
        GradientStop { position: 0; color: "#123a5c" }
        GradientStop { position: 1; color: "#0a2337" }
      }
      border.color: "#4fc3e8"
      border.width: Math.max(1, badge.displayScale)
      visible: !badge.standard || artwork.status === Image.Error
      Text {
        objectName: "dreamingsaintFallback"
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
}
