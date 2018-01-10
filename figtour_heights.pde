import java.util.Arrays;

ArrayList<Edge> edges;
ArrayList<Intersection> intersections;
//ArrayList<Node> nodes;
Node[][] board;
float[][] lowerBounds;
float[][] upperBounds;
int w, h;

float zMax = 50;

boolean repel = false;
boolean rotate = false;

boolean save = false;

float rotation = 0;

int updateCount;

float gridSizeX, gridSizeY;

PrintWriter writer, timeSeriesWriter;

void setup() {
  size(600, 600, P3D);
  //fullScreen(P3D);
  edges = new ArrayList<Edge>();
  intersections = new ArrayList<Intersection>();

  String[] strings = loadStrings("figtour2.txt");
  int[] dim = getSize(strings);
  w = dim[0];
  h = dim[1];
  board = new Node[w][h];
  loadTour(strings, board);

  lowerBounds = new float[w][h];
  upperBounds = new float[w][h];

  loadBounds(0, -250, "figtourbrightnesses.dat");

  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      // lowerBounds[i][j] = 0;
      println("Lower bound at " + i + ", " + j + ": " + lowerBounds[i][j]);
      upperBounds[i][j] = 50;
      board[i][j].p.z = lowerBounds[i][j];
    }
  }

  gridSizeX = (float)width/w;
  gridSizeY = (float)height/h;
  for (int i=0; i<edges.size()-1; i++) {
    for (int j=i; j<edges.size(); j++) {
      Intersection intersect = edges.get(i).getIntersection(edges.get(j));
      if (intersect != null) {
        intersections.add(intersect);
      }
    }
  }

  println("There are " + intersections.size() + " intersections");

  repel = false;
  rotate = false;
  rotation = 0;

  updateCount = 0;

  background(255);
  
  String fileName = month() + "-" + day() + "-" + year() + "/" + hour() + ";" + minute() + "," + second();
  timeSeriesWriter = createWriter(fileName + "__ratio.txt");
}

void draw() {
  // zMax = map(mouseX, 0, width, 0, 250);
  zMax = 50;
  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      upperBounds[i][j] = lowerBounds[i][j] + zMax;
      //upperBounds[i][j] = 10;
    }
  }

  lights();

  if (rotate) {
    rotation += .01;
  }

  background(255);
  //fill(255);
  //rect(0, 0, width, height * .8);

  pushMatrix();
  translate(width/2, height/2);
  rotateX(rotation);
  translate(-width/2, -height/2);

  if (repel) {
    // for (int i=0; i<w; i++) {
    //   for (int j=0; j<h; j++) {
    //     float val = random(-1, 1) * zMax * .01 * (1 - ((float)updateCount / (updateCount + 30)));
    //     board[i][j].applyZForce(val);
    //   }
    // }

    // for (Intersection in : intersections) {
    //   Edge e = random(1)<.5?in.e1 : in.e2;
    //   Node n = random(1)<.5?e.p1 : e.p2;
    //   float val = random(-1, 1) * zMax * .01 * (1 - ((float)updateCount / (updateCount + 30)));
    //   n.applyZForce(val);
    // }

    for (int k=0; k<10; k++) {
      Intersection in = intersections.get((int)random(intersections.size()));
      Edge e = random(1)<.5?in.e1 : in.e2;
      Node n = random(1)<.5?e.p1 : e.p2;
      float val = random(-1, 1) * zMax * .1 * (1 - ((float)updateCount / (updateCount + 20)));
      // float val = random(-1, 1) * 50;
      // println("Value: " + val);
      n.applyZForce(val);
    }
    
    updatePoints();
  }

  if (save) {
    timeSeriesWriter.flush();
    timeSeriesWriter.close();
    String fileName = month() + "-" + day() + "-" + year() + "/" + hour() + ";" + minute() + "," + second();
    writer = createWriter(fileName + ".txt");
    for (int i=0; i<w; i++) {
      for (int j=0; j<h; j++) {
        int x = i+1;
        int y = j+1;
        float z = board[i][j].p.z;
        writer.println(x + " " + y + " " + z);
      }
    }
    writer.flush();
    writer.close();
    //beginRecord("nervoussystem.obj.OBJExport", fileName + ".obj");
  }

  fill(200);
  noStroke();

  //noFill();
  //stroke(0);
  //strokeWeight(1);

  for (Edge e : edges) {
    box(e.p1.p, e.p2.p);
    //line(e.p1.p, e.p2.p);
  }

  if (save) {
    //endRecord();
    save = false;
  }

  popMatrix();
}

void updatePoints() {
  float sum=0;
  float minDist = MAX_INT;
  for (Intersection i : intersections) {
    float d = i.getDistance();
    if (d < minDist) {
      minDist = d;
    }
    sum += d;
    i.applyForce();
  }

  attractToBounds();

  //println("Average distance: " + sum/intersections.size());
  //println("Smallest distance: " + minDist);
  if (updateCount % 5 == 0) {
    float ratio = minDist / (sum/intersections.size());
    println("Ratio: " + ratio);
    timeSeriesWriter.write(updateCount + " " + ratio);
    //int x = (updateCount/5) % width;
    //float y = height - (ratio * height * .2);
  }

  smoothTour();
  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      Node n = board[i][j];
      n.update();
      n.p.z = constrain(n.p.z, lowerBounds[i][j], upperBounds[i][j]);
    }
  }


  // updateCount = (updateCount + 1) % width;
  updateCount++;
}

void line(PVector p, PVector q) {
  line(p.x, p.y, p.z, q.x, q.y, q.z);
}

