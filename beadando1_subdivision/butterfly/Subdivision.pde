void applySubdivisionAndSmoothing() {
  ArrayList<PVector> newVertices = new ArrayList<PVector>(vertices);
  ArrayList<int[]> newFaces = new ArrayList<int[]>();
  HashMap<String, Integer> edgeMidpoints = new HashMap<String, Integer>();
  
  for (int[] f : faces) {
    int i0 = f[0], i1 = f[1], i2 = f[2];
    
    int im01 = getOrCreateMidpoint(i0, i1, newVertices, edgeMidpoints);
    int im12 = getOrCreateMidpoint(i1, i2, newVertices, edgeMidpoints);
    int im20 = getOrCreateMidpoint(i2, i0, newVertices, edgeMidpoints);
    
    newFaces.add(new int[]{i0, im01, im20});
    newFaces.add(new int[]{im01, i1, im12});
    newFaces.add(new int[]{im20, im12, i2});
    newFaces.add(new int[]{im01, im12, im20});
  }
  
  vertices = newVertices;
  faces = newFaces;
  smoothMesh();
}

int getOrCreateMidpoint(int a, int b, ArrayList<PVector> vList, HashMap<String, Integer> cache) {
  String key = (a < b) ? a + "_" + b : b + "_" + a;
  if (cache.containsKey(key)) return cache.get(key);
  
  PVector mid = PVector.lerp(vList.get(a), vList.get(b), 0.5);
  int index = vList.size();
  vList.add(mid);
  cache.put(key, index);
  return index;
}

void smoothMesh() {
  ArrayList<HashSet<Integer>> neighbors = new ArrayList<HashSet<Integer>>();
  for (int i = 0; i < vertices.size(); i++) neighbors.add(new HashSet<Integer>());
  
  for (int[] f : faces) {
    neighbors.get(f[0]).add(f[1]); neighbors.get(f[0]).add(f[2]);
    neighbors.get(f[1]).add(f[0]); neighbors.get(f[1]).add(f[2]);
    neighbors.get(f[2]).add(f[0]); neighbors.get(f[2]).add(f[1]);
  }
  
  ArrayList<PVector> smoothedVertices = new ArrayList<PVector>();
  for (int i = 0; i < vertices.size(); i++) {
    PVector v = vertices.get(i);
    HashSet<Integer> ns = neighbors.get(i);
    
    if (ns.size() == 0) {
      smoothedVertices.add(v.copy());
      continue;
    }
    
    PVector sum = new PVector(0, 0, 0);
    for (int nIdx : ns) sum.add(vertices.get(nIdx));
    sum.div(ns.size());
    
    PVector smoothed = PVector.lerp(v, sum, 0.5);
    smoothedVertices.add(smoothed);
  }
  vertices = smoothedVertices;
}
