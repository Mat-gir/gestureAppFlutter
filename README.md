# Tilt Volume Simple - Applicazione Mobile Flutter

Applicazione mobile **minimalista** sviluppata in Flutter che controlla il **volume di sistema** inclinando il telefono a destra o a sinistra, sfruttando i dati dell’accelerometro tramite il package `sensors_plus` e il controllo del volume tramite `volume_controller`.

## Obiettivi del Progetto

Questo progetto è stato realizzato per dimostrare in modo essenziale le seguenti competenze:

1. **Sensore accelerometro (base)**: Lettura in tempo reale dei dati dell’accelerometro tramite lo stream `accelerometerEvents` del package `sensors_plus`.[web:25]
2. **Gestione dello stato**: Utilizzo di `StatefulWidget` e `setState()` per aggiornare l’interfaccia in risposta ai dati del sensore.
3. **Interazione con il sistema**: Controllo del volume hardware del dispositivo tramite il package `volume_controller`.[web:39]
4. **Logica semplificata**: Nessun `Timer.periodic`, nessuna animazione complessa, solo logica diretta dentro al listener dello stream.
5. **UI minimale e testabile**: Interfaccia ridotta a pochi widget (`Text`, `Column`, `Slider`) che rende il codice facile da leggere, mantenere e testare.

## Requisiti Tecnici

### Ambiente di Sviluppo

- Flutter SDK 3.0+
- Dart SDK 2.17+
- Android Studio o Visual Studio Code
- Dispositivo fisico Android o iOS (l’accelerometro non è disponibile sugli emulatori tradizionali)[web:34]

### Dipendenze

```yaml
dependencies:
  flutter:
    sdk: flutter
  sensors_plus: ^4.0.2
  volume_controller: ^2.0.7
```

> **Nota**: questa app richiede un dispositivo fisico per funzionare correttamente, poiché l’accelerometro hardware non è simulato dagli emulatori.

### Permessi Android

Per il controllo del volume su Android, aggiungere in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

## Installazione e Configurazione

### 1. Creazione del Progetto

```bash
flutter create tilt_volume_simple
cd tilt_volume_simple
```

### 2. Sostituzione dei File

- Sostituire il contenuto di `lib/main.dart` con l’implementazione fornita del widget `MyApp` e di `VolumeTilt`.
- (Opzionale) Sostituire `test/widget_test.dart` con un test che verifichi la presenza dei principali elementi della UI.

### 3. Installazione Dipendenze

```bash
flutter pub get
```

### 4. Esecuzione su Dispositivo Fisico

```bash
flutter run
```

## Architettura dell’Applicazione

### Struttura del Codice

```text
lib/main.dart
├── MyApp (MaterialApp)
└── VolumeTilt (StatefulWidget)
    └── _VolumeTiltState
        ├── initState()
        │   ├── VolumeController().getVolume()
        │   └── accelerometerEvents.listen(...)
        ├── dispose()
        │   └── _accelSub.cancel()
        └── build()
            ├── Text('Volume: ...')
            ├── Text('Tilt X: ...')
            └── Slider(...)
```

### Componenti Principali

#### 1. Lettura Accelerometro

```dart
_accelSub = accelerometerEvents.listen((event) {
  setState(() {
    _tiltX = event.x;

    if (_tiltX > 2.0) {
      _volume = (_volume - 0.01).clamp(0.0, 1.0);
    } else if (_tiltX < -2.0) {
      _volume = (_volume + 0.01).clamp(0.0, 1.0);
    }

    VolumeController().setVolume(_volume);
  });
});
```

- Lo stream `accelerometerEvents` fornisce continuamente valori per gli assi X, Y, Z.[web:25]
- In questa app si usa solo l’asse **X** per capire se il telefono è inclinato a sinistra o a destra.

#### 2. Inizializzazione del Volume

```dart
@override
void initState() {
  super.initState();
  VolumeController().showSystemUI = false;
  VolumeController().getVolume().then((v) {
    setState(() => _volume = v);
  });
  // ... sottoscrizione all'accelerometro
}
```

- Viene letto il volume attuale del sistema e memorizzato in `_volume` come valore compreso tra `0.0` e `1.0`.

#### 3. Pulizia delle Risorse

```dart
@override
void dispose() {
  _accelSub?.cancel();
  VolumeController().showSystemUI = true;
  super.dispose();
}
```

- La sottoscrizione allo stream viene cancellata per evitare memory leak.
- L’OSD del volume di sistema viene ripristinato allo stato originale.

## Funzionalità

### Controllo Volume via Inclinazione (Versione Semplificata)

- Inclinare il telefono verso **destra** (`x < -2.0`) aumenta il volume.
- Inclinare il telefono verso **sinistra** (`x > 2.0`) diminuisce il volume.
- Tenere il telefono **quasi verticale** (valori tra `-2.0` e `2.0`) mantiene il volume costante.
- La variazione per evento è fissa (`±0.01`), ma la frequenza degli eventi accelera o rallenta l’effetto percepito.

