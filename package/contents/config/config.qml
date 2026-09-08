import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance")
        icon: "color-management-symbolic"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Motion")
        icon: "media-playback-start-symbolic"
        source: "configMotion.qml"
    }
    ConfigCategory {
        name: "CAVA"
        icon: "view-process-system-symbolic"
        source: "configCava.qml"
    }
    ConfigCategory {
        name: i18n("General")
        icon: "configure-symbolic"
        source: "configGeneral.qml"
    }
}
