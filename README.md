# Shake Dice - Applicazione Mobile Flutter

Applicazione mobile sviluppata in Flutter che implementa un dado virtuale controllato tramite **GestureDetector**: scorrendo velocemente lo schermo (simulando uno "shake") o premendo il pulsante, si lanciano i dadi e si tiene uno storico dei risultati.

## Obiettivi del Progetto

Questo progetto è stato realizzato per dimostrare le seguenti competenze:

1. **GestureDetector**: Utilizzo del widget `GestureDetector` per rilevare gesture di swipe rapido come simulazione dello shake fisico del telefono
2. **Gestione dello stato**: Utilizzo di `StatefulWidget` per aggiornare l'interfaccia in risposta ai lanci e alla selezione del numero di dadi
3. **Animazioni**: Implementazione di `AnimationController` e `AnimatedBuilder` per l'effetto visivo di vibrazione del dado durante il lancio
4. **Logica applicativa**: Generazione di numeri casuali, calcolo del totale e gestione dello storico degli ultimi 10 lanci
5. **UI e componenti Material**: Utilizzo di widget Material 3 per un'interfaccia moderna con tema scuro e sfumature viola

## Requisiti Tecnici

### Ambiente di Sviluppo
- Flutter SDK 3.0+
- Dart SDK 2.17+
- Android Studio o Visual Studio Code
- Emulatore Android/iOS o dispositivo fisico

### Dipendenze
```yaml
dependencies:
  flutter:
    sdk: flutter
```

> Nessuna dipendenza esterna: l'app utilizza solo il Flutter SDK.

## Installazione e Configurazione

### 1. Creazione del Progetto
```bash
flutter create shake_dice
cd shake_dice
```

### 2. Sostituzione dei File
Sostituire il contenuto di `lib/main.dart` e `pubspec.yaml` con i file forniti.

### 3. Esecuzione
```bash
flutter run
```

