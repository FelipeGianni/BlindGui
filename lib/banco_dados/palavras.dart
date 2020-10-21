import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

//primeira tabela -> para beacons
final String palavraTable   = 'palavraTable';
final String idColumn       = 'idColumn';
final String palavraColumn  = 'palavraColumn';
final String idBeaconColumn = 'idBeaconColumn';

class PalavrasChave {

  static final PalavrasChave _instance = PalavrasChave.internal();

  factory PalavrasChave() => _instance;

  PalavrasChave.internal();

  Database _db;

  //verificar se banco de dados já foi criado. Caso não tenha sido, cria.
  Future<Database> get db async {
    if(_db != null){
      return _db;
    } else {
      _db = await initDb();

      //limpa tabela palavraTable caso tenha alguma coisa
      await dropaPalavra();

      //carga no banco com palavras chave
      await preparaPalavra('biblioteca', '000000000001');
      await preparaPalavra('cantina', '000000000002');
      await preparaPalavra('sala 301 prédio 5', '000000000003');
      await preparaPalavra('sala dos professores', '000000000004');
      await preparaPalavra('coordenação', '000000000005');

      return _db;
    }
  }

  //função para criar banco de dados
  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'palavras.db');

    return await openDatabase(path, version: 1, onCreate: (Database db, int newerVersion) async{
      await db.execute(
        'CREATE TABLE $palavraTable($idColumn INTEGER PRIMARY KEY, $palavraColumn TEXT, $idBeaconColumn  TEXT)'
      );
    });
  }

  //prepara pra insert
  Future<void> preparaPalavra(String word, String beacon) async {
    Palavra p = Palavra();
    p.palavra = word;
    p.beacon  = beacon;

    savePalavra(p);
  }

  //função para salvar uma palavra
  Future<Palavra> savePalavra(Palavra palavra) async {
    Database dbPalavra = await db;

    palavra.id = await dbPalavra.insert(palavraTable, palavra.topMap());
    return palavra;
  }

  //função para retornar dados através de uma palavra
  Future<Palavra> getPalavra(String word) async {
    Database dbPalavra = await db;

    List<Map> maps = await dbPalavra.query(palavraTable,
      columns: [idColumn, palavraColumn, idBeaconColumn],
      where: "palavraColumn = ?",
      whereArgs: [word]);
    
    if(maps.length > 0){
      return Palavra.fromMap(maps.first);
    } else {
      return null;
    }
  }

  //função para retornar dados através de um id de beacon
  Future<Palavra> getIdBeacon(String word) async {
    Database dbPalavra = await db;

    List<Map> maps = await dbPalavra.query(palavraTable,
      columns: [idColumn, palavraColumn, idBeaconColumn],
      where: "idBeaconColumn = ?",
      whereArgs: [word]);
    
    if(maps.length > 0){
      return Palavra.fromMap(maps.first);
    } else {
      return null;
    }
  }

  //dropa tabela
  Future<int> dropaPalavra() async {
    Database dbPalavra = await db;

    return await dbPalavra.rawDelete("DELETE FROM $palavraTable");
  }
  
  //função para obter todas as palavras gravadas
  Future<List> getAllPalavras() async {
    Database dbPalavra = await db;

    List listMap = await dbPalavra.rawQuery("SELECT * FROM $palavraTable");
    List<Palavra> listPalavra = List();

    for(Map m in listMap){
      listPalavra.add(Palavra.fromMap(m));
    }

    return listPalavra;
  }

  //apaga determinada palavra
  Future<int> deletePalavra(int id) async {
    Database dbPalavra = await db;

    return await dbPalavra.delete(palavraTable, where: "$idColumn = ?", whereArgs: [id]);
  }

  //atualiza determinada palavra
  Future<int> updatePalavra(Palavra palavra) async {
    Database dbPalavra = await db;

    return await dbPalavra.update(palavraTable, palavra.topMap(), where: "$idColumn = ?", whereArgs: [palavra.id]);
  }

  //função para obter numero total de palavras cadastradas
  Future<int> getNumber() async {
    Database dbPalavra = await db;

    return Sqflite.firstIntValue(await dbPalavra.rawQuery("SELECT COUNT(*) FROM $palavraTable"));
  }

  //função para fechar o banco de dados
  Future close() async {
    Database dbPalavra = await db;

    dbPalavra.close();
  }
}

class Palavra {

  int id;
  String palavra;
  String beacon;

  Palavra();

  Palavra.fromMap(Map map) {
    id      = map[idColumn];
    palavra = map[palavraColumn];
    beacon  = map[idBeaconColumn];
  }

  Map topMap() {
    Map<String, dynamic> map = {
      palavraColumn: palavra,
      idBeaconColumn: beacon
    };

    if(id != null){
      map[idColumn] = id;
    }

    return map;
  }

  @override
  String toString(){
    return "Palavra(id: $id, palavra: $palavra, beacon: $beacon)";
  }

}