
var ITERATIONS = 1000000;

function fillArray(a) {
  var n = 0;
  for (var i = 0; i < ITERATIONS; i++) {
    a.push(n);
    n++;
    if (n > 15) {
      n = 0;
    }
  }
}

function fillArray2(a) {
  var n = 0;
  for (var i = 0; i < ITERATIONS; i++) {
    a[i] = n;
    n++;
    if (n > 15) {
      n = 0;
    }
  }
}

function countPresence(a, n) {
  var r = 0, len = a.length;
  for (var i = 0; i < len; i++) {
    if (a[i] === n) {
      r++;
    }
  }
  return r;
}

const CHAR = 11;

var a = [];

function countIt() {
  var n = countPresence(a, CHAR);
  console.log(`count of number ${CHAR}: ${n}`);
}

fillArray(a);
countIt();

a = new Array(ITERATIONS);
fillArray2(a);
countIt();
