// Copyright 2006-2008 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Ported by the Dart team to Dart.

// Translated to Swift by Joao Pedrosa.

// This is a Dart implementation of the Richards benchmark from:
//
//    http://www.cl.cam.ac.uk/~mr10/Bench.html
//
// The benchmark was originally implemented in BCPL by
// Martin Richards.

import Glibc
import Sua

/**
 * Richards imulates the task dispatcher of an operating system.
 **/
class Richards {

  func run() throws {
    let scheduler = Scheduler()
    scheduler.addIdleTask(id: Richards.ID_IDLE, priority: 0, queue: nil,
        count: Richards.COUNT)

    var queue = Packet(link: nil, id: Richards.ID_WORKER,
        kind: Richards.KIND_WORK)
    queue = Packet(link: queue, id: Richards.ID_WORKER,
        kind: Richards.KIND_WORK)
    scheduler.addWorkerTask(id: Richards.ID_WORKER, priority: 1000,
        queue: queue)

    queue = Packet(link: nil, id: Richards.ID_DEVICE_A,
        kind: Richards.KIND_DEVICE)
    queue = Packet(link: queue, id: Richards.ID_DEVICE_A,
        kind: Richards.KIND_DEVICE)
    queue = Packet(link: queue, id: Richards.ID_DEVICE_A,
        kind: Richards.KIND_DEVICE)
    scheduler.addHandlerTask(id: Richards.ID_HANDLER_A, priority: 2000,
        queue: queue)

    queue = Packet(link: nil, id: Richards.ID_DEVICE_B,
        kind: Richards.KIND_DEVICE)
    queue = Packet(link: queue, id: Richards.ID_DEVICE_B,
        kind: Richards.KIND_DEVICE)
    queue = Packet(link: queue, id: Richards.ID_DEVICE_B,
        kind: Richards.KIND_DEVICE)
    scheduler.addHandlerTask(id: Richards.ID_HANDLER_B, priority: 3000,
        queue: queue)

    scheduler.addDeviceTask(id: Richards.ID_DEVICE_A, priority: 4000,
        queue: nil)

    scheduler.addDeviceTask(id: Richards.ID_DEVICE_B, priority: 5000,
        queue: nil)

    scheduler.schedule()

    if scheduler.queueCount != Richards.EXPECTED_QUEUE_COUNT ||
        scheduler.holdCount != Richards.EXPECTED_HOLD_COUNT {
      print("Error during execution: queueCount = \(scheduler.queueCount)" +
          ", holdCount = \(scheduler.holdCount).")
    }
    if Richards.EXPECTED_QUEUE_COUNT != scheduler.queueCount {
      throw SchedulerError.WrongQueueCount
    }
    if Richards.EXPECTED_HOLD_COUNT != scheduler.holdCount {
      throw SchedulerError.WrongHoldCount
    }
  }

  static let DATA_SIZE = 4
  static let COUNT = 1000

  /**
   * These two constants specify how many times a packet is queued and
   * how many times a task is put on hold in a correct run of richards.
   * They don't have any meaning a such but are characteristic of a
   * correct run so if the actual queue or hold count is different from
   * the expected there must be a bug in the implementation.
   **/
  static let EXPECTED_QUEUE_COUNT = 2322
  static let EXPECTED_HOLD_COUNT = 928

  static let ID_IDLE = 0
  static let ID_WORKER = 1
  static let ID_HANDLER_A = 2
  static let ID_HANDLER_B = 3
  static let ID_DEVICE_A = 4
  static let ID_DEVICE_B = 5
  static let NUMBER_OF_IDS = 6

  static let KIND_DEVICE = 0
  static let KIND_WORK = 1
}


/**
 * A scheduler can be used to schedule a set of tasks based on their relative
 * priorities.  Scheduling is done by maintaining a list of task control blocks
 * which holds tasks and the data queue they are processing.
 */
class Scheduler {

  var queueCount = 0
  var holdCount = 0
  var currentTcb: TaskControlBlock?
  var currentId = 0
  var list: TaskControlBlock?
  var blocks = [TaskControlBlock?](repeating: nil,
      count: Richards.NUMBER_OF_IDS)

  /// Add an idle task to this scheduler.
  func addIdleTask(id: Int, priority: Int, queue: Packet?, count: Int) {
    addRunningTask(id: id, priority: priority, queue: queue,
        task: IdleTask(scheduler: self, v1: 1, count: count))
  }

  /// Add a work task to this scheduler.
  func addWorkerTask(id: Int, priority: Int, queue: Packet) {
    addTask(id: id, priority: priority, queue: queue,
            task: WorkerTask(scheduler: self, v1: Richards.ID_HANDLER_A, v2: 0))
  }

  /// Add a handler task to this scheduler.
  func addHandlerTask(id: Int, priority: Int, queue: Packet) {
    addTask(id: id, priority: priority, queue: queue,
        task: HandlerTask(scheduler: self))
  }

  /// Add a handler task to this scheduler.
  func addDeviceTask(id: Int, priority: Int, queue: Packet?) {
    addTask(id: id, priority: priority, queue: queue,
        task: DeviceTask(scheduler: self))
  }

