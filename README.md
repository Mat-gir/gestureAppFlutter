# Tilt Volume - Applicazione Mobile Flutter

Applicazione mobile sviluppata in Flutter che controlla il **volume di sistema** in tempo reale inclinando il telefono a destra o a sinistra, sfruttando i dati dell'accelerometro hardware tramite il package `sensors_plus`.

## Obiettivi del Progetto

Questo progetto è stato realizzato per dimostrare le seguenti competenze:

1. **Sensore Accelerometro**: Lettura in tempo reale dei dati dell'accelerometro tramite lo stream `accelerometerEvents` del package `sensors_plus`
2. **Gestione dello stato**: Utilizzo di `StatefulWidget` per aggiornare l'interfaccia in risposta ai dati del sensore
3. **Interazione con il sistema**: Controllo del volume hardware del dispositivo tramite il package `volume_controller`
4. **Timer e Stream**: Utilizzo combinato di `StreamSubscription` per il sensore e `Timer.periodic` per l'aggiornamento del volume a intervalli regolari
5. **Animazioni**: Utilizzo di `TweenAnimationBuilder` per l'animazione fluida dell'icona del telefono che replica l'inclinazione reale
6. **UI e componenti Material**: Interfaccia moderna con tema scuro, feedback cromatico in base alla direzione di inclinazione

## Requisiti Tecnici

### Ambiente di Sviluppo
- Flutter SDK 3.0+
- Dart SDK 2.17+
- Android Studio o Visual Studio Code
- Dispositivo fisico Android o iOS (l'accelerometro non è disponibile sull'emulatore)

### Dipendenze
```yaml
dependencies:
  flutter:
    sdk: flutter
  sensors_plus: ^4.0.2
  volume_controller: ^2.0.7
```

> **Nota**: questa app richiede un dispositivo fisico per funzionare correttamente, poiché l'accelerometro hardware non è simulato dagli emulatori.

### Permessi Android

Per il controllo del volume su Android aggiungere in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

## Installazione e Configurazione

### 1. Creazione del Progetto
```bash
flutter create tilt_volume
cd tilt_volume
```

### 2. Sostituzione dei File
Sostituire il contenuto di `lib/main.dart` e `pubspec.yaml` con i file forniti.

### 3. Installazione Dipendenze
```bash
flutter pub get
```

### 4. Esecuzione su Dispositivo Fisico
```bash
flutter run
```

## Architettura dell'Applicazione

### Struttura del Codice
```
lib/main.dart
├── MyApp (MaterialApp)
└── Screens
    └── VolumeScreen
        ├── _onAccelerometro()
        ├── _aggiornaVolume()
        ├── _buildIndicatoreTilt()
        ├── _buildVolumeDisplay()
        ├── _buildBarraVolume()
        └── _buildIstruzione()
```

### Componenti Principali

#### 1. Stream Accelerometro
```dart
_accelSub = accelerometerEvents.listen(_onAccelerometro);
```
Sottoscrizione allo stream dell'accelerometro. Ad ogni evento viene aggiornato il valore di `_tiltX` (asse X) e la direzione rilevata.

#### 2. Timer di Aggiornamento Volume
```dart
_volumeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
  if (_attivo) _aggiornaVolume();
});
```
Ogni 50 ms viene calcolata la variazione di volume in base all'intensità dell'inclinazione e applicata al sistema tramite `VolumeController`.

#### 3. Calcolo dell'Intensità
```dart
final intensita = ((_tiltX.abs() - _soglia) / 7.0).clamp(0.0, 1.0);
final delta = intensita * _velocitaMax;
```
Il volume non cambia a velocità fissa: più si inclina il telefono, più velocemente il volume sale o scende. La soglia minima evita variazioni accidentali da piccole oscillazioni.

## Funzionalità

### Controllo Volume via Inclinazione
- Inclinare a **destra**: il volume sale progressivamente
- Inclinare a **sinistra**: il volume scende progressivamente
- Tenere il telefono **fermo**: il volume rimane invariato
- La velocità di variazione è proporzionale all'angolo di inclinazione

### Indicatore Grafico del Telefono
- Un'icona del telefono ruota in tempo reale replicando l'inclinazione fisica
- Il bordo cambia colore: blu (neutro), azzurro (volume su), rosso (volume giù)
- L'animazione usa `TweenAnimationBuilder` con durata 100 ms per fluidità

### Display Volume
- Percentuale grande al centro aggiornata in tempo reale
- Icona del volume che cambia (muto / basso / alto)
- Barra di progresso orizzontale con colore dinamico

