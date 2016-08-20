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

  new val create(runner: _BenchRunner tag) =>
    _runner = runner

  fun iter(): BenchSequence =>
    BenchSequence(_runner)

  fun log(s: String) =>
    _runner.log(s)

class BenchSequence
  let _runner: _BenchRunner tag
  var cycles: U64 = 2
  var count: U64 = 2
  var started: Bool = false
  var start_time: (I64, I64) = (0,0)
  var target_time: U64 =  5_000_000_000

  new create(runner: _BenchRunner tag) =>
    _runner = runner

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

actor _BenchRunner
  let _bench: Bench iso
  let _env: Env
  let _name: String

  new create(bench: Bench iso, env: Env) =>
    _env = env
    _name = bench.name()
    _bench = consume bench

  be apply() =>
    let helper = BenchHelper(this) 
    log("Starting bench")
    _bench(helper)
    //log("Finnished bench: " + _bench.name())

  be log(s: String) =>
    _env.out.write(_name + ":" + s + "\n")

actor PonyBench
  let _env: Env

  new create(env: Env, benchs: BenchList tag) =>
    _env = env
    benchs.benchs(this)

  be apply(bench: Bench iso) =>
    var runner = _BenchRunner(consume bench, _env)
    runner()

  be log(s: String) =>
    _env.out.write(s + "\n")


