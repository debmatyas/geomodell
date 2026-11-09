// ---- Közös segédek a subdivision algoritmusokhoz ----

// Élek nyilvántartása: minden élhez eltároljuk a végpontjait és a szomszédos lapokat.
// Az élek sorszáma (0, 1, 2, ...) köti össze a három gyűjteményt.
class EdgeData {
  HashMap<Long, Integer> index = new HashMap<Long, Integer>();   // él kulcsa -> él sorszáma
  ArrayList<int[]> ends = new ArrayList<int[]>();  // {a, b}: az él két végpontja (csúcsindex)
  ArrayList<int[]> adj  = new ArrayList<int[]>();  // {lap0, lap1, lapSzám}: az élt tartalmazó lapok sorszáma és darabszáma (-1 = nincs lap)
  int vertexCount;   // a csúcsok száma, a kulcsképzéshez kell

  EdgeData(int vertexCount) {
    this.vertexCount = vertexCount;
  }

  // Egyedi azonosító az élhez, független a végpontok sorrendjétől (a-b ugyanaz, mint b-a)
  // A (long) azért kell, hogy a szorzás ne csorduljon túl nagy hálónál
  long key(int a, int b) {
    return (long) Math.min(a, b) * vertexCount + Math.max(a, b);
  }

  // Az a-b él sorszámának megkeresése (az élnek már szerepelnie kell a katalógusban)
  int find(int a, int b) {
    return index.get(key(a, b));
  }

  // Bejegyzi, hogy az a-b él a faceIdx-edik laphoz tartozik; ha az él új, felveszi a katalógusba
  void addFace(int a, int b, int faceIdx) {
    long k = key(a, b);
    Integer e = index.get(k);
    if (e == null) {
      // első előfordulás: új él, új sorszámmal
      e = ends.size();
      index.put(k, e);
      ends.add(new int[]{a, b});
      adj.add(new int[]{-1, -1, 0});
    }
    int[] ad = adj.get(e);
    if (ad[2] < 2) ad[ad[2]] = faceIdx;   // az első két lapot eltároljuk
    ad[2]++;                              // a lapok számát mindig növeljük (3 vagy több = nem-manifold él)
  }

  // Belső él: pontosan két lap osztozik rajta
  boolean isInterior(int e) {
    return adj.get(e)[2] == 2;
  }
}

// Felépíti az élkatalógust: végigmegy az összes lapon, és minden élét bejegyzi
EdgeData buildEdges(ArrayList<int[]> fs, int vertexCount) {
  EdgeData ed = new EdgeData(vertexCount);
  for (int fi = 0; fi < fs.size(); fi++) {
    int[] f = fs.get(fi);
    for (int i = 0; i < f.length; i++) {
      // az (i + 1) % hossz miatt az utolsó csúcs az elsőhöz kapcsolódik (zárt lap)
      ed.addFace(f[i], f[(i + 1) % f.length], fi);
    }
  }
  return ed;
}

// Minden csúcshoz a belőle induló élek listája (élek sorszámai)
ArrayList<ArrayList<Integer>> buildVertexEdges(EdgeData ed, int vertexCount) {
  ArrayList<ArrayList<Integer>> vEdges = new ArrayList<ArrayList<Integer>>();
  for (int i = 0; i < vertexCount; i++) vEdges.add(new ArrayList<Integer>());   // minden csúcsnak üres lista
  for (int e = 0; e < ed.ends.size(); e++) {
    int[] en = ed.ends.get(e);
    vEdges.get(en[0]).add(e);   // az él mindkét végpontjához hozzáadjuk
    vEdges.get(en[1]).add(e);
  }
  return vEdges;
}

// Többszögű lapok háromszögekre bontása (Loop és Butterfly háromszöghálót igényel)
void ensureTriangles() {
  ArrayList<int[]> tris = new ArrayList<int[]>();
  for (int[] f : faces) {
    if (f.length == 3) {
      tris.add(f);   // a háromszög változatlanul átmegy
    } else if (f.length > 3) {
      // legyezős bontás: az f[0] csúcsból húzott átlókkal n-2 háromszög lesz
      for (int i = 1; i < f.length - 1; i++) {
        tris.add(new int[]{f[0], f[i], f[i + 1]});
      }
    }
    // 3-nál kevesebb csúcsú lap degenerált, kimarad
  }
  faces = tris;
}
