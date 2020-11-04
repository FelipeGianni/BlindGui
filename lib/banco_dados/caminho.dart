import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

//tabela -> walkTable
final String walkTable    = 'walkTable';
final String beaconColumn = 'beaconColumn';
final String distColumn   = 'distColumn';
final String rssiColumn   = 'rssiColumn';
final String qtdColumn    = 'qtdColumn';

//bestwalk
final String beaconBest = 'beaconBest';
final String distBest   = 'distBest';
final String rssiBest   = 'rssiBest';

class Caminho {

  static final Caminho _instance = Caminho.internal();

  factory Caminho() => _instance;

  Caminho.internal();

  Database _db;

  
  /*** Inicio - querys de controle ***/

    //verificar se banco de dados já foi criado. Caso não tenha sido, cria.
    Future<Database> get db async {
      if(_db != null){
        return _db;
      } else {
        _db = await initDb();

        //limpa tabela walkTable caso tenha alguma coisa
        await dropaWalk();

        //000000000001 => biblioteca
        //000000000002 => cantina
        //000000000003 => sala 301 prédio 5
        //000000000004 => sala dos professores
        //000000000005 => coordenação

        //carga no banco com caminhos
        await preparaWalk('000000000001', 0, 0, 0);
        await preparaWalk('000000000002', 0, 0, 0);
        await preparaWalk('000000000003', 0, 0, 0);
        await preparaWalk('000000000004', 0, 0, 0);
        await preparaWalk('000000000005', 0, 0, 0);

        return _db;
      }
    }

    //função para criar banco de dados e tabelas
    Future<Database> initDb() async {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'walk.db');

      return await openDatabase(path, version: 1, onCreate: (Database db, int newerVersion) async{
        await db.execute(
          'CREATE TABLE $walkTable($beaconColumn TEXT, $distColumn INTEGER, $rssiColumn INTEGER, $qtdColumn INTEGER)'
        );
      });
    }

    //prepara para inserir em walkTable
    Future<void> preparaWalk(String word1, int word2, int word3, int word4) async {
      Walk p = Walk();
      p.beacon = word1;
      p.dist   = word2;
      p.rssi   = word3;
      p.qtd    = word4;

      saveWalk(p);
    }

    //função para salvar beacon encontrados em walkTable
    Future<Walk> saveWalk(Walk path) async {
      Database dbPath = await db;

      await dbPath.insert(walkTable, path.topMap());
      return path;
    }

    //função para resetar walkTable
    Future<int> limpaWalk() async {
      Database dbPath = await db;

      return await dbPath.rawUpdate(
      'UPDATE $walkTable SET $distColumn = 0, $rssiColumn = 0, $qtdColumn = 0');
    }

    //função para atualizar dados de walkTable
    Future<int> atualizaWalk(String word1, int word2, int word3, int word4) async {
      Database dbPath = await db;

      return await dbPath.rawUpdate(
      'UPDATE $walkTable SET $distColumn = ?, $rssiColumn = ?, $qtdColumn = ? WHERE $beaconColumn = ?',
      [word2,word3,word4,word1]);
    }

    //dropa walkTable
    Future<int> dropaWalk() async {
      Database dbPath = await db;

      return await dbPath.rawDelete("DELETE FROM $walkTable");
    }

    //função para fechar o banco de dados
    Future close() async {
      Database dbPath = await db;

      dbPath.close();
    }

  /*** Fim - querys de controle ***/

  /*** Inicio - querys de busca ***/
  
    //função para obter todas as palavras gravadas
    Future<List> getAllWalks() async {
      Database dbPath = await db;

      List listMap = await dbPath.rawQuery("SELECT * FROM $walkTable");
      List<Walk> listWalk = List();

      for(Map m in listMap){
        listWalk.add(Walk.fromMap(m));
      }

      return listWalk;
    }
  
    //função para obter todas os caminhos gravadas
    Future<BestWalk> getBestWalk(String word1) async {
      Database dbPath = await db;

      List<Map> maps = await dbPath.rawQuery(
        "SELECT beaconColumn AS $beaconBest, distColumn/qtdColumn AS $distBest "
        "FROM $walkTable WHERE beaconColumn <> '$word1' AND qtdColumn > 5 ORDER BY 2");
      
      if(maps.length > 0){
        return BestWalk.fromMap(maps.first);
      } else {
        return null;
      }
    }
  
    //função para obter todas os caminhos gravadas
    Future<Walk> getWalkLimit(String word1) async {
      Database dbPath = await db;

      List<Map> maps = await dbPath.query(walkTable,
        columns: [beaconColumn],
        where: "beaconColumn <> ? AND qtdColumn = ?",
        whereArgs: [word1, 10]);
      
      if(maps.length > 0){
        return Walk.fromMap(maps.first);
      } else {
        return null;
      }
    }
  
    //função para obter um caminhos
    Future<Walk> getWalk(String word1) async {
      Database dbPath = await db;

      List<Map> maps = await dbPath.query(walkTable,
        columns: [beaconColumn, distColumn, rssiColumn, qtdColumn],
        where: "beaconColumn = ?",
        whereArgs: [word1]);
      
      if(maps.length > 0){
        return Walk.fromMap(maps.first);
      } else {
        return null;
      }
    }

  /*** Fim - querys de busca ***/
}

class Walk {

  String beacon;
  int dist;
  int rssi;
  int qtd;

  Walk();

  Walk.fromMap(Map<String, dynamic> map) {
    beacon = map[beaconColumn];
    dist   = map[distColumn];
    rssi   = map[rssiColumn];
    qtd    = map[qtdColumn];
  }

  Map topMap() {
    Map<String, dynamic> map = {
      beaconColumn: beacon,
      distColumn: dist,
      rssiColumn: rssi,
      qtdColumn: qtd
    };

    return map;
  }

  @override
  String toString(){
    return "WalkTable(beacon: $beacon, dist: $dist, rssi: $rssi, qtd: $qtd)";
  }

}

class BestWalk {

  String beacon;
  int dist;

  BestWalk();

  BestWalk.fromMap(Map<String, dynamic> map) {
    beacon = map[beaconBest];
    dist   = map[distBest];
  }

  Map topMap() {
    Map<String, dynamic> map = {
      beaconBest: beacon,
      distBest: dist
    };

    return map;
  }

  @override
  String toString(){
    return "BestWalk(beacon: $beacon, dist: $dist)";
  }

}