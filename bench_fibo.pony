use "ponybench"
use "collections"

class iso BenchInlineFibonacci is Bench
  fun name(): String => "Inline"

  fun apply(h: BenchHelper) =>
    var n: U64 = 0
    var n': U64 = 1
    for i in h.iter() do
      n = 0
      n' = 1
      for j in Range[U32](0,200) do
         n = n' = n + n'
      end
    end
    /*h.log(n.string())*/


class iso BenchLinearFibonacci is Bench
  fun name(): String => "BenchLinear"

  fun linear_fib(order: U32): U64 =>
    var n: U64 = 0
    var n': U64 = 1
    n = 0
    n' = 1
    for j in Range[U32](0,order) do
       n = n' = n + n'
    end
    n

  fun apply(h: BenchHelper) =>
    var n: U64 = 0
    for i in h.iter() do
      n = linear_fib(200)
    end
    /*h.log(n.string())*/


class iso BenchRecursiveFibonacci is Bench
  fun name(): String => "BenchRecursive"

  fun recursive_fib(order: U32): U64 =>
    match order
    | 0 => 0
    | 1 => 1
    else
      recursive_fib(order - 1) + recursive_fib(order - 2)
    end

  fun apply(h: BenchHelper) =>
    var n: U64 = 0
    for i in h.iter() do
      n = recursive_fib(40)
    end
    h.log(n.string())


actor Main is BenchList
  
  new create(env: Env) =>
    PonyBench(env, this)

  fun tag benchs(bench: PonyBench) =>
    bench(BenchInlineFibonacci)
    bench(BenchLinearFibonacci)
    //bench(BenchRecursiveFibonacci)
