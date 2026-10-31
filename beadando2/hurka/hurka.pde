PVector[] controlPoints;
int draggedIndex = -1;

void setup() {
  size(800, 600, P2D);
  
  controlPoints = new PVector[5];
  controlPoints[0] = new PVector(100, 500);
  controlPoints[1] = new PVector(200, 100);
  controlPoints[2] = new PVector(600, 100);
  controlPoints[3] = new PVector(650, 300);
  controlPoints[4] = new PVector(700, 500);
}

void draw() {
  background(255);
  circle(400, 300, 100);
  
  // Control polygon
  stroke(180);
  noFill();
  beginShape();
  for (int i = 0; i < controlPoints.length; i++) {
    vertex(controlPoints[i].x, controlPoints[i].y);
  }
  endShape();

  // Control points
  fill(220, 50, 50);
  noStroke();
  for (int i = 0; i < controlPoints.length; i++) {
    circle(controlPoints[i].x, controlPoints[i].y, 10);
  }

  // Bézier curve
  stroke(0, 100, 220);
  noFill();
  beginShape();
  int samples = 200;
  for (int s = 0; s <= samples; s++) {
    float t = s / (float)samples;
    PVector p = bezierPointBernstein(controlPoints, t);
    vertex(p.x, p.y);
  } 
  endShape();
}

void mousePressed() {
  for (int i = 0; i < controlPoints.length; i++) {
    if (dist(mouseX, mouseY, controlPoints[i].x, controlPoints[i].y) < 10) {
      draggedIndex = i;
      break;
    }
  }
}

void mouseDragged() {
  if (draggedIndex != -1) {
    controlPoints[draggedIndex].set(mouseX, mouseY);
    redraw();
  }
}

void mouseReleased() {
  draggedIndex = -1;
}

PVector bezierPointBernstein(PVector[] points, float t) {
  int n = points.length - 1;
  PVector result = new PVector(0, 0);

  for (int i = 0; i <= n; i++) {
    float b = bernstein(n, i, t);
    result.add(PVector.mult(points[i], b));
  }

  return result;
}

float bernstein(int n, int i, float t) {
  return binomial(n, i) * pow(t, i) * pow(1 - t, n - i);
}

float binomial(int n, int k) {
  if (k < 0 || k > n) return 0;
  if (k > n - k) k = n - k;
  
  float result = 1;
  for (int j = 1; j <= k; j++) {
    result *= (n - k + j);
    result /= j;
  }
  
  return result;
}