  /// Add the specified task and mark it as running.
  func addRunningTask(id: Int, priority: Int, queue: Packet?, task: Task) {
    addTask(id: id, priority: priority, queue: queue, task: task)
    currentTcb!.setRunning()
  }

  /// Add the specified task to this scheduler.
  func addTask(id: Int, priority: Int, queue: Packet?, task: Task) {
    currentTcb = TaskControlBlock(link: list, id: id, priority: priority,
        queue: queue, task: task)
    list = currentTcb
    blocks[id] = currentTcb
  }

  /// Execute the tasks managed by this scheduler.
  func schedule() {
    currentTcb = list
    while currentTcb != nil {
      if currentTcb!.isHeldOrSuspended() {
        currentTcb = currentTcb!.link
      } else {
        currentId = currentTcb!.id
        currentTcb = currentTcb!.run()
      }
    }
  }

  /// Release a task that is currently blocked and return the next block to run.
  func release(id: Int) -> TaskControlBlock? {
    guard let tcb = blocks[id] else { return nil }
    tcb.markAsNotHeld()
    if tcb.priority > currentTcb!.priority {
      return tcb
    }
    return currentTcb
  }

  /**
   * Block the currently executing task and return the next task control block
   * to run.  The blocked task will not be made runnable until it is explicitly
   * released, even if new work is added to it.
   */
  func holdCurrent() -> TaskControlBlock? {
    holdCount += 1
    currentTcb!.markAsHeld()
    return currentTcb!.link
  }

  /**
   * Suspend the currently executing task and return the next task
   * control block to run.
   * If new work is added to the suspended task it will be made runnable.
   */
  func suspendCurrent() -> TaskControlBlock {
    currentTcb!.markAsSuspended()
    return currentTcb!
  }

  /**
   * Add the specified packet to the end of the worklist used by the task
   * associated with the packet and make the task runnable if it is currently
   * suspended.
   */
  func queue(packet: Packet) -> TaskControlBlock? {
    guard let t = blocks[packet.id] else { return nil }
    queueCount += 1
    packet.link = nil
    packet.id = currentId
    return t.checkPriorityAdd(task: currentTcb!, packet: packet)
  }

}


/**
 * A task control block manages a task and the queue of work packages associated
 * with it.
 */
class TaskControlBlock: CustomStringConvertible {

  var link: TaskControlBlock?
  var id = 0       // The id of this block.
  var priority = 0 // The priority of this block.
  var queue: Packet? // The queue of packages to be processed by the task.
  var task: Task?
  var state = 0

  init(link: TaskControlBlock?, id: Int, priority: Int, queue: Packet?,
      task: Task) {
    self.link = link
    self.id = id
    self.priority = priority
    self.queue = queue
    self.task = task
    state = queue == nil ? TaskControlBlock.STATE_SUSPENDED :
        TaskControlBlock.STATE_SUSPENDED_RUNNABLE
  }

  /// The task is running and is currently scheduled.
  static let STATE_RUNNING = 0

  /// The task has packets left to process.
  static let STATE_RUNNABLE = 1

  /**
   * The task is not currently running. The task is not blocked as such and may
   * be started by the scheduler.
   */
  static let STATE_SUSPENDED = 2

  /// The task is blocked and cannot be run until it is explicitly released.
  static let STATE_HELD = 4

  static let STATE_SUSPENDED_RUNNABLE = STATE_SUSPENDED | STATE_RUNNABLE
  static let STATE_NOT_HELD = ~STATE_HELD

  func setRunning() {
    state = TaskControlBlock.STATE_RUNNING
  }

  func markAsNotHeld() {
    state = state & TaskControlBlock.STATE_NOT_HELD
  }

  func markAsHeld() {
    state = state | TaskControlBlock.STATE_HELD
  }

  func isHeldOrSuspended() -> Bool {
    return (state & TaskControlBlock.STATE_HELD) != 0 ||
        (state == TaskControlBlock.STATE_SUSPENDED)
  }

  func markAsSuspended() {
    state = state | TaskControlBlock.STATE_SUSPENDED
  }

  func markAsRunnable() {
    state = state | TaskControlBlock.STATE_RUNNABLE
  }

  /// Runs this task, if it is ready to be run, and returns the next task to run.
  func run() -> TaskControlBlock? {
    var packet: Packet?
    if state == TaskControlBlock.STATE_SUSPENDED_RUNNABLE {
      packet = queue
      queue = packet!.link
      state = queue == nil ? TaskControlBlock.STATE_RUNNING :
          TaskControlBlock.STATE_RUNNABLE
    }
    return task!.run(packet: packet)
  }

  /**
   * Adds a packet to the worklist of this block's task, marks this as
   * runnable if necessary, and returns the next runnable object to run
   * (the one with the highest priority).
   */
  func checkPriorityAdd(task: TaskControlBlock, packet: Packet)
      -> TaskControlBlock {
    if queue == nil {
      queue = packet
      markAsRunnable()
      if priority > task.priority {
        return self
      }
    } else {
      queue = packet.addTo(queue: queue)
    }
    return task
  }

