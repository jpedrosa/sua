// Copyright 2011 Google Inc. All Rights Reserved.
// Copyright 1996 John Maloney and Mario Wolczko
//
// This file is part of GNU Smalltalk.
//
// GNU Smalltalk is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2, or (at your option) any later version.
//
// GNU Smalltalk is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// GNU Smalltalk; see the file COPYING.  If not, write to the Free Software
// Foundation, 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// Translated first from Smalltalk to JavaScript, and finally to
// Dart by Google 2008-2010.
//
// Translated to Swift by Joao Pedrosa 2015.
// Translated to Wren by Bob Nystrom 2014.

// A Wren implementation of the DeltaBlue constraint-solving
// algorithm, as described in:
//
// "The DeltaBlue Algorithm: An Incremental Constraint Hierarchy Solver"
//   Bjorn N. Freeman-Benson and John Maloney
//   January 1990 Communications of the ACM,
//   also available as University of Washington TR 89-08-06.
//
// Beware: this benchmark is written in a grotesque style where
// the constraint model is built by side-effects from constructors.
// I've kept it this way to avoid deviating too much from the original
// implementation.

// Strengths are used to measure the relative importance of constraints.
// New strengths may be inserted in the strength hierarchy without
// disrupting current constraints.  Strengths cannot be created outside
// this class, so == can be used for value comparison.

class Strength {

  var value = 0
  var name = ""

  init(value: Int, name: String) {
    self.value = value
    self.name = name
  }

  var nextWeaker: Strength {
    get { return ORDERED[value] }
  }

  static func stronger(s1: Strength, s2: Strength) -> Bool {
    return s1.value < s2.value
  }

  static func weaker(s1: Strength, s2: Strength) -> Bool {
    return s1.value > s2.value
  }

  static func weakest(s1: Strength, s2: Strength) -> Strength {
    return Strength.weaker(s1, s2: s2) ? s1 : s2
  }

  static func strongest(s1: Strength, s2: Strength) -> Strength {
    return Strength.stronger(s1, s2: s2) ? s1 : s2
  }

}

// Compile time computed constants.
let REQUIRED        = Strength(value: 0, name: "required")
let STRONG_REFERRED = Strength(value: 1, name: "strongPreferred")
let PREFERRED       = Strength(value: 2, name: "preferred")
let STRONG_DEFAULT  = Strength(value: 3, name: "strongDefault")
let NORMAL          = Strength(value: 4, name: "normal")
let WEAK_DEFAULT    = Strength(value: 5, name: "weakDefault")
let WEAKEST         = Strength(value: 6, name: "weakest")

let ORDERED = [
  WEAKEST, WEAK_DEFAULT, NORMAL, STRONG_DEFAULT, PREFERRED, STRONG_REFERRED
]

var planner = Planner()

class Constraint {

  var strength: Strength
  var variable: Variable

  init(variable: Variable, strength: Strength) {
    self.variable = variable
    self.strength = strength
  }

  // Override me.
  func addToGraph() {}

  // Override me.
  func removeFromGraph() {}

  // Activate this constraint and attempt to satisfy it.
  func addConstraint() {
    addToGraph()
    planner.incrementalAdd(self)
  }

  // Override me.
  func markInputs(mark: Int) {}

  // Override me.
  func chooseMethod(mark: Int) {}

  // Override me.
  var isSatisfied: Bool {
    get { return false }
  }

  // Override me.
  var output: Variable {
    get { return variable }
  }

  // Override me.
  func markUnsatisfied() {}

  // Attempt to find a way to enforce this constraint. If successful,
  // record the solution, perhaps modifying the current dataflow
  // graph. Answer the constraint that this constraint overrides, if
  // there is one, or nil, if there isn't.
  // Assume: I am not already satisfied.
  func satisfy(mark: Int) -> Constraint? {
    chooseMethod(mark)
    if (!isSatisfied) {
      if (strength === REQUIRED) {
        print("Could not satisfy a required constraint!")
      }
      return nil
    }

    markInputs(mark)
    let out = output
    let overridden = out.determinedBy
    overridden?.markUnsatisfied()
    out.determinedBy = self
    if (!planner.addPropagate(self, mark: mark)) {
      print("Cycle encountered")
    }
    out.mark = mark
    return overridden
  }

  func destroyConstraint() {
    if (isSatisfied) {
      planner.incrementalRemove(self)
    }
    removeFromGraph()
  }

