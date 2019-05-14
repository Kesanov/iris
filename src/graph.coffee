fs    = require 'fs'

clone = (obj) => JSON.parse JSON.stringify obj
sort  = (a,f) => a.sort (a, b) => f(a) - f(b)
last  = (arr) => arr[arr.length - 1]
uniq  = (arr) => arr[i] for i in [0..arr.length-1] when arr[i] != arr[i+1]

chain = (args) ->
  for arg from args when arg
    for a from arg
      yield a

class Stack

  stack: []

  constructor: (@stack = []) ->

  empty : ( ) => @stack.length == 0
  insert: (x) => @stack.push x
  remove: ( ) => @stack.pop()

class Queue

  frnt: []
  back: []

  constructor: (@frnt = [], @back = []) ->

  empty : ( ) => @frnt.length == 0 and @back.length == 0
  insert: (x) => @back.push x
  remove: ( ) =>
    if @frnt.length == 0
      @frnt = @back.reverse()
      @back = []
    @frnt.pop()

class UniqueQueue

  queue: null
  costs: {}
  items: {}

  constructor: (queue, costs, items) ->
    @items = {}
    @costs = costs
    @queue = new queue()
    for [name, cost, item] in items
      @insert name, cost, item
    return this

  reinsert: (name, cost, item = null) =>
    @queue.insert [name, cost]
    @items[name] = item
    @costs[name] = cost

  insert: (name, cost, item = null) =>
    @reinsert name, cost, item  if name not of @costs or cost < @costs[name]

  iter: () ->
    while not @queue.empty()
      [name, cost] = @queue.remove()
      if @costs[name] == cost
        yield [name, cost, @items[name]]


class Graph

  edges: {}
  rdges: {}

  constructor: (@edges = {}, @rdges = {}) ->

  addNode: (n) =>
    if n not of @edges
      @edges[n] = []
      @rdges[n] = []

  addEdge: (s, t) =>
    @edges[s].push t
    @rdges[t].push s

  delEdge: (s, t) =>
    @edges[s] = @edges[s].filter(x => x != t)
    @rdges[t] = @edges[t].filter(x => x != s)

  adges: (n) ->
    if n of @edges
      yield t for t in @edges[n]
    if n of @rdges
      yield t for t in @rdges[n]


class GraphLayout

  label: {}
  sourc: []
  ranks: {}
  nodes: {}
  edges: {}
  graph: null

  constructor: (@sourc = [0], @ranks = {0: 0}, @nodes = {}, @edges = {}) ->
    @graph = new Graph()

  step: (newnodes, newedges, layout = true) =>
    graph = new Graph()

    @addEdges graph, newnodes, newedges
    @rankNodes graph, newedges
    @orientEdges graph, newedges

    for i, [label] of newnodes
      @nodes[i] = [null, null]
      @label[i] = label

    @dominanceLayout() if layout

  addEdges: (graph, newnodes, newedges) =>
    for n, _ of newnodes
      graph.addNode n
      @graph.addNode n
    for i, [s, t, o] of newedges when s != t
      graph.addNode s if s not of newnodes
      graph.addNode t if t not of newnodes
      graph.addEdge s, t
      @edges[i] = [s, t, o]

  rankNodes: (graph, newedges) =>
    queue = new UniqueQueue Queue, @ranks, []
    nodes = []
    for _, [s,t] of newedges
      nodes.push(s) if s of @ranks
      nodes.push(t) if t of @ranks
    nodes = uniq(sort nodes, (n) => -@ranks[n])
    for n in nodes
      queue.reinsert n, @ranks[n]
      for [n, r, _] from queue.iter()
        for t from chain [@graph.edges[n], graph.adges n]
          if n != t and (t not of @ranks or r == @ranks[t])
            queue.insert t, r-1

  orientEdges: (graph, newedges) =>
    for e, [s,t,o] of newedges when s != t
      [s,t] = [t,s] if @ranks[s] < @ranks[t]
      @graph.addEdge s, t
      @edges[e] = [s,t,o]
    for n, _ of @ranks
      sort @graph.edges[n], (a) => @graph.rdges[a].length + 1/a
      sort @graph.rdges[n], (a) => @graph.rdges[a].length + 1/a


  dominanceLayout: () =>
    # PRELIMINARY
    [remains, xs, ys, x, y] = [[], [], [], 0, 0]
    queue = new UniqueQueue Stack, {}, ([n, 2, 2] for n in @sourc)
