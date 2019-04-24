import * as basegl from 'basegl'
import {circle, rect, plane} from 'basegl/display/Shape'
import * as Color from 'basegl/display/Color'
import {group} from 'basegl/display/Symbol'
import {KeyboardMouseReactor} from 'basegl/navigation/EventReactor'
import {graph} from 'layoutData'

G = 30

scene = basegl.scene
  domElement: 'scene'
  width: 2048
  height: 2048

new KeyboardMouseReactor scene

addNode = ([y, x]) ->
  r = G/6
  node = scene.add basegl.symbol basegl.expr -> circle(r).move(r, r)
  node.bbox.xy = [2*r, 2*r]
  node.position.xy = [G*x, G*y]
  node.addEventListener "mouseover", (e) -> console.log "OVER NODE!"

addEdge = ([ys, xs], [yt, xt], offset) ->
  line1 = addLine [ys,xs], [ys,xs+offset]
  line2 = addLine [yt+.5,xs+offset], [yt+.5,xt]
  line3 = addLine [ys,xs+offset], [yt+.5,xs+offset]
  line4 = addLine [yt+.5, xt], [yt, xt]
  group [line1, line2, line3, line4]

addLine = ([ys, xs], [yt, xt]) ->
  [ys, xs, yt, xt] = [yt, xt, ys, xs] if xs > xt

  size = Math.sqrt (Math.pow G*xs-G*xt, 2) + (Math.pow G*ys-G*yt, 2)
  line = scene.add basegl.symbol basegl.expr -> rect(2*size, G/12)
  line.bbox.xy = [2*size, G/12]
  line.rotation.z = Math.atan (yt-ys) / (xt-xs)

  line = group [line]
  line.position.xy = [G*xs+G/6, G*ys+G/6]
  line

for _, pos of graph.nodes
  pos[0] += 10
  pos[1] += 20
for _, pos of graph.nodes
  addNode pos
for _, [s, t, offset] of graph.edges
  [s, t] = [t, s] if graph.nodes[s][0] < graph.nodes[t][0]
  addEdge graph.nodes[s], graph.nodes[t], offset