  // Normal constraints are not input constraints.  An input constraint
  // is one that depends on external state, such as the mouse, the
  // keybord, a clock, or some arbitraty piece of imperative code.
  var isInput: Bool {
    get { return false }
  }

  // Override me.
  func execute() {}

  // Override me.
  func inputsKnown(mark: Int) -> Bool {
    return false
  }

  // Override me.
  func recalculate() {}

}

// Abstract superclass for constraints having a single possible output variable.
class UnaryConstraint: Constraint {

  var satisfied = false

  override init(variable: Variable, strength: Strength) {
    super.init(variable: variable, strength: strength)
    addConstraint()
  }

  // Adds this constraint to the constraint graph.
  override func addToGraph() {
    output.addConstraint(self)
    satisfied = false
  }

  // Decides if this constraint can be satisfied and records that decision.
  override func chooseMethod(mark: Int) {
    satisfied = (output.mark != mark) &&
        Strength.stronger(strength, s2: output.walkStrength)
  }

  // Returns true if this constraint is satisfied in the current solution.
  override var isSatisfied: Bool {
    get { return satisfied }
  }

  override func markInputs(mark: Int) {
    // has no inputs.
  }

  // Calculate the walkabout strength, the stay flag, and, if it is
  // 'stay', the value for the current output of this constraint. Assume
  // this constraint is satisfied.
  override func recalculate() {
    output.walkStrength = strength
    output.stay = !isInput
    if (output.stay) {
      execute() // Stay optimization.
    }
  }

  // Records that this constraint is unsatisfied.
  override func markUnsatisfied() {
    satisfied = false
  }

  override func inputsKnown(mark: Int) -> Bool {
    return true
  }

  override func removeFromGraph() {
    output.removeConstraint(self)
    satisfied = false
  }

}

// Variables that should, with some level of preference, stay the same.
// Planners may exploit the fact that instances, if satisfied, will not
// change their output during plan execution.  This is called "stay
// optimization".
class StayConstraint: UnaryConstraint {

  override func execute() {
    // Stay constraints do nothing.
  }

}

// A unary input constraint used to mark a variable that the client
// wishes to change.
class EditConstraint: UnaryConstraint {

  // Edits indicate that a variable is to be changed by imperative code.
  override var isInput: Bool {
    get { return true }
  }

  override func execute() {
    // Edit constraints do nothing.
  }

}

// Directions.
let NONE = 1
let FORWARD = 2
let BACKWARD = 0

// Abstract superclass for constraints having two possible output
// variables.
class BinaryConstraint: Constraint {

  var v1: Variable
  var v2: Variable
  var direction: Int

  init(v1: Variable, v2: Variable, strength: Strength) {
    self.v1 = v1
    self.v2 = v2
    direction = NONE
    super.init(variable: v1, strength: strength)
    addConstraint()
  }

  // Decides if this constraint can be satisfied and which way it
  // should flow based on the relative strength of the variables related,
  // and record that decision.
  override func chooseMethod(mark: Int) {
    if (v1.mark == mark) {
      if (v2.mark != mark &&
          Strength.stronger(strength, s2: v2.walkStrength)) {
        direction = FORWARD
      } else {
        direction = NONE
      }
    }

    if (v2.mark == mark) {
      if (v1.mark != mark &&
          Strength.stronger(strength, s2: v1.walkStrength)) {
        direction = BACKWARD
      } else {
        direction = NONE
      }
    }

    if (Strength.weaker(v1.walkStrength, s2: v2.walkStrength)) {
      if (Strength.stronger(strength, s2: v1.walkStrength)) {
        direction = BACKWARD
      } else {
        direction = NONE
      }
    } else {
      if (Strength.stronger(strength, s2: v2.walkStrength)) {
        direction = FORWARD
      } else {
        direction = BACKWARD
      }
    }
  }

  // Add this constraint to the constraint graph.
  override func addToGraph() {
    v1.addConstraint(self)
    v2.addConstraint(self)
    direction = NONE
  }

  // Answer true if this constraint is satisfied in the current solution.
  override var isSatisfied: Bool {
    get { return direction != NONE }
  }

  // Mark the input variable with the given mark.
  override func markInputs(mark: Int) {
    input.mark = mark
  }

  // Returns the current input variable
  var input: Variable {
    get { return direction == FORWARD ? v1 : v2 }
  }

