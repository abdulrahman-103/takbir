import QtQuick 2.0
import QtQuick.Controls 2.0
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    LayoutMirroring.enabled: plasmoid.configuration.languageIndex === 1
    LayoutMirroring.childrenInherit: true

    property alias cfg_city: cityField.text
    property alias cfg_country: countryField.text
    property alias cfg_notifications: notificationsCheckBox.checked
    property alias cfg_hourFormat: hourFormatCheckBox.checked
    property alias cfg_method: methodField.currentIndex
    property int cfg_school: 0
    property alias cfg_languageIndex: languageField.currentIndex
    property string cfg_locationType
    property string cfg_latitude: ""
    property string cfg_longitude: ""
    property string cfg_ipCity: ""

    Kirigami.FormLayout {
         Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "Location"
                : plasmoid.configuration.languageIndex === 1
                    ? "الموقع"
                    : plasmoid.configuration.languageIndex === 2
                        ? "Konum"
                        : ""
        }        ButtonGroup {
            id: locationTypeGroup
            buttons: [cityRadio, autoRadio]
        }

        RadioButton {
            id: cityRadio
            text: plasmoid.configuration.languageIndex === 0
                ? "City"
                : plasmoid.configuration.languageIndex === 1
                    ? "المدينة"
                    : plasmoid.configuration.languageIndex === 2
                        ? "Şehir"
                        : ""
            property string locationValue: "city"
            checked: cfg_locationType === "city"
            onCheckedChanged: {
                if (checked) {
                    cfg_locationType = locationValue
                }
            }
        }

        TextField {
            id: cityField
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "City: "
                : plasmoid.configuration.languageIndex === 1
                    ? "المدينة: "
                    : plasmoid.configuration.languageIndex === 2
                        ? "Şehir: "
                        : ""
            visible: cityRadio.checked
        }
        TextField {
            id: countryField
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "Country: "
                : plasmoid.configuration.languageIndex === 1
                    ? "البلد :"
                    : plasmoid.configuration.languageIndex === 2
                        ? "Ülke: "
                        : ""
            visible: cityRadio.checked
        }

        RadioButton {
            id: autoRadio
            text: plasmoid.configuration.languageIndex === 0
                ? "Automatic"
                : plasmoid.configuration.languageIndex === 1
                    ? "تلقائي"
                    : plasmoid.configuration.languageIndex === 2
                        ? "Otomatik"
                        : ""
            property string locationValue: "automatic"
            checked: cfg_locationType === "automatic"
            onCheckedChanged: {
                if (checked) {
                    cfg_locationType = locationValue
                }
            }
        }

        Button {
            text: plasmoid.configuration.languageIndex === 0
                            ? "Fetch Coordinates"
                            : plasmoid.configuration.languageIndex === 1
                                ? "الحصول على الإحداثيات"
                                : plasmoid.configuration.languageIndex === 2
                                    ? "Koordinatları Al"
                                    : ""
            visible: autoRadio.checked
            onClicked: {
                var xhr = new XMLHttpRequest();
                xhr.open("GET", "http://ip-api.com/json", true);
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            var response = JSON.parse(xhr.responseText);
                            cfg_latitude = response.lat.toString();
                            cfg_longitude = response.lon.toString();
                            cfg_ipCity = response.city + ", " + response.country;
                            autoCoordinatesLabel.text = plasmoid.configuration.languageIndex === 0
                                ? "Location: " + cfg_ipCity + "\nCoordinates: " + response.lat + ", " + response.lon
                                : plasmoid.configuration.languageIndex === 1
                                    ? "الموقع: " + cfg_ipCity + "\nالإحداثيات: " + response.lat + "، " + response.lon
                                    : plasmoid.configuration.languageIndex === 2
                                        ? "Konum: " + cfg_ipCity + "\nKoordinatlar: " + response.lat + ", " + response.lon
                                        : ""
                        } else {
                            autoCoordinatesLabel.text = plasmoid.configuration.languageIndex === 0
                                ? "Failed to fetch coordinates"
                                : plasmoid.configuration.languageIndex === 1
                                    ? "فشل الحصول على الإحداثيات"
                                    : plasmoid.configuration.languageIndex === 2
                                        ? "Koordinatlar alınamadı"
                                        : ""
                        }
                    }
                };
                xhr.send();
            }
        }

        Label {
            id: autoCoordinatesLabel
            text: plasmoid.configuration.languageIndex === 0
                            ? "Click \"Fetch Coordinates\" to get your location"
                            : plasmoid.configuration.languageIndex === 1
                                ? "انقر على زر \"الحصول على الإحداثيات\" للحصول على موقعك"
                                : plasmoid.configuration.languageIndex === 2
                                    ? "Konumunuzu almak için \"Koordinatları Al\" düğmesine tıklayın"
                                    : ""
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
            visible: autoRadio.checked
        }

        Label {
            text: plasmoid.configuration.languageIndex === 0
                ? "Note: If you are using a VPN, the location will be incorrect"
                : plasmoid.configuration.languageIndex === 1
                    ? "ملاحظة: إذا كنت تستخدم VPN سيكون الموقع غير صحيح"
                    : plasmoid.configuration.languageIndex === 2
                        ? "Not: Eğer bir VPN kullanıyorsanız konum yanlış olacaktır"
                        : ""
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
            visible: autoRadio.checked
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "Calculation Method"
                : plasmoid.configuration.languageIndex === 1
                    ? "طريقة الحساب"
                    : plasmoid.configuration.languageIndex === 2
                        ? "Hesaplama Yöntemi"
                        : ""
        }
         
        ComboBox {
            id: methodField
            
            property var en: [
                "University of Islamic Sciences, Karachi",
                "Islamic Society of North America",
                "Muslim World League",
                "Umm Al-Qura University, Makkah",
                "Egyptian General Authority of Survey",
                "Gulf Region",
                "Kuwait",
                "Qatar",
                "Majlis Ugama Islam Singapura, Singapore",
                "Union Organization Islamic de France",
                "Diyanet İşleri Başkanlığı, Turkey",
                "Spiritual Administration of Muslims of Russia",
                "Moonsighting Committee Worldwide",
                "Dubai, UAE",
                "Jabatan Kemajuan Islam Malaysia",
                "Tunisia",
                "Algeria",
                "Kementerian Agama Republik Indonesia",
                "Morocco",
                "Comunidade Islamica de Lisboa",
                "Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan"
            ]

            property var ar: [
                "جامعة العلوم الإسلامية، كراتشي",
                "الجمعية الإسلامية لأمريكا الشمالية",
                "رابطة العالم الإسلامي",
                "جامعة أم القرى، مكة المكرمة",
                "الهيئة المصرية العامة للمساحة",
                "منطقة الخليج",
                "الكويت",
                "قطر",
                "مجلس الشؤون الإسلامية في سنغافورة",
                "اتحاد المنظمات الإسلامية في فرنسا",
                "رئاسة الشؤون الدينية التركية",
                "الإدارة الدينية لمسلمي روسيا",
                "لجنة رؤية الهلال العالمية",
                "دبي، الامارات",
                "إدارة التنمية الإسلامية الماليزية",
                "تونس",
                "الجزائر",
                "وزارة الشؤون الدينية في جمهورية إندونيسيا",
                "المغرب",
                "المجتمع الإسلامي في لشبونة",
                "وزارة الأوقاف والشؤون والمقدسات الإسلامية، الأردن"
            ]

            property var tr: [
            "İslam Bilimleri Üniversitesi, Karaçi",
            "Kuzey Amerika İslam Cemiyeti",
            "Dünya İslam Birliği",
            "Ümmü'l-Kurâ Üniversitesi, Mekke",
            "Mısır Genel Ölçüm Kurumu",
            "Körfez Bölgesi",
            "Kuveyt",
            "Katar",
            "Singapur İslam Dini Konseyi",
            "Fransa İslam Örgütleri Birliği",
            "Diyanet İşleri Başkanlığı, Türkiye",
            "Rusya Müslümanları Dini İdaresi",
            "Dünya Hilal Gözlem Komitesi",
            "Dubai, BAE",
            "Malezya İslami Kalkınma Dairesi",
            "Tunus",
            "Cezayir",
            "Endonezya Din İşleri Bakanlığı",
            "Fas",
            "Lizbon İslam Cemaati",
            "Ürdün Evkaf, İslami İşler ve Kutsal Mekanlar Bakanlığı"
        ]

            property var languages: [
                en,
                ar,
                tr
            ]
            model: languages[plasmoid.configuration.languageIndex]
            onModelChanged: currentIndex = 2
            currentIndex: plasmoid.configuration.method !== undefined ? plasmoid.configuration.method : 2
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "Format"
                : plasmoid.configuration.languageIndex === 1
                    ? "التنسيق"
                    : plasmoid.configuration.languageIndex === 2
                        ? "Biçim"
                        : ""
        }

        ComboBox {
            id: languageField
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "Language: "
                : plasmoid.configuration.languageIndex === 1
                    ? "اللغة: "
                    : plasmoid.configuration.languageIndex === 2
                        ? "Dil: "
                        : ""
            model: ["English", "العربية", "Türkçe"]
            currentIndex: plasmoid.configuration.languageIndex !== undefined ? plasmoid.configuration.languageIndex : 0
        }

        CheckBox {
            id: hourFormatCheckBox
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "12-Hour Format: "
                : plasmoid.configuration.languageIndex === 1
                    ? "صيغة ال12 ساعة: "
                    : plasmoid.configuration.languageIndex === 2
                        ? "12 saatlik biçim: "
                        : ""
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "Notifications"
                : plasmoid.configuration.languageIndex === 1
                    ? "الإشعارات"
                    : plasmoid.configuration.languageIndex === 2
                        ? "Bildirimler"
                        : ""
        }

        CheckBox {
            id: notificationsCheckBox
            Kirigami.FormData.label: plasmoid.configuration.languageIndex === 0
                ? "Enable Notifications: "
                : plasmoid.configuration.languageIndex === 1
                    ? "تفعيل الإشعارات: "
                    : plasmoid.configuration.languageIndex === 2
                        ? "Bildirimleri etkinleştir: "
                        : ""
        }
    }
}
