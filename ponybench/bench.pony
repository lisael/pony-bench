use "options"
use "time"


trait BenchList

  fun tag benchs(bench: PonyBench)
    """
    """

  fun alone(): Bool => false


trait Bench

  fun name(): String
  fun ref apply(h: BenchHelper)

class val BenchHelper
  let _runner: _BenchRunner tag
  let _bench_name: String

  new val create(runner: _BenchRunner tag, name: String val) =>
    _runner = runner
    _bench_name = name

  fun iter(): BenchSequence =>
    BenchSequence(_runner, _bench_name)

  fun log(s: String) =>
    _runner.log(s)

class BenchSequence
  let _runner: _BenchRunner tag
  let _bench_name: String
  var cycles: U64 = 2
  var count: U64 = 2
  var started: Bool = false
  var start_time: (I64, I64) = (0,0)
  var target_time: U64 =  5_000_000_000

  new create(runner: _BenchRunner tag, name: String val) =>
    _runner = runner
    _bench_name = name

  fun log(s: String) =>
    _runner.log(s)

  fun ref has_next(): Bool =>
    if not started then
      if cycles < 32 then
        var delta = get_delta()

        if delta > (target_time / 2) then
          cycles = cycles - count
          results(delta)
          return false
        end
      end

      if count > 2 then return true end

      var delta = get_delta()

      if (delta < (target_time / 100) ) or (cycles < 32) then
        cycles = cycles * 2
      else
        // log("found at " + cycles.string() + " ( " + delta.string() + " ns)")
        cycles = (cycles * target_time) / delta
        // log(cycles.string())
        started = true
      end

      count = cycles
      start_time = Time.now()
      return true
    end

    count > 0

  fun ref next(): U64 ? =>
    count = count - 1
    match count
    | 1 => results(get_delta()); 1
    | 0 => error
    else
      1
    end

  fun get_delta(): U64 =>
    var end_time = Time.now()
    match start_time
    | (0,0) => 0
    else Time.wall_to_nanos(end_time) - Time.wall_to_nanos(start_time)
    end

  fun results(delta: U64) =>
    var per_loop: U64 = delta / cycles
    log(cycles.string() + " loops. Took " +
        delta.string() + " ns => " +
        per_loop.string() + "ns per loop")
    _runner.result(BenchResult(_bench_name, cycles, delta))

class val BenchResult
  let name: String
  let loops: U64
  let duration: U64

  new val create(name': String, loops': U64, duration': U64) =>
    name = name'
    loops = loops'
    duration = duration'

  fun string(): String =>
    var per_loop: U64 = duration / loops
    name + ": " +
    loops.string() + " loops. Took " +
    duration.string() + " ns => " +
    per_loop.string() + " ns per loop"

actor _BenchRunner
  let _bench: Bench iso
  let _main: PonyBench tag
  let _name: String
  let _results: Array[BenchResult val] = Array[BenchResult val]
  var _runs: U8 = 3

  new create(bench: Bench iso, list: PonyBench) =>
    _main = list
    _name = bench.name()
    _bench = consume bench

  be apply() =>
    if _runs == 0 then
      log("End")
      _main._result(_select_result())
      return
    end
    let helper = BenchHelper(this, _bench.name()) 
    log("Run " + _runs.string())
    _bench(helper)
    _runs = _runs - 1

  be result(res: BenchResult val) =>
    _results.push(res)
    this()

  be log(msg: String) =>
    _main.log(_name + ": " + msg)

  fun _select_result(): BenchResult =>
    try _results(0) else BenchResult("", 0, 0) end

actor PonyBench
  let _env: Env
  let _results: Array[BenchResult val] = Array[BenchResult val]
  var _num_benchs: USize = 0

  new create(env: Env, benchs: BenchList tag) =>
    _env = env
    benchs.benchs(this)

  be apply(bench: Bench iso) =>
    var runner = _BenchRunner(consume bench, this)
    runner()
    _num_benchs = _num_benchs + 1

  be _result(res: BenchResult val) =>
    _results.push(res)
    log("###" + _results.size().string() + " " + _num_benchs.string())
    if _results.size() == _num_benchs then
      _print_report()
    end

  be _print_report() =>
    log("Best of 3 runs:")
    for result in _results.values() do
      log(result.string())
    end
    log("Done!")

  be log(s: String) =>
    _env.out.write(s + "\n")
