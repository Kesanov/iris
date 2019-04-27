import * as basegl from 'basegl'
import {circle, rect, triangle} from 'basegl/display/Shape'
import * as Color from 'basegl/display/Color'
import {group} from 'basegl/display/Symbol'
import {KeyboardMouseReactor} from './EventReactor'
import {graph} from 'layoutdata'

G = 15

scene = basegl.scene
  domElement: 'scene'
  width: 2048
  height: 2048


eventReactor = new KeyboardMouseReactor scene

addNode = (n, [y, x]) ->
  r = G/6
#  name = basegl.text {str: "HELLO", scene: scene, fontFamily: 'SourceCodePro', size: 16}
  node = scene.add basegl.symbol basegl.expr -> circle(r).move(r, r)
  node.bbox.xy = [2*r, 2*r]
  node.position.xy = [G*x, G*y]
  node.addEventListener "mouseover", (e) -> console.log "OVER NODE!"
  group [node]

addEdge = ([ys, xs], [yt, xt], offset) ->
  line1 = addLine [ys,xs], [ys,xs+offset]
  line2 = addLine [yt+.3,xs+offset], [yt+.3,xt]
  line3 = addLine [ys,xs+offset], [yt+.3,xs+offset]
  line4 = addLine [yt+.3, xt], [yt, xt]
  group [line1, line2, line3, line4]

addLine = ([ys, xs], [yt, xt]) ->
  pi = if xs > xt then Math.PI else 0

  size = Math.sqrt (Math.pow G*xs-G*xt, 2) + (Math.pow G*ys-G*yt, 2)
  line = scene.add basegl.symbol basegl.expr -> rect(1.5*size, G/10)
  line.bbox.xy = [1.2*size, G/10]

  srce = scene.add basegl.symbol basegl.expr -> rect(0.8*size, G/10).fill(Color.rgb [0.8,0.3,0,.5])
  srce.bbox.xy = [.8*size, G/10]
  srce.position.xy = [0.6*size, 0]

  line = group [line, srce]
  line.rotation.z = pi + Math.atan (yt-ys) / (xt-xs)
  line = group [line]
  line.position.xy = [G*xs+G/6, G*ys+G/6]
  line


for _, pos of graph.nodes
  pos[1] += 50
for n, pos of graph.nodes
  addNode n, pos
for _, [s, t, offset] of graph.edges
  addLine graph.nodes[s], graph.nodes[t]