void box(PVector p, PVector q) {
  pushMatrix();
  PVector mid = PVector.lerp(p, q, .5);
  translate(mid.x, mid.y, mid.z);
  PVector v = PVector.sub(q, p);

  PVector upVec = new PVector(0, 0, 1);
  PVector axisOfRotation = v.cross(upVec);
  axisOfRotation.normalize();
  float angleOfRotation = PVector.angleBetween(v, upVec);
  rotate(-angleOfRotation, axisOfRotation.x, axisOfRotation.y, axisOfRotation.z);
  //fill(100);
  box(5, 5, v.mag());
  popMatrix();
}

void keyPressed() {
  if (key == ' ') {
    repel = !repel;
  }
  else if (key == 'r') {
    rotate = !rotate;
  }
  else if (key == 'f') {
    setup();
  }
  else if (key == 's') {
    save = true;
  }
}

void smoothTour() {
  float[][] heights;
  float[][] weights;
  heights = new float[w][h];
  weights = new float[w][h];
  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      heights[i][j] = 0;
      weights[i][j] = 0;
    }
  }
  // populate heights[i][j] with the weighted sum of all vertices connected the node at i,j
  // populate weights[i][j] with the sum of all weights of vertices connected to node at i,j
  for (Edge e : edges) {
    Node n1 = e.p1;
    Node n2 = e.p2;
    int i1 = (int)(n1.p.x/gridSizeX);
    int j1 = (int)(n1.p.y/gridSizeY);
    int i2 = (int)(n2.p.x/gridSizeX);
    int j2 = (int)(n2.p.y/gridSizeY);
    float w = 1/n1.p.dist(n2.p);
    heights[i1][j1] += n2.p.z * w;
    heights[i2][j2] += n1.p.z * w;
    weights[i1][j1] += w;
    weights[i2][j2] += w;
  }

  float maxDiff = 0;
  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      if (weights[i][j] > 0) {
        float avgHeight = heights[i][j]/weights[i][j];
        float currHeight = board[i][j].p.z;
        float diff = avgHeight - currHeight;
        if (abs(diff) > maxDiff) {
          maxDiff = abs(diff);
        }
        //println("Diff: " + diff);
        board[i][j].applyZForce(diff * .001);
      }
    }
  }
  // println("MAx diff: " + maxDiff);
}

int[] getSize(String[] strings) {
  int[] result = new int[2];
  int w = 8;
  int h = 8;
  String[] split1 = strings[0].split(" ");
  println(split1[0] + " , " + split1[1]);
  if (split1[0].equals("rows:")) {
    w = Integer.parseInt(split1[1]);
    String[] split2 = strings[1].split(" ");
    if (split2[0].equals("cols:")) {
      h = Integer.parseInt(split2[1]);
    }
  }
  result[0] = w;
  result[1] = h;
  return result;
}

void loadTour(String[] strings, Node[][] board) {
  Node currNode = null;
  boolean first = true;
  Node firstNode = null;
  int startIndex = 0;
  String[] split1 = strings[0].split(" ");
  if (split1[0].equals("rows:")) {
    startIndex = 2;
  }
  for (int k=startIndex; k<strings.length; k++) {
    String s = strings[k];
    String[] split = s.split(" ");
    if (split.length == 3 && split[0].equals("")) {
      split = new String[]{split[1], split[2]};
    }
    if (split.length == 2) {
      int i = Integer.parseInt(split[0]);
      int j = Integer.parseInt(split[1]);
      if (board[i][j] == null) {
        board[i][j] = new Node((float)i/(w+1)*width, (float)j/(h+1)*height);
      }
      if (!first) {
        edges.add(new Edge(currNode, board[i][j]));
      }
      else {
        firstNode = board[i][j];
      }
      currNode = board[i][j];
      first = false;
    }
    else {
      println("Error reading line: " + Arrays.toString(split));
    }
  }
  if (edges.get(edges.size()-1).p2 != firstNode) {
    edges.add(new Edge(currNode, firstNode));
  }
}

// 0 for lower, 1 for upper
void loadBounds(int boundType, float coef, String fileName) {
  String[] lines = loadStrings(fileName);
  String[] line1 = lines[0].split(" ");
  String[] line2 = lines[1].split(" ");

  float[][] bounds = boundType == 0 ? lowerBounds : upperBounds;

  println(line1[0] + ",      ," + line2[0]);
  if (!((line1[0].equals("rows:")) &&
      Integer.parseInt(line1[1]) == w-1 &&
      line2[0].equals("cols:") &&
      Integer.parseInt(line2[1]) == h-1)) {
        println("error on file input");
        return;
  }

  float[][] cells = new float[w-1][h-1];

  for (int i=2; i<min(lines.length, w-1); i++) {
    String[] words = lines[i].split(" ");
    int k=0;
    for (int j=0; j<words.length; j++) {
      if (!words[j].isEmpty()) {
        println("Word: " + words[j]);
        cells[i][k++] = coef * Float.parseFloat(words[j]);
      }
    }
  }

  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      float v1 = cells[max(0, i-1)][max(0, j-1)];
      float v2 = cells[max(0, i-1)][min(h-2, j)];
      float v3 = cells[min(w-2, i)][max(0, j-1)];
      float v4 = cells[min(w-2, i)][min(h-2, j)];
      bounds[i][j] = (v1 + v2 + v3 + v4)/4;
    }
  }
}

void attractToBounds() {
  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      board[i][j].repelFrom((lowerBounds[i][j] + upperBounds[i][j])/2);
    }
  }
}