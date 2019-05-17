#!/usr/bin/env python3
import gurobipy as g
import json

class GraphLayout:

    def __init__(self):
        self.styl = [] # label: style
        self.node = {} # id: (y,x,rank,label)
        self.edge = {} # id: (s,t,offset)

    @classmethod
    def loadCoffee(cls, file):
        data = (line for line in open(file, 'r'))
        grph = cls()
        next(data)
        next(data)
        for line in data:
            if 'nodes:' in line: break
            grph.styl.append(line)
        for line in data:
            if 'edges:' in line: break
            line = line.split(':')
            [y,x,r,l] = [l.split(',')[0].split('}')[0] for l in line[2:]]
            grph.node[int(line[0])] = int(r), int(x), int(r), l
        for line in data:
            line = line.split(':')
            [s,t] = [l.split(',')[0].split('}')[0] for l in line[2:]]
            grph.edge[int(line[0])] = int(s), int(t), 0
        return grph

    def saveCoffee(self, file):
        f = open(file, 'w')
        print('export graph =', file=f)
        print('  styles:', file=f)
        for s in self.styl: print(s, file=f, end='')
        print('  nodes:', file=f)
        for k, (y,x,r,l) in self.node.items(): print(f'    {k}: {{y:{-r}, x:{x}, rank:{r}, label:{l}}}', file=f)
        print('  edges:', file=f)
        for k, (s,t,o)   in self.edge.items(): print(f'    {k}: {{s:{s}, t:{t}}}', file=f)

# exact, but slow grid layout algorithm
def main(graph):
    M = 1000
    m = g.Model()

    def abs_(val):  # |val|
        x = m.addVar(vtype=g.GRB.CONTINUOUS)
        m.addConstr(x >=  val)
        m.addConstr(x >= -val)
        return x

    def imp(name, cond, vals): # c[i] >= 0  ===>  v[i] >= 0
        v = m.addVar(vtype=g.GRB.BINARY, name=name + ' value')
        c = m.addVars(range(len(cond)), vtype=g.GRB.BINARY, name=name + ' condition')
        m.addConstrs(cond[i] <=  M*c[i] - 1 for i in range(len(cond)))
        m.addConstrs(vals[i] >= -M*v        for i in range(len(vals)))
        return sum(c.values()) + v <= len(cond)

    y, x = 0, 1
    # - add variables
    edge = m.addVars(graph.edge.keys(), lb=-100, ub=100, vtype= g.GRB.INTEGER, name="EDGE")
    node = m.addVars(graph.node.keys(),          ub=999, vtype= g.GRB.INTEGER, name="NODE")

    m.update()
    # - add constraints
    # NO CROSSING
    for e1, (s1, t1, _) in graph.edge.items():
        for e2, (s2, t2, _) in graph.edge.items():
            if graph.node[s1][y] > graph.node[s2][y] > graph.node[t1][y]:
                e1GTs2 = node[s1] + edge[e1] - node[s2]
                e1GTt2 = node[s1] + edge[e1] - node[t2]

                m.addConstr(imp(f'R {e1} {e2}', [ edge[e2],  e1GTs2], [ e1GTt2 -1]))
                m.addConstr(imp(f'L {e1} {e2}', [-edge[e2], -e1GTs2], [-e1GTt2 -1]))
    # s.x > e.x > t.x
    for e, (s, t, _) in graph.edge.items():
        tGTs = node[t] - node[s]
        tGTe = node[t] - node[s] - edge[e]

        m.addConstr(imp(f'R {e}', [ tGTs], [ edge[e],  tGTe]))
        m.addConstr(imp(f'L {e}', [-tGTs], [-edge[e], -tGTe]))

    # node[a].y > node[b].y if rank[a] < rank[b]
    # m.addConstrs(node[a,0] - 1 >= node[b, 0] for a in graph.node for b in graph.node if graph.rank[a] < graph.rank[b])
    # node[a].x != node[b].x
    for a in graph.node:
        for b in graph.node:
            if a < b and graph.node[a][y] == graph.node[b][y]:
                t = m.addVar(vtype=g.GRB.BINARY, name=f'{a}.x!={b}.x')
                m.addConstr(node[a] - node[b] >= -M*   t  +1)
                m.addConstr(node[b] - node[a] >= -M*(1-t) +1)

    # - set objective : change in node position + total edge length
    m.setObjective(
        # sum(abs(node[n] - x)       for n, (_, x, _, _) in graph.node.items() if x is not None)+
        sum(abs_(node[s] - node[t]) for s, t, _   in graph.edge.values()),
        g.GRB.MINIMIZE,
    )

    m.update()
    m.write('debug.lp')

    m.optimize()
    for n in graph.node: graph.node[n] = -graph.node[n][2], int(round(node[n].X)), graph.node[n][2], graph.node[n][3]
    for e in graph.edge: graph.edge[e] = graph.edge[e][0], graph.edge[e][1], int(round(edge[e].X))
    print(sum(graph.node[t][0] - graph.node[s][0] + abs(graph.node[s][1] - graph.node[t][1]) for (s,t,o) in graph.edge.values()))
    print(graph.node)
    print({e: edge[e].X for e in graph.edge})
    print({var.VarName: int(round(var.X)) for var in m.getVars()})

if __name__ == '__main__':
    grph = GraphLayout.loadCoffee('./layoutdata.coffee')
    main(grph)
    grph.saveCoffee('./layoutdata.coffee')