  // Returns the current output variable.
  override var output: Variable {
    get { return direction == FORWARD ? v2 : v1 }
  }

  // Calculate the walkabout strength, the stay flag, and, if it is
  // 'stay', the value for the current output of this
  // constraint. Assume this constraint is satisfied.
  override func recalculate() {
    let ihn = input
    let out = output
    out.walkStrength = Strength.weakest(strength, s2: ihn.walkStrength)
    out.stay = ihn.stay
    if (out.stay) {
      execute()
    }
  }

  // Record the fact that this constraint is unsatisfied.
  override func markUnsatisfied() {
    direction = NONE
  }

  override func inputsKnown(mark: Int) -> Bool {
    let i = input
    return i.mark == mark || i.stay || i.determinedBy == nil
  }

  override func removeFromGraph() {
    v1.removeConstraint(self)
    v2.removeConstraint(self)
    direction = NONE
  }

}

// Relates two variables by the linear scaling relationship: "v2 =
// (v1 * scale) + offset". Either v1 or v2 may be changed to maintain
// this relationship but the scale factor and offset are considered
// read-only.
class ScaleConstraint: BinaryConstraint {

  var scale: Variable
  var offset: Variable

  init(src: Variable, scale: Variable, offset: Variable, dest: Variable,
      strength: Strength) {
    self.scale = scale
    self.offset = offset
    super.init(v1: src, v2: dest, strength: strength)
  }

  // Adds this constraint to the constraint graph.
  override func addToGraph() {
    super.addToGraph()
    scale.addConstraint(self)
    offset.addConstraint(self)
  }

  override func removeFromGraph() {
    super.removeFromGraph()
    scale.removeConstraint(self)
    offset.removeConstraint(self)
  }

  override func markInputs(mark: Int) {
    super.markInputs(mark)
    scale.mark = mark
    offset.mark = mark
  }

  // Enforce this constraint. Assume that it is satisfied.
  override func execute() {
    if (direction == FORWARD) {
      v2.value = v1.value * scale.value + offset.value
    } else {
      v1.value = (v2.value - offset.value) / scale.value
    }
  }

  // Calculate the walkabout strength, the stay flag, and, if it is
  // 'stay', the value for the current output of this constraint. Assume
  // this constraint is satisfied.
  override func recalculate() {
    let ihn = input
    let out = output
    out.walkStrength = Strength.weakest(strength, s2: ihn.walkStrength)
    out.stay = ihn.stay && scale.stay && offset.stay
    if (out.stay) {
      execute()
    }
  }
}

// Constrains two variables to have the same value.
class EqualityConstraint: BinaryConstraint {

  // Enforce this constraint. Assume that it is satisfied.
  override func execute() {
    output.value = input.value
  }

}

// A constrained variable. In addition to its value, it maintain the
// structure of the constraint graph, the current dataflow graph, and
// various parameters of interest to the DeltaBlue incremental
// constraint solver.
class Variable {

  var constraints: [Constraint] = []
  var determinedBy: Constraint?
  var mark = 0
  var walkStrength = WEAKEST
  var stay = true
  var name = ""
  var value = 0

  init(name: String, value: Int) {
    self.name = name
    self.value = value
  }

  // Add the given constraint to the set of all constraints that refer
  // this variable.
  func addConstraint(constraint: Constraint) {
    constraints.append(constraint)
  }

  // Removes all traces of c from this variable.
  func removeConstraint(constraint: Constraint) {
    constraints = constraints.filter({ $0 !== constraint })
    if let c = determinedBy {
      if (c === constraint) {
        determinedBy = nil
      }
    }
  }

}

// A Plan is an ordered list of constraints to be executed in sequence
// to resatisfy all currently satisfiable constraints in the face of
// one or more changing inputs.
class Plan {

  var list: [Constraint] = []

  func addConstraint(constraint: Constraint) {
    list.append(constraint)
  }

  var size: Int {
    get { return list.count }
  }

  func execute() {
    for constraint in list {
      constraint.execute()
    }
  }

}

class Planner {

  var currentMark = 0

