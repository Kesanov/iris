#!/usr/bin/env python3
import gurobipy as g
import json

class GraphLayout:

    def __init__(self):
        self.node = {} # id: (y,x)
        self.edge = {} # id: (s,t,offset)

    @classmethod
    def loadJson(cls, file):
        data = json.loads(open(file, 'r').read())
        grph = cls()
        grph.node = {int(k): tuple(v) for k,v in data['nodes'].items()}
        grph.edge = {int(k): tuple(v) for k,v in data['edges'].items()}
        return grph

    def saveCoffee(self, file):
        f = open(file, 'w')
        print('export graph =', file=f)
        print('  nodes:', file=f)
        for k, v in self.node.items(): print(f'    {k}: {list(v)}', file=f)
        print('  edges:', file=f)
        for k, v in self.edge.items(): print(f'    {k}: {list(v)}', file=f)

# exact, but slow grid layout algorithm
def main(graph):
    M = 1000
    m = g.Model()

    def abs(val):  # |val|
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
        sum(abs(node[n] - x)       for n, (_, x) in graph.node.items() if x is not None)+
        sum(abs(node[s] - node[t]) for s, t, _   in graph.edge.values()),
        g.GRB.MINIMIZE,
    )

    m.update()
    m.write('debug.lp')

    m.optimize()

    for n in graph.node: graph.node[n] = graph.node[n][y], int(round(node[n].X))
    for e in graph.edge: graph.edge[e] = graph.edge[e][0], graph.edge[e][1], int(round(edge[e].X))
    print(graph.node)
    print({e: edge[e].X for e in graph.edge})
    print({var.VarName: int(round(var.X)) for var in m.getVars()})

if __name__ == '__main__':
    grph = GraphLayout.loadJson('../data/graphlayout.json')
    main(grph)
    grph.saveCoffee('./layoutData.coffee')