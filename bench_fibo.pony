use "ponybench"
use "collections"
use "math"

class iso BenchStdlibFibonacci is Bench
  fun name(): String => "StdLib"

  fun apply(h: BenchHelper) =>
    var n: U64 = 0
    for i in h.iter() do
      let fibo = Fibonacci
      for j in Range[U32](0,502) do
         fibo.has_next() 
         n = fibo.next()
      end
    end


class iso BenchInlineFibonacci is Bench
  fun name(): String => "Inline"

  fun apply(h: BenchHelper) =>
    var n: U64 = 0
    var n': U64 = 1
    for i in h.iter() do
      n = 0
      n' = 1
      for j in Range[U32](0,500) do
         n = n' = n + n'
      end
    end


class iso BenchLinearFibonacci is Bench
  fun name(): String => "Linear"

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


class iso BenchRecursiveFibonacci is Bench
  fun name(): String => "Recursive"

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
    bench(BenchRecursiveFibonacci)
    bench(BenchLinearFibonacci)
    bench(BenchInlineFibonacci)
    bench(BenchStdlibFibonacci)
