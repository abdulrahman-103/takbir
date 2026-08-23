import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.notification 1.0

PlasmoidItem {
    id: root

    property var methodIds: [
    1,  // University of Islamic Sciences, Karachi
    2,  // Islamic Society of North America
    3,  // Muslim World League
    4,  // Umm Al-Qura University, Makkah
    5,  // Egyptian General Authority of Survey
    8,  // Gulf Region
    9,  // Kuwait
    10, // Qatar
    11, // Majlis Ugama Islam Singapura, Singapore
    12, // Union Organization Islamic de France
    13, // Diyanet İşleri Başkanlığı, Turkey
    14, // Spiritual Administration of Muslims of Russia
    15, // Moonsighting Committee Worldwide
    16, // Dubai
    17, // Jabatan Kemajuan Islam Malaysia
    18, // Tunisia
    19, // Algeria
    20, // Kementerian Agama Republik Indonesia
    21, // Morocco
    22, // Comunidade Islamica de Lisboa
    23  // Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan
]

    readonly property bool isVertical: true
    property bool isSmall: width < (Kirigami.Units.gridUnit * 10) || height < (Kirigami.Units.gridUnit * 10)
    property int languageIndex: Plasmoid.configuration.languageIndex !== undefined ? Plasmoid.configuration.languageIndex : 0

    width: Kirigami.Units.gridUnit * 15
    height: Kirigami.Units.gridUnit * 23
    preferredRepresentation: isSmall ? compactRepresentation : fullRepresentation
    // for task bar representation
    Layout.minimumWidth: Kirigami.Units.gridUnit * 7
    Layout.preferredWidth: Kirigami.Units.gridUnit * 7

    // times
    property var times: ({})
    property string lastActivePrayer: ""
    property string activePrayer: ""
    property var displayTimes: ({})

    compactRepresentation: CompactRepresentation {
        activePrayer: root.activePrayer
        displayTimes: root.displayTimes
        plasmoidItem: root
        languageIndex: root.languageIndex
    }





    function languageUpdate() {
        languageIndex = Plasmoid.configuration.languageIndex; // change language
    }

    function to12HourTime(timeString, isActive) {
        if (isActive) { // if checkbox is active, convert to 12-hour format
            let parts = timeString.split(':');
            let hours = parseInt(parts[0], 10);
            let minutes = parseInt(parts[1], 10);
            let period = hours >= 12
                ? (languageIndex === 0 ? "PM" : languageIndex === 1 ? "مساءً" : languageIndex === 2 ? "ÖS" : "")
                : (languageIndex === 0 ? "AM" : languageIndex === 1 ? "صباحًا" : languageIndex === 2 ? "ÖÖ" : "");
            hours = hours % 12 || 12;
            if (minutes > 9) {
                return `${hours}:${minutes} ${period}`;
            } else {
                return `${hours}:0${minutes} ${period}`;
            }
        } else { // no change
            return timeString;
        }
    }

    function parseTime(timeString) {
        let parts = timeString.split(':');
        let dateObj = new Date();
        dateObj.setHours(parseInt(parts[0], 10));
        dateObj.setMinutes(parseInt(parts[1], 10));
        dateObj.setSeconds(0);
        return dateObj;
    }

    function getPrayerName(languageIndex, prayer) {
        if (languageIndex === 0) {
            return prayer;
        } else if (languageIndex === 1) {
            let arabicPrayers = {
                "Fajr": "الفجر",
                "Sunrise": "الشروق",
                "Dhuhr": "الظهر",
                "Asr": "العصر",
                "Maghrib": "المغرب",
                "Isha": "العشاء"
            }
            return arabicPrayers[prayer];
        } else if (languageIndex === 2) {
            let turkishPrayers = {
                "Fajr": "Sabah",
                "Sunrise": "Güneş",
                "Dhuhr": "Öğle",
                "Asr": "İkindi",
                "Maghrib": "Akşam",
                "Isha": "Yatsı"
            }
            return turkishPrayers[prayer];
        }
    }

    function highlightActivePrayer(timings) {
        // assuming all timings are for current day
        var currentPrayer = "";
        if (Date.now() > parseTime(timings.Fajr) && Date.now() < parseTime(timings.Sunrise)) { currentPrayer = "Fajr"; }
        else if (Date.now() > parseTime(timings.Sunrise) && Date.now() < parseTime(timings.Dhuhr)) { currentPrayer = "Sunrise"; }
        else if (Date.now() > parseTime(timings.Dhuhr) && Date.now() < parseTime(timings.Asr)) { currentPrayer = "Dhuhr"; }
        else if (Date.now() > parseTime(timings.Asr) && Date.now() < parseTime(timings.Maghrib)) { currentPrayer = "Asr"; }
        else if (Date.now() > parseTime(timings.Maghrib) && Date.now() < parseTime(timings.Isha)) { currentPrayer = "Maghrib"; }
        else { currentPrayer = "Isha"; }

        lastActivePrayer = activePrayer;
        activePrayer = currentPrayer;

        if (lastActivePrayer !== currentPrayer && Plasmoid.configuration.notifications) {
            var notification = notificationComponent.createObject(parent);
            notification.title = "It's " + activePrayer + " time";
            notification.sendEvent();
        }
    }

    function fetchTimes(callback) {
        let locationType = Plasmoid.configuration.locationType;
        let URL = "";
        
        // Build URL based on location type
        if (locationType === "city") {
            // Use city and country
            URL = "https://api.aladhan.com/v1/timingsByCity?city=" + encodeURIComponent(Plasmoid.configuration.city) + "&country=" + encodeURIComponent(Plasmoid.configuration.country) + "&method=" + methodIds[Plasmoid.configuration.method] + "&school=0";
            fetchTimesFromAPI(URL, callback);
        } else if (locationType === "automatic") {
            // Fetch IP location first, then get prayer times
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "http://ip-api.com/json", true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        let response = JSON.parse(xhr.responseText);
                        // Store the city and country from IP lookup
                        Plasmoid.configuration.ipCity = response.city + ", " + response.country;
                        Plasmoid.configuration.latitude = response.lat.toString();
                        Plasmoid.configuration.longitude = response.lon.toString();
                        URL = "https://api.aladhan.com/v1/timings?latitude=" + response.lat + "&longitude=" + response.lon + "&method=" + methodIds[Plasmoid.configuration.method] + "&school=0";
                        fetchTimesFromAPI(URL, callback);
                    } else {
                        console.error("Failed to fetch IP location");
                        handleFetchError();
                    }
                }
            };
            xhr.send();
        } else if (locationType === "coordinates") {
            // Use manual latitude and longitude
            URL = "https://api.aladhan.com/v1/timings?latitude=" + Plasmoid.configuration.latitude + "&longitude=" + Plasmoid.configuration.longitude + "&method=" + methodIds[Plasmoid.configuration.method] + "&school=0";
            fetchTimesFromAPI(URL, callback);
        }
    }

    function fetchTimesFromAPI(URL, callback) {
        request(URL, (o) => {
                    if (o.status === 200) {
                        let data = JSON.parse(o.responseText).data;
                        times = data.timings;
                        times.date = data.date.gregorian.date;
                        if (callback) callback(data.timings);
                    } else {
                        handleFetchError();
                    }
                });
    }

    function handleFetchError() {
        if (Plasmoid.configuration.notifications) {
            var notification = notificationComponent.createObject(parent);
            notification.title = "Could not update times. Are you connected to the internet?";
            notification.sendEvent();
        }

        if (getFormattedDate(new Date()) != times.date) {
            times = {
                "Fajr": "00:00",
                "Sunrise": "00:00",
                "Dhuhr": "00:00",
                "Asr": "00:00",
                "Maghrib": "00:00",
                "Isha": "00:00"
            }
            updateDisplay();
        }
    }

    function updateDisplay(timings) {
        var prayerTimes = timings || times;
        highlightActivePrayer(prayerTimes);

        let isActive = Plasmoid.configuration.hourFormat;
        displayTimes = {
            "fajr": to12HourTime(prayerTimes.Fajr, isActive),
            "sunrise": to12HourTime(prayerTimes.Sunrise, isActive),
            "dhuhr": to12HourTime(prayerTimes.Dhuhr, isActive),
            "asr": to12HourTime(prayerTimes.Asr, isActive),
            "maghrib": to12HourTime(prayerTimes.Maghrib, isActive),
            "isha": to12HourTime(prayerTimes.Isha, isActive)
        }
    }

    function request(url, callback) {
        let xhr = new XMLHttpRequest();
        xhr.onreadystatechange = (function(myxhr) {
        return () => {
        if (myxhr.readyState === 4) callback(myxhr);
        };
        })(xhr);
        xhr.open("GET", url);
        xhr.send();
    }


    function getFormattedDate(givenDate) {
        const today = givenDate;
        const day = String(today.getDate()).padStart(2, "0");
        const month = String(today.getMonth() + 1).padStart(2, "0");
        const year = today.getFullYear();
        return `${day}-${month}-${year}`;
    }








    // Notification element
    Component {
        id: notificationComponent
        Notification {
            componentName: "plasma_workspace"
            eventId: "notification"
            autoDelete: true
        }
    }
    // onload
    Component.onCompleted: {
        fetchTimes(updateDisplay);
        Plasmoid.configuration.valueChanged.connect((key, value) => {
            // Only refetch when user-controlled settings change, not internal values
            if (key === "locationType" || key === "city" || key === "country" ||
                key === "method" || key === "hourFormat") {
                fetchTimes(updateDisplay);
            } else if (key === "languageIndex") {
                // Just update display for language change, no need to refetch
                updateDisplay();
            }
        });
    }
    // loop
    Item {
        Timer {
            interval: 30000 // repeat every 30 seconds
            running: true
            repeat: true
            onTriggered: () => {
                if (times && Object.keys(times).length > 0 && getFormattedDate(new Date()) === times.date) {
                    updateDisplay(times);
                } else {
                    fetchTimes(updateDisplay);
                }
            }
        }
    }

    fullRepresentation: Item {
        id: prayerClock

        Column {
            width: parent.width * 5 / 6
            anchors.centerIn: parent

            Label {
                id: titleLabel
                text: languageIndex === 0
                    ? "Prayer Times"
                    : languageIndex === 1
                        ? "مواقيت الصلاة"
                        : languageIndex === 2
                            ? "Namaz Vakitleri"
                            : ""
                font.pixelSize: 24
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: subtitleLabel

                text: {
                    if (Plasmoid.configuration.locationType === "automatic") {
                        return Plasmoid.configuration.ipCity || "Automatic Location";
                    } else if (Plasmoid.configuration.locationType === "coordinates") {
                        return Plasmoid.configuration.latitude + ", " + Plasmoid.configuration.longitude;
                    } else {
                        return Plasmoid.configuration.city + ", " + Plasmoid.configuration.country;
                    }
                }
                font.pixelSize: 18
                anchors.horizontalCenter: parent.horizontalCenter
            }

            PlasmaComponents.MenuSeparator {
                width: parent.width
                topPadding: Kirigami.Units.largeSpacing
                bottomPadding: Kirigami.Units.largeSpacing
            }

            // Prayer times, refresh button
            ListModel {
                id: prayerElementsModal
                ListElement { handle: "Fajr" }
                ListElement { handle: "Sunrise" }
                ListElement { handle: "Dhuhr" }
                ListElement { handle: "Asr" }
                ListElement { handle: "Maghrib" }
                ListElement { handle: "Isha" }
            }

            Repeater {
                model: prayerElementsModal

                Column {
                    width: parent.width

                    Rectangle {
                        width: parent.width
                        color: activePrayer === handle ? Kirigami.Theme.highlightColor : "transparent"
                        height: Kirigami.Units.gridUnit * 1.8
                        radius: Kirigami.Units.gridUnit * .6

                        RowLayout {
                            anchors.fill: parent // throwing error
                            anchors.leftMargin: Kirigami.Units.largeSpacing
                            anchors.rightMargin: Kirigami.Units.largeSpacing
                            layoutDirection: languageIndex === 0 || languageIndex === 2 ? Qt.LeftToRight : Qt.RightToLeft

                            Label {
                                text: getPrayerName(languageIndex, handle)
                                Layout.alignment: Qt.AlignLeft
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                                color: activePrayer === handle ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                            }

                            Label {
                                text: displayTimes[handle.toLowerCase()] ? displayTimes[handle.toLowerCase()] : "00:00"
                                Layout.alignment: Qt.AlignRight
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                                color: activePrayer === handle ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                            }
                        }

                    }

                    PlasmaComponents.MenuSeparator {
                        width: parent.width
                        visible: index < prayerElementsModal.count - 1
                        topPadding: Kirigami.Units.smallSpacing * 1.2
                        bottomPadding: Kirigami.Units.smallSpacing * 1.2
                    }
                }
            }

            PlasmaComponents.MenuSeparator {
                width: parent.width
                topPadding: Kirigami.Units.mediumSpacing
                bottomPadding: Kirigami.Units.mediumSpacing
                contentItem: Rectangle {
                    color: "transparent"
                }
            }

            Button {
                text: languageIndex === 0
                    ? "Refresh Times"
                    : languageIndex === 1
                        ? "حدث المواقيت"
                        : languageIndex === 2
                            ? "Vakitleri Yenile"
                            : ""
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    if (times && Object.keys(times).length > 0 && getFormattedDate(new Date()) === times.date) {
                        updateDisplay(times);
                        if (Plasmoid.configuration.notifications) {
                            var notification = notificationComponent.createObject(parent);
                            notification.title = "Refreshing prayer times";
                            notification.sendEvent();
                        }
                    } else {
                        fetchTimes(updateDisplay);
                    }
                }
            }
        }
    }
}
