import QtQuick
import QtQuick.Window

// 御坂美琴：用户提供的成品横幅（透明PNG，1916x821）按原字节显示，不抠图、不改字。
// 组件设计尺寸与共享显示框一致（110x30），图片按宽度铺满。
// 原图内容比例偏方（2.38），铺满需垂直裁切约36%；经预览对比取 bias=0.25：
// 保住角色脸部、拳头与右侧完整文字，只裁掉上下多余的电光特效。
// 服务器设置其他名称时使用纯文本回退，不显示图片内固定的原名。
Item {
  id: badge
  property string title: "御坂美琴"
  property bool motionEnabled: true
  implicitWidth: 110
  implicitHeight: 30
  readonly property real displayScale: Math.max(0, Math.min(width / implicitWidth,
                                                          height / implicitHeight))
  readonly property string displayTitle: title.replace(/^【|】$/g, "")
  readonly property bool standard: displayTitle === "御坂美琴"
  // 溢出窗口的取位：0=贴顶，1=贴底；0.25 偏上保住头部。
  readonly property real cropBias: 0.25

  Item {
    id: frame
    anchors.centerIn: parent
    width: badge.implicitWidth * badge.displayScale
    height: badge.implicitHeight * badge.displayScale
    clip: true

    Image {
      id: artwork
      objectName: "misakamikotoArtwork"
      width: frame.width
      height: width * 821 / 1916
      y: -(height - frame.height) * badge.cropBias
      source: "../images/misaka_banner.png"
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
        GradientStop { position: 0; color: "#4a3208" }
        GradientStop { position: 1; color: "#2c1e05" }
      }
      border.color: "#f0b13a"
      border.width: Math.max(1, badge.displayScale)
      visible: !badge.standard || artwork.status === Image.Error
      Text {
        objectName: "misakamikotoFallback"
        anchors.fill: parent
        anchors.margins: 3 * badge.displayScale
        text: badge.displayTitle
        textFormat: Text.PlainText
        font.family: "serif"
        font.bold: true
        font.pixelSize: 13 * badge.displayScale
        color: "#fff3d6"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }
    }
  }
}
