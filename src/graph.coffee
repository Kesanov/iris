class Queue

  frnt: []
  back: []

  empty: ( ) =>
    @frnt.length == 0 and @back.length == 0
  insert: (x) =>
    @back.push x
  remove: ( ) =>
    if @frnt.length == 0
      @frnt = @back.reverse()
      @back = []
    @frnt.pop()

class UniqueQueue

  queue: null
  costs: {}
  items: {}

  constructor: (queue, items) ->
    @queue  = new queue()
    for [name, cost, item] in items
      @insert name, cost, item

  insert: (name, cost, item) => if name not of @costs or cost < @costs[name]
    @queue.insert [name, cost]
    @costs[name] = cost
    @items[name] = item

  iter: ( ) ->
    while not @queue.empty()
      [name, cost] = @queue.remove()
      if @costs[name] == cost
        yield [name, cost, @items[name]]


class Graph

  edges: {}
  rdges: {}

  addEdge: (s, t) =>
    if s not of @edges then @edges[s] = []
    if t not of @rdges then @rdges[t] = []
    @edges[s].push t
    @rdges[t].push s

  iter: (n) ->
    if n of @edges
      yield t for t in @edges[n]
    if n of @rdges
      yield t for t in @rdges[n]


class GraphLayout

  ranks: {}
  nodes: {}
  edges: {}
  graph: null

  constructor: (  ) ->
    @graph = new Graph()

  step: (newnodes, newedges) =>
    # ADD EDGES
    for i, e of newedges
      @graph.addEdge e[0], e[1]
      @edges[i] = e
    # INIT RANKS
    for n, _ of newnodes
      for t from @graph.iter n
        if t of @nodes
          rank = if n of @ranks then @ranks[n] else 0
          @ranks[n] = Math.min rank, @ranks[t]-1
    @ranks[0] = 0
    # ADD RANKS
    queue = new UniqueQueue Queue, ([n, @ranks[n], n] for n, _ of newnodes when n of @ranks)
    queue.costs = @ranks
    for [n, r, _] from queue.iter()
      for t from @graph.iter n
        if t not of @ranks or r >= @ranks[t]
          queue.insert t, r-1, t
    # ADD NODES
    for i, _ of newnodes
      @nodes[i] = null

g = new GraphLayout()

