import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project/banco_dados/palavras.dart';
import 'package:flutter_project/banco_dados/menorCaminho.dart';
import 'package:flutter_project/banco_dados/caminho.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_blue/flutter_blue.dart';
//import 'package:flutter_project/widgets.dart';
import 'package:flutter_blue_beacon/flutter_blue_beacon.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {

  PalavrasChave banco = PalavrasChave();
  MenorCaminho banco2 = MenorCaminho();
  Caminho banco3 = Caminho();

  /* Inicio - Variáveis de Voz */
    FlutterTts flutterTts;
    double volume = 1.0;
    double pitch  = 1.0;
    double rate   = 0.9; //velocidade

    stt.SpeechToText _speech;
    String _text      = 'Clique na tela e fale um destino';
    String _destino   = '';
    String _destinoId = '';
    String _fala = '';
    double _confidence = 1.0;
  /* Fim - Variáveis de Voz */

  /* Inicio - Variáveis de localização */
    String _ultimoLocal    = '';
    String _ultimoLocalId  = '000000000000';
    String _fraseLocal     = '';
    String _proximoLocalId = '000000000000';
    int _ultimoDistance = 0;
    int _ultimoRssi     = 0;
    int _dirErrada      = 0;
  /* Fim - Variáveis de localização */

  /* Inicio - Variáveis de Beacons */
    FlutterBlueBeacon flutterBlueBeacon = FlutterBlueBeacon.instance;
    FlutterBlue _flutterBlue = FlutterBlue.instance;

    /// Scanning
    StreamSubscription _scanSubscription;
    Map<int, Beacon> beacons = new Map();
    bool isScanning = false;

    /// State
    StreamSubscription _stateSubscription;
    BluetoothState state = BluetoothState.unknown;
  /* Fim - Variáveis de Beacons */

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    flutterTts = FlutterTts();

    // Immediately get the state of FlutterBlue
    _flutterBlue.state.then((s) {
      setState(() {
        state = s;
      });
    });
    // Subscribe to state changes
    _stateSubscription = _flutterBlue.onStateChanged().listen((s) {
      setState(() {
        state = s;
      });
    });
  }
  
  /* Inicio - Funções de Voz */
    Future _speak(frase) async {
      await flutterTts.setVoice('pt-br-x-afs-network');
      //await flutterTts.setVoice('pt-br-x-afs#female_1-local');
      //await flutterTts.setVoice('pt-br-x-afs#male_3-local');
      //await flutterTts.setVoice('pt-br-x-afs-local');
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
      await flutterTts.speak(frase);
    }
  /* Fim - Funções de Voz */

  /* Inicio - Funções de Beacons */
    @override
    void dispose() {
      _stateSubscription?.cancel();
      _stateSubscription = null;
      _scanSubscription?.cancel();
      _scanSubscription = null;
      super.dispose();
    }

    _startScan() {
      print("Scanning now");
      _scanSubscription = flutterBlueBeacon.scan(timeout: const Duration(seconds: 3600)).listen((beacon) {
        if (beacon is EddystoneUID) {
          print("beaconId: ${beacon.beaconId}, tx: ${beacon.tx}, rssi: ${beacon.rssi}, distance: ${beacon.distance}");

          //verifica se beacon lido existe no banco
          banco.getIdBeacon(beacon.beaconId).then((list){
            //se existir
            if(list != null){
              //busca últimos valores de beacon lido 
              banco3.getWalk(beacon.beaconId).then((list2){
                int dis = beacon.distance.round()+list2.dist;
                int rss = (beacon.rssi*-1)+list2.rssi;
                int qtd = list2.qtd+1;

                //atualiza valores de beacon lido 
                banco3.atualizaWalk(beacon.beaconId, dis, rss, qtd).then((list3){
                  //Verifica se existe algum beacon que já foi atualizado 10 vezes ou mais. Não pode ser o valor do último beacon informado para o usuário
                  banco3.getWalkLimit(_ultimoLocalId).then((list4){
                    //caso tenha sido
                    if(list4 != null){
                      //busca melhor distancia de todas registradas. Não pode ser o valor do último beacon informado para o usuário
                      banco3.getBestWalk(_ultimoLocalId).then((list5){
                        _ultimoDistance = list5.dist;

                        banco.getIdBeacon(list5.beacon).then((list6){
                          String ultLocal = list6.palavra;

                          banco3.getAllWalks().then((list99){
                            print("----------list99----------");
                            print(list99);
                          });

                          //verifica se melhor distancia estiver menor que 85
                          if(_ultimoDistance <= 40){ //verifica se melhor distancia estiver menor que 40
                            print("----------_ultimoDistance <= 40----------");
                            print(_ultimoDistance);
                            //verifica se é o destino desejado
                            if(list6.beacon == _destinoId){
                              _fala = 'Voce chegou ao seu destino!';
                              _speak(_fala);
                              _stopScan();
                            } else {
                              _ultimoLocalId = list6.beacon;
                              _ultimoLocal   = list6.palavra;
                            
                              print("----------_ultimoLocalId----------");
                              print(_ultimoLocalId);
                              print("----------_ultimoLocal----------");
                              print(_ultimoLocal);

                              //busca proximo caminho
                              banco2.getCaminho(_ultimoLocalId, _destinoId).then((list7){
                                _dirErrada      = 0;
                                _proximoLocalId = list7.proximo;
                                _fraseLocal     = list7.frase;
                                
                                banco3.limpaWalk();
                                _fala = 'Voce está na $_ultimoLocal. Para chegar na $_destino, é preciso $_fraseLocal .';
                                _speak(_fala);
                              });
                            }
                          } else if(_ultimoDistance > 40 && _ultimoDistance <= 85) {
                            print("----------_ultimoDistance > 40 && _ultimoDistance <= 85----------");
                            print(_ultimoDistance);
                            //verifica se esta indo na direção errada.
                            if(list6.beacon != _proximoLocalId && _dirErrada == 0){ 
                              print("----------list6.beacon != _proximoLocalId && _dirErrada == 0----------");
                              _dirErrada = 1;
                              banco3.limpaWalk();
                              _speak('Você está indo na direção errada. É preciso retornar onde estava, $_fraseLocal para chegar na $_destino.');
                            }
                          } else {
                            banco3.limpaWalk();
                          }
                        });
                      });
                    }
                  });
                });
              });
            }
          });
        }
        setState(() {
          beacons[beacon.hash] = beacon;
        });
      }, onDone: _stopScan);

      setState(() {
        isScanning = true;
      });
    }

    _stopScan() {
      print("Scan stopped");
      _scanSubscription?.cancel();
      _scanSubscription = null;
      setState(() {
        isScanning = false;
      });
    }

    _buildAlertTile() {
      return new Container(
        color: Colors.redAccent,
        child: new ListTile(
          title: new Text(
            'Bluetooth adapter is ${state.toString().substring(15)}',
            style: Theme.of(context).primaryTextTheme.subtitle1,
          ),
          trailing: new Icon(
            Icons.error,
            color: Theme.of(context).primaryTextTheme.subtitle1.color,
          ),
        ),
      );
    }
  /* Fim - Funções de Beacons */

  @override
  Widget build(BuildContext context) {
    var tiles = new List<Widget>();
    if (state != BluetoothState.on) {
      tiles.add(_buildAlertTile());
    }

    return GestureDetector(
      onTap: _listen,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
        ),
        body: SingleChildScrollView(
          reverse: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
            child: Text(_text,
              style: const TextStyle(
                fontSize: 32.0,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _listen() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (available) {
      _speech.listen(
        cancelOnError: false,
        onResult: (val) => setState(() {

          //verifica se reconhecimento é confiável
          if (val.hasConfidenceRating && val.confidence > 0) {

            //verifica se palavra reconhecida é tutorial.
              //Caso seja, o app da uma explicação de seu funcionamento
              //Caso não seja, procura palavra no banco de dados.
                //Caso encontre inicia o percurso
                //Caso não encontre, informa que não entendeu a palavra
            if(val.recognizedWords == 'tutorial'){
              _fala = 'Olá, você está usando o BlindGui. Para utilizar, basta clicar em qualquer lugar da tela e falar onde deseja ir. Caso deseje repetir a mensagem, clique na tela e fale, repetir.';

              _confidence = val.confidence;
              _speak(_fala);
            } else if(val.recognizedWords == 'repetir') {
              _speak(_fala);
            } else {
              banco.getPalavra(val.recognizedWords).then((list){
                if(list == null){
                  _fala       = 'Não entendi o que você disse. Poderia repetir ?';
                  _confidence = val.confidence;
                  _speak(_fala);
                } else {
                  _destino    = list.palavra;
                  _destinoId  = list.beacon;
                  _fala       = 'Destino confirmado, você está indo para a $_destino';
                  _confidence = val.confidence;
                  _speak(_fala);

                  //inicia a busca por beacons
                  _startScan();
                }
              });
            }
          }
        }),
      );
    }
  }
}