### Esecuzione su zapp.run
1. Andare su [zapp.run](https://zapp.run) e creare un nuovo progetto Flutter
2. Sostituire `lib/main.dart` e `pubspec.yaml` con i file forniti
3. Premere **Run**

## Architettura dell'Applicazione

### Struttura del Codice
```
lib/main.dart
├── MyApp (MaterialApp)
├── Models
│   └── DiceResult
└── Screens
    └── DiceScreen
        ├── _buildDiceSelector()
        ├── _buildDiceZone()
        ├── _buildHint()
        ├── _buildHistory()
        └── _DiceFace (Widget separato)
```

### Componenti Principali

#### 1. Model Layer - DiceResult
```dart
class DiceResult {
  final List<int> values;
  final DateTime time;

  int get total => values.fold(0, (a, b) => a + b);
}
```
Rappresenta il risultato di un singolo lancio. Memorizza i valori di ogni dado e il timestamp del lancio. Espone il getter `total` per la somma automatica.

#### 2. Presentation Layer - DiceScreen
```dart
class DiceScreen extends StatefulWidget { ... }
```
Schermata principale che gestisce l'intero stato dell'applicazione:
- **Selettore dadi**: chip da 1 a 4 dadi selezionabili
- **Zona dado**: i dadi con animazione shake
- **Storico**: lista degli ultimi 10 lanci con totale

#### 3. Widget - _DiceFace
```dart
class _DiceFace extends StatelessWidget {
  final int value;
  final bool isRolling;
}
```
Widget riutilizzabile per il singolo dado. Usa `AnimatedContainer` per la transizione di colore e l'effetto glow durante il lancio.

## Funzionalità

### Rilevamento della Gesture (Shake Simulato)
- Il `GestureDetector` avvolge l'intera schermata
- `onPanUpdate` accumula la distanza percorsa dal dito
- Quando l'accumulo supera una soglia (300 px), viene lanciato `_rollDice()`
- L'accumulo si azzera a ogni rilascio del dito (`onPanEnd`)

### Lancio dei Dadi
- Genera valori casuali tra 1 e 6 per ogni dado selezionato
- Attiva l'`AnimationController` per l'effetto visivo di vibrazione
- Aggiunge il risultato in cima allo storico (max 10 voci)
- Produce un feedback aptico con `HapticFeedback.mediumImpact()`

### Selettore Numero di Dadi
- `ChoiceChip` per selezionare da 1 a 4 dadi
- Il cambio di selezione azzera i valori e lo storico

### Schermata Storico
- Lista degli ultimi 10 lanci in ordine cronologico inverso
- Il lancio più recente è evidenziato con bordo viola e testo in grassetto
- Mostra le emoji dei dadi (⚀ ⚁ ⚂ ⚃ ⚄ ⚅) e il totale per ogni lancio
- Messaggio informativo se non è stato ancora effettuato alcun lancio

## Logica Applicativa

### Flusso dell'Applicazione

1. **Avvio**: L'utente vede due dadi con valore 1, l'hint e lo storico vuoto
2. **Selezione dadi**: L'utente sceglie quanti dadi usare tramite i chip
3. **Lancio via gesture**: Scorrendo velocemente con il dito si simula lo shake
4. **Lancio via pulsante**: Il FAB "LANCIA" effettua la stessa azione
5. **Animazione**: I dadi vibrano per 600 ms con effetto elastico
6. **Aggiornamento**: Il risultato appare in cima allo storico

### Gestione dello Stato

L'applicazione utilizza `StatefulWidget` per gestire:
- Valori attuali di ogni dado (`_currentValues`)
- Numero di dadi selezionati (`_numDice`)
- Stato di animazione in corso (`_isRolling`)
- Storico dei lanci (`_history`)
- Accumulo gesture shake (`_shakeAccum`)

### Logica dell'Animazione Shake

L'effetto visivo di "vibrazione" del dado è ottenuto combinando:
- `AnimationController` con durata 600 ms
- Curva `Curves.elasticOut` per un rimbalzo naturale
- `Transform.translate` con offset orizzontale basato su `sin()`:

```dart
final offset = sin(_shakeAnimation.value * pi * 6) * 10;
Transform.translate(offset: Offset(offset, 0), child: child);
```

## Note Tecniche

### Compatibilità Flutter

`AnimatedContainer` e `ChoiceChip` sono disponibili in tutte le versioni di Flutter 3.x, garantendo piena compatibilità con zapp.run.

### Simulazione dello Shake via GestureDetector

Il sensore accelerometro non è disponibile nel Flutter SDK base senza package esterni. Per mantenere zero dipendenze, si è scelto di simulare lo shake tramite `GestureDetector.onPanUpdate`, che si comporta in modo analogo dal punto di vista dell'utente (movimento rapido = lancio).

### Persistenza dei Dati

I dati non vengono salvati in modo persistente: si resettano alla chiusura dell'app. Una possibile estensione è l'utilizzo del package `shared_preferences` per conservare lo storico tra le sessioni.

## Gestione dei Casi Limite

L'applicazione gestisce i seguenti casi limite:
- **Lancio in corso**: se l'animazione è attiva, nuovi lanci vengono ignorati (`if (_isRolling) return`)
- **Storico pieno**: lo storico è limitato a 10 voci, le più vecchie vengono eliminate automaticamente
- **Storico vuoto**: messaggio informativo al posto della lista
- **Cambio dadi**: la selezione di un numero diverso di dadi azzera tutto per evitare incoerenze

## Testing e Debug

### Verifica Funzionalità
1. Selezionare 1 dado e premere LANCIA: verificare che appaia un valore da 1 a 6
2. Scorrere velocemente lo schermo: verificare il lancio automatico
3. Selezionare 4 dadi e verificare che il totale corrisponda alla somma
4. Effettuare più di 10 lanci: verificare che lo storico si tronchi
5. Cambiare numero di dadi: verificare che lo storico si azzeri

### Debug
```bash
flutter run --debug
flutter logs
```

## Possibili Estensioni

- Integrazione del package `sensors_plus` per il vero accelerometro hardware
- Modalità "sfida": il gioco chiede un totale da ottenere entro 3 lanci
- Salvataggio persistente dello storico con `shared_preferences`
- Supporto a dadi con facce diverse (D4, D8, D12, D20)
- Suono di lancio dado con il package `audioplayers`
- Statistiche: frequenza di uscita di ogni valore nel tempo

## Riferimenti Tecnici

- **Flutter Documentation**: https://docs.flutter.dev/
- **Dart Language**: https://dart.dev/guides
- **Material Design 3**: https://m3.material.io/
- **GestureDetector Widget**: https://api.flutter.dev/flutter/widgets/GestureDetector-class.html
- **AnimationController**: https://api.flutter.dev/flutter/animation/AnimationController-class.html
- **StatefulWidget**: https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html
- **HapticFeedback**: https://api.flutter.dev/flutter/services/HapticFeedback-class.html

## Conclusioni

Questo progetto dimostra l'applicazione pratica del `GestureDetector` in Flutter per simulare l'input fisico dell'accelerometro senza dipendenze esterne, combinandolo con animazioni fluide, feedback aptico e una UI moderna a tema scuro. Il risultato è un'app intuitiva e divertente, utile per qualsiasi gioco da tavolo.