#    console.log @ranks, @sourc, queue.queue.stack
    for n, _ of @nodes
      remains[n] = @graph.rdges[n].length
    for [n, _, _] from queue.iter()
      @nodes[n][1] = x++
      xs.push n
      for t from @graph.edges[n]
        queue.insert t, 1 if --remains[t] == 0
    queue = new UniqueQueue Stack, {}, ([n, 2, 2] for n in @sourc.reverse())
    for n, _ of @nodes
      remains[n] = @graph.rdges[n].length
    for [n, _, _] from queue.iter()
      @nodes[n][0] = y++
#      @nodes[n][0] = y++ if @trans[n]
      ys.push n
      for t from @graph.edges[n].reverse()
        queue.insert t, 1 if --remains[t] == 0

    # COMPACTION
    [x, ns] = [0, sort (n for n, _ of @nodes), (n) => @nodes[n][1]]
    for i in [0..ns.length-2]
      @nodes[ns[i+1]][1] = if int(ns[i+1]) == @graph.edges[ns[i]][0] then x else ++x

    for n, _ of @nodes when @graph.edges[n].length == 0
      @nodes[n][0] = 1 + Math.max.apply null, (@nodes[s][0] for s in @graph.rdges[n])

    ns = sort (n for n, _ of @nodes), (n) => @nodes[n][0]
    ys = (-1 for n, _  of @nodes)
    for n in sort (n for n, _ of @nodes), (n) => @nodes[n][0]
      parentY = Math.max.apply null, (@nodes[s][0] for s in @graph.rdges[n])
      ys[@nodes[n][1]] = @nodes[n][0] = 1 + Math.max parentY, ys[@nodes[n][1]]
#
#    for n, pos of @nodes
#      pos[1] = pos[1] - pos[0]
#      pos[0] = pos[1] + 2*pos[0]

  write: () =>
    file = fs.openSync('./layoutdata.coffee', 'w')
    fs.writeSync file, "export graph =\n"
    fs.writeSync file, "  styles:\n"
    labels = uniq (l for _, l of @label).sort()
    for label, i in labels
      fs.writeSync file, "    #{label}: {hsl: [#{(1+i)/labels.length},1,.5]}\n"
    fs.writeSync file, "  nodes:\n"
    for n, [y, x] of @nodes
      fs.writeSync file, "    #{n} : {y: #{y}, x: #{x}, rank: #{@ranks[n]}, label: '#{@label[n]}'}\n"
    fs.writeSync file, "  edges:\n"
    for e, [s, t] of @edges
      fs.writeSync file, "    #{e} : {s: #{s}, t: #{t}}\n"
    fs.closeSync file

class State

  graph: null
  input: null

  constructor: (@input) ->
    @graph = new GraphLayout()

  iter: () ->
    for transition from @input
      for n in transition.remove.nodes
        delete @graph.nodes[n]
        delete @graph.ranks[n]
        delete @graph.graph.edges[n]
        delete @graph.graph.rdges[n]
      for e in transition.remove.edges
        [s, t] = @graph.edges[e]
        if s of @graph.nodes
          @graph.graph.edges[s] = @graph.graph.edges[s].filter (x) => x != t
        if t of @graph.nodes
          @graph.graph.rdges[t] = @graph.graph.rdges[t].filter (x) => x != s
        delete @graph.edges[e]

      @graph.step transition.insert.nodes, transition.insert.edges
      yield @graph

int = parseInt

readCSV = (file) ->
  nodes = ((s.replace(/\s+/g, '') for s in line.split(',')) for line in fs.readFileSync(file+'/nodes.csv', 'utf8').split('\n'))
  edges = ((s.replace(/\s+/g, '') for s in line.split(',')) for line in fs.readFileSync(file+'/edges.csv', 'utf8').split('\n'))
  [n, e] = [1, 1]
  while nodes[n++][0] != 'END' and edges[e++][0] != 'END'
    t = {remove: {nodes: [], edges: []}, insert: {nodes: {}, edges: {}}}
    while nodes[n][0] == 'remove'
      t.remove.nodes.push int(nodes[n++][1])
    while nodes[n][0] == 'insert'
      t.insert.nodes[int(nodes[n][1])] = [nodes[n][2]]
      n++
    while edges[e][0] == 'remove'
      t.remove.edges.push int(edges[e++][1])
    while edges[e][0] == 'insert'
      t.insert.edges[int(edges[e][1])] = [int(edges[e][2]), int(edges[e][3]), 0]
      e++
    yield t

state = new State readCSV '../data/ImgZen'

i=0
for graph from state.iter()
  if i++ == 0
    graph.write()
    break

