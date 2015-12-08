
const ITERATIONS = 1000000;

fillArray(a) {
  var n = 0;
  for (var i = 0; i < ITERATIONS; i++) {
    a.add(n);
    n++;
    if (n > 15) {
      n = 0;
    }
  }
}

fillArray2(a) {
  var n = 0;
  for (var i = 0; i < ITERATIONS; i++) {
    a[i] = n;
    n++;
    if (n > 15) {
      n = 0;
    }
  }
}

countPresence(a, n) {
  var r = 0, len = a.length;
  for (var i = 0; i < len; i++) {
    if (a[i] == n) {
      r++;
    }
  }
  return r;
}

const CHAR = 11;

main() {
  var a = [];

  countIt() {
    var n = countPresence(a, CHAR);
    print("count of number ${CHAR}: ${n}");
  }

  fillArray(a);
  countIt();

  a = new List(ITERATIONS);
  fillArray2(a);
  countIt();
}