  var description: String { return "tcb { \(task)@\(state) }" }

}

/**
 *  Abstract task that manipulates work packets.
 */
class Task {

  let scheduler: Scheduler // The scheduler that manages this task.

  init(scheduler: Scheduler) {
    self.scheduler = scheduler
  }

  // Override me.
  func run(packet: Packet?) -> TaskControlBlock? { return nil }

}

/**
 * An idle task doesn't do any work itself but cycles control between the two
 * device tasks.
 */
class IdleTask: Task, CustomStringConvertible {

  var v1 = 0    // A seed value that controls how the device tasks are scheduled.
  var count = 0 // The number of times this task should be scheduled.

  init(scheduler: Scheduler, v1: Int, count: Int) {
    self.v1 = v1
    self.count = count
    super.init(scheduler: scheduler)
  }

  override func run(packet: Packet?) -> TaskControlBlock? {
    count -= 1
    if count == 0 {
      return scheduler.holdCurrent()
    }
    if (v1 & 1) == 0 {
      v1 = v1 >> 1
      return scheduler.release(id: Richards.ID_DEVICE_A)
    }
    v1 = (v1 >> 1) ^ 0xD008
    return scheduler.release(id: Richards.ID_DEVICE_B)
  }

  var description: String { return "IdleTask" }

}


/**
 * A task that suspends itself after each time it has been run to simulate
 * waiting for data from an external device.
 */
class DeviceTask: Task, CustomStringConvertible {

  var v1: Packet?

  override func run(packet: Packet?) -> TaskControlBlock? {
    if packet == nil {
      guard let v = v1 else { return scheduler.suspendCurrent() }
      v1 = nil
      return scheduler.queue(packet: v)
    }
    v1 = packet
    return scheduler.holdCurrent()
  }

  var description: String { return "DeviceTask" }

}


/**
 * A task that manipulates work packets.
 */
class WorkerTask: Task, CustomStringConvertible {

  var v1 = 0 // A seed used to specify how work packets are manipulated.
  var v2 = 0 // Another seed used to specify how work packets are manipulated.

  init(scheduler: Scheduler, v1: Int, v2: Int) {
    self.v1 = v1
    self.v2 = v2
    super.init(scheduler: scheduler)
  }

  override func run(packet: Packet?) -> TaskControlBlock? {
    guard let packet = packet else {
      return scheduler.suspendCurrent()
    }
    if v1 == Richards.ID_HANDLER_A {
      v1 = Richards.ID_HANDLER_B
    } else {
      v1 = Richards.ID_HANDLER_A
    }
    packet.id = v1
    packet.a1 = 0
    for i in 0..<Richards.DATA_SIZE {
      v2 += 1
      if v2 > 26 {
        v2 = 1
      }
      packet.a2[i] = v2
    }
    return scheduler.queue(packet: packet)
  }

  var description: String { return "WorkerTask" }

}


/**
 * A task that manipulates work packets and then suspends itself.
 */
class HandlerTask: Task, CustomStringConvertible {

  var v1: Packet?
  var v2: Packet?

  override func run(packet: Packet?) -> TaskControlBlock? {
    if let packet = packet {
      if packet.kind == Richards.KIND_WORK {
        v1 = packet.addTo(queue: v1)
      } else {
        v2 = packet.addTo(queue: v2)
      }
    }
    if let v1 = v1 {
      let count = v1.a1
      if count < Richards.DATA_SIZE {
        if let v2 = v2 {
          let v = v2
          self.v2 = v2.link
          v.a1 = v1.a2[count]
          v1.a1 = count + 1
          return scheduler.queue(packet: v)
        }
      } else {
        let v = v1
        self.v1 = v1.link
        return scheduler.queue(packet: v)
      }
    }
    return scheduler.suspendCurrent()
  }

  var description: String { return "HandlerTask" }

}


/**
 * A simple package of data that is manipulated by the tasks.  The exact layout
 * of the payload data carried by a packet is not importaint, and neither is the
 * nature of the work performed on packets by the tasks.
 * Besides carrying data, packets form linked lists and are hence used both as
 * data and worklists.
 */
class Packet: CustomStringConvertible {

  var link: Packet? // The tail of the linked list of packets.
  var id = 0      // An ID for this packet.
  var kind = 0    // The type of this packet.
  var a1 = 0

  var a2 = [Int](repeating: 0, count: Richards.DATA_SIZE)

  init(link: Packet?, id: Int, kind: Int) {
    self.link = link
    self.id = id
    self.kind = kind
  }

  /// Add this packet to the end of a worklist, and return the worklist.
  func addTo(queue: Packet?) -> Packet {
    link = nil
    guard let q = queue else { return self }
    var next = q
    var peek = next.link
    while peek != nil {
      next = peek!
      peek = next.link
    }
    next.link = self
    return q
  }

  var description: String { return "Packet" }

}

enum SchedulerError: ErrorProtocol {
  case WrongQueueCount
  case WrongHoldCount
}

let sw = Stopwatch()
sw.start()
let o = Richards()
try o.run()
print("Elapsed: \(sw.millis)")
