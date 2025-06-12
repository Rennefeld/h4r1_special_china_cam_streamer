# China Cam Stream

Dieses Programm zeigt einen MJPEG Stream über UDP an und nutzt eine moderne Kivy-Oberfläche, die sich besonders für Android im Hochformat eignet. Neben dem reinen Anzeigen können verschiedene Bildoperationen angewendet und Aufnahmen erstellt werden.

## Funktionen

- **MJPEG Anzeige** aus einem UDP Stream
- **Konfigurationsmenü** für Kamera-IP, Kamera-Port, Helligkeit, Kontrast und Sättigung
- **Bildoperationen**: Drehung in 90°-Schritten, horizontales/vertikales Spiegeln, Schwarz/Weiß
- **Snapshot und Videoaufnahme** mit individuellem Speicherort
- **Individuelle Dateinamen** beim Speichern von Videos und Bildern

## Bedienung

Nach dem Start erscheint die Hauptoberfläche mit dem Videofenster und den Steuerbuttons. 
Über das Menü `Einstellungen` lassen sich die Kameradaten sowie Bildparameter anpassen. 
Alle Änderungen werden sofort angewendet und in `settings.json` gespeichert.

### Steuerbuttons

 - **Aufnahme**: Startet bzw. beendet die Videoaufnahme und speichert als AVI-Datei.
- **Snapshot**: Speichert das aktuelle Bild als JPEG.
- **Debug**: Schaltet eine Protokollierung ein oder aus.
- **Restart**: Startet den Stream manuell neu.
- **Rotate**: Rotiert das Bild um 90°.
- **Flip H/V**: Spiegelt das Bild horizontal bzw. vertikal.
- **B/W**: Schaltet zwischen Farbe und Graustufen um.
- **Auflösung**: Vordefinierte Werte bis 1920x1080 wählbar.
