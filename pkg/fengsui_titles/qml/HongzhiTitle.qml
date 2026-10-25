import QtQuick
import QtQuick.Window

// 鸿志凌空：用户提供的成品横幅（透明PNG，2143x734，墨卷云山版）按原字节显示，不抠图、不改字。
// 组件设计尺寸与共享显示框一致（110x30），图片按宽度铺满、cropBias 取景：
// 上下透明留边吸收部分溢出。zoom 0.9 画面在框内略缩小留边。服务器设置其他名称时使用纯文本回退。
Item {
  id: badge
  property string title: "鸿志凌空"
  property bool motionEnabled: true
  implicitWidth: 110
  implicitHeight: 30
  readonly property real displayScale: Math.max(0, Math.min(width / implicitWidth,
                                                          height / implicitHeight))
  readonly property string displayTitle: title.replace(/^【|】$/g, "")
  readonly property bool standard: displayTitle === "鸿志凌空"
  // 框内缩放：1.0 满框，0.9 略缩小留边（v3 更扁、裁切少，放得更大）。
  readonly property real zoom: 0.9
  // 溢出窗口的取位：0=贴顶，1=贴底。
  readonly property real cropBias: 0.6

  Item {
    id: frame
    anchors.centerIn: parent
    width: badge.implicitWidth * badge.displayScale * badge.zoom
    height: badge.implicitHeight * badge.displayScale * badge.zoom
    clip: true

    Image {
      id: artwork
      objectName: "hongzhilingkongArtwork"
      width: frame.width
      height: width * 734 / 2143
      y: -(height - frame.height) * badge.cropBias
      source: "../images/hongzhi3_banner.png"
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
        GradientStop { position: 0; color: "#2e3138" }
        GradientStop { position: 1; color: "#1b1d22" }
      }
      border.color: "#9aa3b0"
      border.width: Math.max(1, badge.displayScale)
      visible: !badge.standard || artwork.status === Image.Error
      Text {
        objectName: "hongzhilingkongFallback"
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
}
