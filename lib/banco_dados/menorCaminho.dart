import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

//primeira tabela -> pathTable
final String pathTable     = 'pathTable';
final String idColumn      = 'idColumn';
final String deColumn      = 'DeColumn';
final String paraColumn    = 'ParaColumn';
final String proximoColumn = 'ProximoColumn';
final String fraseColumn   = 'FraseColumn';

class MenorCaminho {

  static final MenorCaminho _instance = MenorCaminho.internal();

  factory MenorCaminho() => _instance;

  MenorCaminho.internal();

  Database _db;

  
  /*** Inicio - querys de controle ***/

    //verificar se banco de dados já foi criado. Caso não tenha sido, cria.
    Future<Database> get db async {
      if(_db != null){
        return _db;
      } else {
        _db = await initDb();

        //limpa tabela pathTable caso tenha alguma coisa
        await dropaPath();

        //000000000001 => biblioteca
        //000000000002 => cantina
        //000000000003 => sala 301 prédio 5
        //000000000004 => sala dos professores
        //000000000005 => coordenação

        //carga no banco com caminhos
        await preparaPath('000000000001', '000000000002', '000000000004', 'Seguir sentido sala dos professores e, para isso, é preciso andar pelo corredor por mais dez metros');
        await preparaPath('000000000001', '000000000003', '000000000003', 'Andar por dez metros pelo corredor, subir três lances de escada e, depois, andar por mais dez metros pelo corredor');
        await preparaPath('000000000001', '000000000004', '000000000004', 'Andar pelo corredor por mais dez metros');
        await preparaPath('000000000001', '000000000005', '000000000004', 'Seguir sentido sala dos professores e, para isso, é preciso andar pelo corredor por mais dez metros');
        await preparaPath('000000000002', '000000000001', '000000000005', 'Seguir sentido coordenação e, para isso, é preciso andar por cinco metros, subir dois lances de escadas e, depois, andar reto por mais quinze metros');
        await preparaPath('000000000002', '000000000003', '000000000005', 'Seguir sentido coordenação e, para isso, é preciso andar por cinco metros, subir dois lances de escadas e, depois, andar reto por mais quinze metros');
        await preparaPath('000000000002', '000000000004', '000000000005', 'Seguir sentido coordenação e, para isso, é preciso andar por cinco metros, subir dois lances de escadas e, depois, andar reto por mais quinze metros');
        await preparaPath('000000000002', '000000000005', '000000000005', 'Andar por cinco metros, subir dois lances de escadas e, depois, andar reto por mais quinze metros');
        await preparaPath('000000000003', '000000000001', '000000000001', 'Andar por dez metros pelo corredor, descer três lances de escada e, depois, andar por mais dez metros pelo corredor');
        await preparaPath('000000000003', '000000000002', '000000000001', 'Seguir sentido biblioteca e, para isso, é preciso andar por dez metros pelo corredor, descer três lances de escada e, depois, andar por mais dez metros pelo corredor');
        await preparaPath('000000000003', '000000000004', '000000000001', 'Seguir sentido biblioteca e, para isso, é preciso andar por dez metros pelo corredor, descer três lances de escada e, depois, andar por mais dez metros pelo corredor');
        await preparaPath('000000000003', '000000000005', '000000000001', 'Seguir sentido biblioteca e, para isso, é preciso andar por dez metros pelo corredor, descer três lances de escada e, depois, andar por mais dez metros pelo corredor');
        await preparaPath('000000000004', '000000000001', '000000000001', 'Andar pelo corredor por mais dez metros');
        await preparaPath('000000000004', '000000000002', '000000000005', 'Seguir sentido coordenação e, para isso, é preciso andar pelo corredor por mais dez metros');
        await preparaPath('000000000004', '000000000003', '000000000001', 'Seguir sentido biblioteca e, para isso, é preciso andar pelo corredor por mais dez metros');
        await preparaPath('000000000004', '000000000005', '000000000005', 'Andar pelo corredor por dez metros');
        await preparaPath('000000000005', '000000000001', '000000000004', 'Seguir sentido sala dos professores e, para isso, é preciso andar pelo corredor por mais dez metros');
        await preparaPath('000000000005', '000000000002', '000000000002', 'Andar por quinze metros, descer dois lances de escadas e, depois, andar reto por mais cinco metros');
        await preparaPath('000000000005', '000000000003', '000000000004', 'Seguir sentido sala dos professores e, para isso, é preciso andar pelo corredor por mais dez metros');
        await preparaPath('000000000005', '000000000004', '000000000004', 'Andar pelo corredor por dez metros');

        return _db;
      }
    }

    //função para criar banco de dados e tabelas
    Future<Database> initDb() async {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'paths.db');

      return await openDatabase(path, version: 1, onCreate: (Database db, int newerVersion) async{
        await db.execute(
          'CREATE TABLE $pathTable($idColumn INTEGER PRIMARY KEY, $deColumn TEXT, $paraColumn TEXT, $proximoColumn TEXT, $fraseColumn TEXT)'
        );
      });
    }

    //prepara para inserir em pathTable
    Future<void> preparaPath(String word1, String word2, String word3, String word4) async {
      Path p = Path();
      p.de      = word1;
      p.para    = word2;
      p.proximo = word3;
      p.frase   = word4;

      savePath(p);
    }

    //função para salvar um caminho em pathTable
    Future<Path> savePath(Path path) async {
      Database dbPath = await db;

      path.id = await dbPath.insert(pathTable, path.topMap());
      return path;
    }

    //dropa pathTable
    Future<int> dropaPath() async {
      Database dbPath = await db;

      return await dbPath.rawDelete("DELETE FROM $pathTable");
    }

    //função para fechar o banco de dados
    Future close() async {
      Database dbPath = await db;

      dbPath.close();
    }

  /*** Fim - querys de controle ***/

  /*** Inicio - querys de busca ***/

    //função para obter todas as palavras gravadas
    Future<List> getAllCaminhos() async {
      Database dbPath = await db;

      List listMap = await dbPath.rawQuery("SELECT * FROM $pathTable");
      List<Path> listWalk = List();

      for(Map m in listMap){
        listWalk.add(Path.fromMap(m));
      }

      return listWalk;
    }
  
    //função para obter todas os caminhos gravadas
    Future<Path> getCaminho(String word1, String word2) async {
      Database dbPath = await db;

      List<Map> maps = await dbPath.query(pathTable,
        columns: [idColumn, deColumn, paraColumn, proximoColumn, fraseColumn],
        where: "deColumn = ? AND paraColumn = ?",
        whereArgs: [word1, word2]);
      
      if(maps.length > 0){
        return Path.fromMap(maps.first);
      } else {
        return null;
      }
    }

  /*** Fim - querys de busca ***/
}

class Path {

  int id;
  String de;
  String para;
  String proximo;
  String frase;

  Path();

  Path.fromMap(Map<String, dynamic> map) {
    id      = map[idColumn];
    de      = map[deColumn];
    para    = map[paraColumn];
    proximo = map[proximoColumn];
    frase   = map[fraseColumn];
  }

  Map topMap() {
    Map<String, dynamic> map = {
      deColumn: de,
      paraColumn: para,
      proximoColumn: proximo,
      fraseColumn: frase
    };

    if(id != null){
      map[idColumn] = id;
    }

    return map;
  }

  @override
  String toString(){
    return "MenorCaminho(id: $id, de: $de, para: $para, proximo: $proximo, frase: $frase)";
  }

}