### Pulsante Pausa
- Il pulsante in alto a destra sospende il controllo via inclinazione
- L'interfaccia si oscura per indicare lo stato di pausa
- Il volume rimane invariato finché non si riprende

## Logica Applicativa

### Flusso dell'Applicazione

1. **Avvio**: L'app legge il volume attuale del sistema e avvia il listener dell'accelerometro
2. **Inclinazione**: L'accelerometro emette eventi continui con i valori degli assi X, Y, Z
3. **Rilevamento direzione**: Se `e.x > soglia` → sinistra (abbassa); se `e.x < -soglia` → destra (alza)
4. **Aggiornamento**: Ogni 50 ms il timer chiama `_aggiornaVolume()` che calcola il delta e lo applica
5. **Feedback**: La UI si aggiorna con colori, percentuale e animazione del telefono
6. **Pausa**: Il pulsante sospende il ciclo di aggiornamento senza chiudere lo stream

### Gestione dello Stato

L'applicazione utilizza `StatefulWidget` per gestire:
- Valore corrente del volume (`_volume`)
- Valore grezzo dell'asse X dell'accelerometro (`_tiltX`)
- Direzione rilevata (`_direzione`: 'neutro', 'sinistra', 'destra')
- Stato attivo/pausa (`_attivo`)

### Pulizia delle Risorse

Nel metodo `dispose()` vengono cancellati sia lo stream che il timer, e il sistema OSD del volume viene ripristinato:

```dart
@override
void dispose() {
  _accelSub?.cancel();
  _volumeTimer?.cancel();
  VolumeController().showSystemUI = true;
  super.dispose();
}
```

## Note Tecniche

### Asse X dell'Accelerometro

Il valore `e.x` restituito da `sensors_plus` rappresenta l'accelerazione sull'asse orizzontale del telefono tenuto in verticale:
- Valore positivo: il dispositivo è inclinato verso sinistra
- Valore negativo: il dispositivo è inclinato verso destra
- La gravità terrestre (9.8 m/s²) è il valore massimo teorico sull'asse

### Soglia Anti-Rumore

```dart
static const double _soglia = 2.0; // m/s²
```
La soglia di 2.0 m/s² filtra le piccole oscillazioni inevitabili durante l'uso normale del telefono, evitando variazioni di volume involontarie.

### Compatibilità

`volume_controller` supporta Android 5.0+ e iOS 9.0+. Su iOS il controllo del volume multimediale potrebbe essere limitato dalle politiche di sistema.

## Gestione degli Errori

L'applicazione gestisce i seguenti casi limite:
- **Volume a 0 o 100**: il valore viene bloccato con `clamp(0.0, 1.0)` senza causare errori
- **Stream non disponibile**: se l'accelerometro non è presente, `accelerometerEvents` non emette eventi e l'app rimane funzionante (ma inattiva)
- **Dispose corretto**: cancellazione di stream e timer per evitare memory leak

## Testing e Debug

### Verifica Funzionalità
1. Avviare l'app su un dispositivo fisico e verificare che la percentuale mostrata corrisponda al volume attuale
2. Inclinare lentamente a destra: il volume deve salire gradualmente
3. Inclinare rapidamente a sinistra: il volume deve scendere più velocemente
4. Premere pausa e inclinare: verificare che il volume non cambi
5. Riprendere e verificare che il controllo torni attivo

### Debug
```bash
flutter run --debug
flutter logs
```

## Possibili Estensioni

- Aggiunta della modalità "blocco notturno": sopra una certa ora il volume non può superare il 50%
- Utilizzo del giroscopio (`gyroscopeEvents`) per un rilevamento dell'angolo più preciso
- Aggiunta di un controllo separato per il volume delle notifiche e delle chiamate
- Salvataggio della soglia di sensibilità con `shared_preferences`
- Widget sulla schermata principale (Home Screen Widget) per attivare/disattivare rapidamente

## Riferimenti Tecnici

- **Flutter Documentation**: https://docs.flutter.dev/
- **Dart Language**: https://dart.dev/guides
- **Material Design 3**: https://m3.material.io/
- **sensors_plus**: https://pub.dev/packages/sensors_plus
- **volume_controller**: https://pub.dev/packages/volume_controller
- **StreamSubscription**: https://api.dart.dev/dart-async/StreamSubscription-class.html
- **StatefulWidget**: https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html

## Conclusioni

Questo progetto dimostra come integrare sensori hardware reali in un'applicazione Flutter, combinando lo stream dell'accelerometro con il controllo del volume di sistema. L'uso del `Timer.periodic` separato dallo stream permette di disaccoppiare la lettura del sensore dall'applicazione dell'effetto, rendendo il codice più leggibile e controllabile.