  // Attempt to satisfy the given constraint and, if successful,
  // incrementally update the dataflow graph.  Details: If satifying
  // the constraint is successful, it may override a weaker constraint
  // on its output. The algorithm attempts to resatisfy that
  // constraint using some other method. This process is repeated
  // until either a) it reaches a variable that was not previously
  // determined by any constraint or b) it reaches a constraint that
  // is too weak to be satisfied using any of its methods. The
  // variables of constraints that have been processed are marked with
  // a unique mark value so that we know where we've been. This allows
  // the algorithm to avoid getting into an infinite loop even if the
  // constraint graph has an inadvertent cycle.
  func incrementalAdd(constraint: Constraint) {
    let mark = newMark()
    var overridden = constraint.satisfy(mark)
    while overridden != nil {
      overridden = overridden?.satisfy(mark)
    }
  }

  // Entry point for retracting a constraint. Remove the given
  // constraint and incrementally update the dataflow graph.
  // Details: Retracting the given constraint may allow some currently
  // unsatisfiable downstream constraint to be satisfied. We therefore collect
  // a list of unsatisfied downstream constraints and attempt to
  // satisfy each one in turn. This list is traversed by constraint
  // strength, strongest first, as a heuristic for avoiding
  // unnecessarily adding and then overriding weak constraints.
  // Assume: [c] is satisfied.
  func incrementalRemove(constraint: Constraint) {
    let out = constraint.output
    constraint.markUnsatisfied()
    constraint.removeFromGraph()
    let unsatisfied = removePropagateFrom(out)
    var strength = REQUIRED
    while (true) {
      for u in unsatisfied {
        if (u.strength === strength) {
          incrementalAdd(u)
        }
      }
      strength = strength.nextWeaker
      if (strength === WEAKEST) {
        break
      }
    }
  }

  // Select a previously unused mark value.
  func newMark() -> Int {
    currentMark = currentMark + 1
    return currentMark
  }

  // Extract a plan for resatisfaction starting from the given source
  // constraints, usually a set of input constraints. This method
  // assumes that stay optimization is desired; the plan will contain
  // only constraints whose output variables are not stay. Constraints
  // that do no computation, such as stay and edit constraints, are
  // not included in the plan.
  // Details: The outputs of a constraint are marked when it is added
  // to the plan under construction. A constraint may be appended to
  // the plan when all its input variables are known. A variable is
  // known if either a) the variable is marked (indicating that has
  // been computed by a constraint appearing earlier in the plan), b)
  // the variable is 'stay' (i.e. it is a constant at plan execution
  // time), or c) the variable is not determined by any
  // constraint. The last provision is for past states of history
  // variables, which are not stay but which are also not computed by
  // any constraint.
  // Assume: [sources] are all satisfied.
  func makePlan(sources: [Constraint]) -> Plan {
    let mark = newMark()
    let plan = Plan()
    var todo = sources
    while todo.count > 0 {
      let constraint = todo.removeLast()
      if constraint.output.mark != mark && constraint.inputsKnown(mark) {
        plan.addConstraint(constraint)
        constraint.output.mark = mark
        addConstraintsConsumingTo(constraint.output, coll: &todo)
      }
    }
    return plan
  }

  // Extract a plan for resatisfying starting from the output of the
  // given [constraints], usually a set of input constraints.
  func extractPlanFromConstraints(constraints: [Constraint]) -> Plan {
    var sources: [Constraint] = []
    for constraint in constraints {
      // if not in plan already and eligible for inclusion.
      if constraint.isInput && constraint.isSatisfied {
        sources.append(constraint)
      }
    }
    return makePlan(sources)
  }

  // Recompute the walkabout strengths and stay flags of all variables
  // downstream of the given constraint and recompute the actual
  // values of all variables whose stay flag is true. If a cycle is
  // detected, remove the given constraint and answer
  // false. Otherwise, answer true.
  // Details: Cycles are detected when a marked variable is
  // encountered downstream of the given constraint. The sender is
  // assumed to have marked the inputs of the given constraint with
  // the given mark. Thus, encountering a marked node downstream of
  // the output constraint means that there is a path from the
  // constraint's output to one of its inputs.
  func addPropagate(constraint: Constraint, mark: Int) -> Bool {
    var todo = [constraint]
    while todo.count > 0 {
      let d = todo.removeLast()
      if d.output.mark == mark {
        incrementalRemove(constraint)
        return false
      }

      d.recalculate()
      addConstraintsConsumingTo(d.output, coll: &todo)
    }

    return true
  }