### Interfaccia Utente

L’interfaccia è volutamente essenziale:

- Testo grande con la scritta `Volume: XX%`.
- Testo secondario `Tilt X: value` per debug e per capire l’effetto dell’inclinazione.
- `Slider` che mostra graficamente il livello di volume (il valore non è modificabile manualmente, serve solo come indicatore).
- Breve testo di istruzioni: “Inclina sinistra → ↓ | destra → ↑”.

## Logica Applicativa

### Flusso dell’Applicazione

1. **Avvio**: L’app legge il volume attuale con `VolumeController().getVolume()` e configura l’ascolto dell’accelerometro.
2. **Evento sensore**: Ogni volta che arriva un nuovo `AccelerometerEvent`, viene aggiornato `_tiltX`.
3. **Decisione direzione**:
   - Se `event.x > 2.0` → il volume viene decrementato.
   - Se `event.x < -2.0` → il volume viene incrementato.
   - Altrimenti non cambia.
4. **Aggiornamento volume**:
   - Il nuovo valore viene calcolato, “clampato” tra `0.0` e `1.0` e impostato nel sistema con `VolumeController().setVolume(...)`.
   - `setState()` aggiorna la UI, riflettendo i nuovi valori.

### Gestione dello Stato

Lo `StatefulWidget` gestisce:

- `_volume`: livello attuale del volume (0.0–1.0).
- `_tiltX`: valore corrente dell’asse X dell’accelerometro.
- `_accelSub`: sottoscrizione allo stream dell’accelerometro, usata per la pulizia in `dispose()`.

## Note Tecniche

### Asse X dell’Accelerometro

Nell’uso tipico con il telefono tenuto in verticale:

- Valore **positivo** (`x > 0`): il dispositivo è inclinato verso sinistra.
- Valore **negativo** (`x < 0`): il dispositivo è inclinato verso destra.
- Magnitudine vicina a `9.8 m/s²` indica allineamento completo con la gravità su quell’asse.[web:22]

### Soglia Anti-Rumore

È stata scelta una soglia costante di `2.0` per ignorare piccole oscillazioni:

```dart
if (_tiltX > 2.0) { ... } else if (_tiltX < -2.0) { ... }
```

Questo riduce cambiamenti involontari dovuti a vibrazioni minime o micro movimenti della mano.

### Compatibilità

- `sensors_plus` supporta Android, iOS, web e desktop, ma l’accelerometro è disponibile solo dove l’hardware lo permette.[web:25]
- `volume_controller` è progettato per Android e iOS; su iOS il controllo del volume può essere limitato dalle politiche di sistema.[web:24]

## Testing e Debug

### Widget Test Esempio

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestureappflutter/main.dart';

void main() {
  testWidgets('VolumeTilt shows initial UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verifica che la UI base sia presente
    expect(find.textContaining('Volume:'), findsOneWidget);
    expect(find.textContaining('Tilt X:'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });
}
```

Questo test verifica che l’app si avvii correttamente e che gli elementi principali della UI siano renderizzati.

### Verifica Manuale

1. Avvia l’app su dispositivo fisico.
2. Controlla che la percentuale mostrata sia coerente con il volume attuale del dispositivo.
3. Inclina gradualmente verso destra e osserva che la percentuale aumenti.
4. Inclina gradualmente verso sinistra e verifica che la percentuale diminuisca.
5. Riporta il telefono in posizione neutra e controlla che il volume rimanga stabile.

### Debug Comandi Utili

```bash
flutter run --debug
flutter logs
```

## Possibili Estensioni

- Aggiunta di un pulsante **pausa** che temporaneamente disattiva il controllo via inclinazione.
- Introduzione di un `Timer.periodic` per rendere la variazione di volume meno dipendente dalla frequenza degli eventi del sensore.
- Animazioni grafiche (ad esempio un’icona di telefono che ruota) per rendere più intuitivo il feedback visivo.
- Salvare su `shared_preferences` la soglia di sensibilità scelta dall’utente.
- Supporto a ulteriori sensori (`gyroscopeEvents`, `userAccelerometerEvents`) per un controllo più preciso.[web:37]

## Riferimenti Tecnici

- **Flutter Documentation**: <https://docs.flutter.dev/>
- **Dart Language**: <https://dart.dev/guides>
- **sensors_plus**: <https://pub.dev/packages/sensors_plus>[web:25]
- **volume_controller**: <https://pub.dev/packages/volume_controller>[web:24]
- **StatefulWidget**: <https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html>
- **StreamSubscription**: <https://api.dart.dev/dart-async/StreamSubscription-class.html>

## Conclusioni

Questo progetto mostra come integrare in maniera **molto semplice** l’accelerometro in un’app Flutter per controllare il volume di sistema, mantenendo il codice breve, leggibile e facilmente estendibile per progetti più avanzati.