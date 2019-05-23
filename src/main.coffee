import * as basegl from 'basegl'
import {circle, rect, triangle} from 'basegl/display/Shape'
import * as Color from 'basegl/display/Color'
import {group} from 'basegl/display/Symbol'
import {KeyboardMouseReactor} from './EventReactor'
import {graph} from 'layoutdata'

G = 30

addNode = (n, {y, x, rank, label}, hsl) ->
  r = G/6
#  name = basegl.tet.x {str: "HELLO", scene: scene, fontFamily: 'SourceCodePro', size: 16}
  src = addLine {y: y, x: x}, {y: y+.3, x: x}
  node = scene.add basegl.symbol basegl.expr -> circle(r).move(r, r).fill(Color.hsl hsl)
  node.bbox.xy = [2*r, 2*r]
  node.position.xy = [G*x, G*y]
  node.addEventListener "mouseover", (e) => alert "Node: id:#{n}, label: #{label}"

  group [node, src]

addEdge = (s, t, offset) ->
  line0 = addLine {y: s.y   , x: s.x}       , {y: s.y-.3, x: s.x}
  line1 = addLine {y: s.y-.3, x: s.x}       , {y: s.y-.3, x: s.x+offset}
  line2 = addLine {y: s.y-.3, x: s.x+offset}, {y: t.y+.3, x: s.x+offset}
  line3 = addLine {y: t.y+.3, x: s.x+offset}, {y: t.y+.3, x: t.x}
  group [line0, line1, line2, line3]

addLine = (s, t) ->
  pi = if s.x > t.x then Math.PI else 0

  size = 2 + 2* Math.sqrt (Math.pow G*s.x-G*t.x, 2) + (Math.pow G*s.y-G*t.y, 2)
  src = scene.add basegl.symbol basegl.expr -> rect(size, G/10)
  src.bbox.xy = [size, G/10]

  line = group [src]

  src.position.x = Math.ceil src.position.x - G*.035
  src.position.y = Math.ceil src.position.y - G*.035
  line.rotation.z = pi + Math.atan (t.y-s.y) / (t.x-s.x)
  line = group [line]
  line.position.xy = [G*s.x+G/6, G*s.y+G/6]
  line


main = () ->
#  basegl.fontManager.register 'SourceCodePro', 'fonts/SourceCodePro.ttf'
#  await basegl.fontManager.load 'SourceCodePro'

  new KeyboardMouseReactor scene

  nodes = {}
  nodes[n]=[0,0] for n, _ of graph.nodes
  for _, {s, t} of graph.edges
    nodes[s][1] += 1
    nodes[t][0] += 1
  origin = {x: graph.nodes[0].x, y: graph.nodes[0].y}
  for _, node of graph.nodes
    node.x += 30 - origin.x
    node.y  = 20 - origin.y - node.y
  for _, {s, t} of graph.edges
    if nodes[t][0] == 1
      offset = graph.nodes[t].x - graph.nodes[s].x
    else if nodes[s][1] == 2
      offset = 0
    else
      offset = 0
    addEdge graph.nodes[s], graph.nodes[t], offset
  for n, node of graph.nodes
    addNode n, node, graph.styles[node.label].hsl


scene = basegl.scene
  domElement: 'scene'
  width: 2048
  height: 2048

new KeyboardMouseReactor scene

main()