  // Update the walkabout strengths and stay flags of all variables
  // downstream of the given constraint. Answer a collection of
  // unsatisfied constraints sorted in order of decreasing strength.
  func removePropagateFrom(out: Variable) -> [Constraint] {
    out.determinedBy = nil
    out.walkStrength = WEAKEST
    out.stay = true
    var unsatisfied: [Constraint] = []
    var todo = [out]
    while todo.count > 0 {
      let v = todo.removeLast()
      for constraint in v.constraints {
        if !constraint.isSatisfied {
          unsatisfied.append(constraint)
        }
      }

      let determining = v.determinedBy
      for next in v.constraints {
        if next !== determining && next.isSatisfied {
          next.recalculate()
          todo.append(next.output)
        }
      }
    }

    return unsatisfied
  }

  func addConstraintsConsumingTo(v: Variable, inout coll: [Constraint]) {
    if let determining = v.determinedBy {
      for constraint in v.constraints {
        if constraint !== determining && constraint.isSatisfied {
          coll.append(constraint)
        }
      }
    }
  }
}

var total = 0

// This is the standard DeltaBlue benchmark. A long chain of equality
// constraints is constructed with a stay constraint on one end. An
// edit constraint is then added to the opposite end and the time is
// measured for adding and removing this constraint, and extracting
// and executing a constraint satisfaction plan. There are two cases.
// In case 1, the added constraint is stronger than the stay
// constraint and values must propagate down the entire length of the
// chain. In case 2, the added constraint is weaker than the stay
// constraint so it cannot be accomodated. The cost in this case is,
// of course, very low. Typical situations lie somewhere between these
// two extremes.
func chainTest(n: Int) {
  planner = Planner()
  var prev: Variable?
  var vfirst: Variable?
  var vlast: Variable?

  // Build chain of n equality constraints.
  for i in 0...n {
    let v = Variable(name: "v", value: 0)
    if let p = prev {
      let _ = EqualityConstraint(v1: p, v2: v, strength: REQUIRED)
    }
    if i == 0 {
      vfirst = v
    }
    if i == n {
      vlast = v
    }
    prev = v
  }

  let first = vfirst!
  let last = vlast!

  let _ = StayConstraint(variable: last, strength: STRONG_DEFAULT)
  let edit = EditConstraint(variable: first, strength: PREFERRED)
  let plan = planner.extractPlanFromConstraints([edit])
  for i in 0..<100 {
    first.value = i
    plan.execute()
    total = total + last.value
  }
}

func change(v: Variable, newValue: Int) {
  let edit = EditConstraint(variable: v, strength: PREFERRED)
  let plan = planner.extractPlanFromConstraints([edit])
  for _ in 0..<10 {
    v.value = newValue
    plan.execute()
  }

  edit.destroyConstraint()
}

// This test constructs a two sets of variables related to each
// other by a simple linear transformation (scale and offset). The
// time is measured to change a variable on either side of the
// mapping and to change the scale and offset factors.
func projectionTest(n: Int) {
  planner = Planner()
  let scale = Variable(name: "scale", value: 10)
  let offset = Variable(name: "offset", value: 1000)
  var vsrc: Variable?
  var vdst: Variable?

  var dests: [Variable] = []
  for i in 0..<n {
    vsrc = Variable(name: "src", value: i)
    vdst = Variable(name: "dst", value: i)
    dests.append(vdst!)
    let _ = StayConstraint(variable: vsrc!, strength: NORMAL)
    let _ = ScaleConstraint(src: vsrc!, scale: scale, offset: offset,
        dest: vdst!, strength: REQUIRED)
  }

  let src = vsrc!
  let dst = vdst!

  change(src, newValue: 17)
  total = total + dst.value
  if dst.value != 1170 {
    print("Projection 1 failed")
  }

  change(dst, newValue: 1050)

  total = total + src.value
  if src.value != 5 {
    print("Projection 2 failed")
  }

  change(scale, newValue: 5)
  for i in 0..<n - 1 {
    total = total + dests[i].value
    if dests[i].value != i * 5 + 1000 {
      print("Projection 3 failed")
    }
  }

  change(offset, newValue: 2000)
  for i in 0..<n - 1 {
    total = total + dests[i].value
    if dests[i].value != i * 5 + 2000 {
      print("Projection 4 failed")
    }
  }
}

func runDeltaBlue() {
  //var start = System.clock
  for _ in 0..<40 {
    chainTest(100)
    projectionTest(100)
  }

  print(total)
  //System.print("elapsed: %(System.clock - start)")
}
