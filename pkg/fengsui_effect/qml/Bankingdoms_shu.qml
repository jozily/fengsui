import QtQuick

Item {
    anchors.fill: parent
    Loader {
        anchors.fill: parent
        source: "Bankingdoms.qml"
        onLoaded: item.kingdoms = "shu"
    }
}
