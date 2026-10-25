import QtQuick
import QtQuick.Window

// 窃香郎：用户提供的成品横幅（透明PNG，2167x726）按原字节显示，不抠图、不改字。
// 组件设计尺寸与共享显示框一致（110x30），图片按宽度铺满、cropBias 取景：
// 上下透明留边吸收部分溢出。服务器设置其他名称时使用纯文本回退。
Item {
  id: badge
  property string title: "窃香郎"
  property bool motionEnabled: true
  implicitWidth: 110
  implicitHeight: 30
  readonly property real displayScale: Math.max(0, Math.min(width / implicitWidth,
                                                          height / implicitHeight))
  readonly property string displayTitle: title.replace(/^【|】$/g, "")
  readonly property bool standard: displayTitle === "窃香郎"
  // 溢出窗口的取位：0=贴顶，1=贴底。
  readonly property real cropBias: 0.55

  Item {
    id: frame
    anchors.centerIn: parent
    width: badge.implicitWidth * badge.displayScale
    height: badge.implicitHeight * badge.displayScale
    clip: true

    Image {
      id: artwork
      objectName: "qiexianglangArtwork"
      width: frame.width
      height: width * 726 / 2167
      y: -(height - frame.height) * badge.cropBias
      source: "../images/qiexiang_banner.png"
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
        GradientStop { position: 0; color: "#3a2a63" }
        GradientStop { position: 1; color: "#241a42" }
      }
      border.color: "#c9a6f0"
      border.width: Math.max(1, badge.displayScale)
      visible: !badge.standard || artwork.status === Image.Error
      Text {
        objectName: "qiexianglangFallback"
        anchors.fill: parent
        anchors.margins: 3 * badge.displayScale
        text: badge.displayTitle
        textFormat: Text.PlainText
        font.family: "serif"
        font.bold: true
        font.pixelSize: 13 * badge.displayScale
        color: "#f5eaff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }
    }
  }
}
