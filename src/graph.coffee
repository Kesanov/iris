fs    = require 'fs'

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
      @ranks[n] = 0
      for t from @graph.iter n
        if t of @nodes
          @ranks[n] = Math.min rank, @ranks[t]-1
    @ranks[0] = 0
    # ADD RANKS
    queue = new UniqueQueue Queue, ([n, @ranks[n], n] for n, _ of newnodes)
    queue.costs = @ranks
    for [n, r, _] from queue.iter()
      for t from @graph.iter n
        if n != t and (t not of @ranks or r >= @ranks[t])
          queue.insert t, r-1, t
    # ADD NODES
    for i, _ of newnodes
      @nodes[i] = [null, null]


class State

  graph: null
  input: null

  constructor: (@input) ->
    @graph = new GraphLayout()

  iter: () ->
    for transition from @input
      for n in transition.remove.nodes
        delete @graph.nodes[n]
      for e in transition.remove.edges
        delete @graph.edges[e]

      @graph.step transition.insert.nodes, transition.insert.edges
      yield @graph

int = parseInt

readCSV = (fileNodes, fileEdges) ->
  nodes = ((s.replace(/\s+/g, '') for s in line.split(',')) for line in fs.readFileSync(fileNodes, 'utf8').split('\n'))
  edges = ((s.replace(/\s+/g, '') for s in line.split(',')) for line in fs.readFileSync(fileEdges, 'utf8').split('\n'))
  [n, e] = [1, 1]
  while nodes[n++][0] != 'END' and edges[e++][0] != 'END'
    t = {remove: {nodes: [], edges: []}, insert: {nodes: {}, edges: {}}}
    while nodes[n][0] == 'remove'
      t.remove.nodes.push int(nodes[n++][1])
    while nodes[n][0] == 'insert'
      t.insert.nodes[int(nodes[n][1])] = nodes[n][2]
      n++
    while edges[e][0] == 'remove'
      t.remove.edges.push int(edges[e++][1])
    while edges[e][0] == 'insert'
      t.insert.edges[int(edges[e][1])] = [int(edges[e][2]), int(edges[e][3]), 0]
      e++
    yield t

state = new State readCSV '../data/nodes.csv', '../data/edges.csv'


for graph from state.iter()
  graph.nodes[n][0] = r for n, r of graph.ranks
  fs.writeFileSync '../data/graphlayout.json', JSON.stringify
    'edges': graph.edges
    'nodes': graph.nodes
  break

