#!/usr/bin/env python3
import gurobipy as g
import json

class GraphLayout:

    def __init__(self):
        self.rank = {}
        self.node = {} # id: (y,x)
        self.edge = {} # id: (s,t,offset)

    @classmethod
    def loadJson(cls, file):
        data = json.loads(open(file, 'r').read())
        grph = cls()
        grph.rank = {int(k):       v  for k,v in data['ranks'].items()}
        grph.node = {int(k):       v  for k,v in data['nodes'].items()}
        grph.edge = {int(k): tuple(v) for k,v in data['edges'].items()}
        return grph

    def saveCoffee(self, file):
        f = open(file, 'w')
        print('export graph =', file=f)
        print('  ranks:', file=f)
        for k, v in self.rank.items(): print(f'    {k}: {     v }', file=f)
        print('  nodes:', file=f)
        for k, v in self.node.items(): print(f'    {k}: {list(v)}', file=f)
        print('  edges:', file=f)
        for k, v in self.edge.items(): print(f'    {k}: {list(v)}', file=f)

# exact, but slow grid layout algorithm
def main(graph):
    m = g.Model()

    def abs(val):  # |val|
        x = m.addVar(vtype=g.GRB.CONTINUOUS)
        m.addConstr(x >=  val)
        m.addConstr(x >= -val)
        return x

    def imp(name, cond, vals): # c[i] >= 0  ===>  v[i] >= 0
        v = m.addVar(vtype=g.GRB.BINARY, name=name + ' value')
        c = m.addVars(range(len(cond)), vtype=g.GRB.BINARY, name=name + ' condition')
        m.addConstrs(cond[i] <=  1000*c[i] - 1 for i in range(len(cond)))
        m.addConstrs(vals[i] >= -1000*v        for i in range(len(vals)))
        return sum(c.values()) + v <= len(cond)

    y, x = 0, 1
    # - add variables
    edge = m.addVars(graph.edge.keys(),                 lb=-100, ub=100, vtype= g.GRB.INTEGER, name="EDGE")
    node = m.addVars([(n,i) for n in graph.node for i in [y,x]], ub=999, vtype= g.GRB.INTEGER, name="NODE")

    # - add constraints
    # NO CROSSING
    for e1, (s1, t1, _) in graph.edge.items():
        for e2, (s2, t2, _) in graph.edge.items():
            crossY = [node[t1,y] - node[s2,y] -1, node[t2,y] - node[t1,y] -1]
            t1LTe2 = node[s2,x] + edge[e2] - 1 - node[t1,x]

            m.addConstr(imp(f'R {e1} {e2}', crossY + [ edge[e1]], [ t1LTe2]))
            m.addConstr(imp(f'L {e1} {e2}', crossY + [-edge[e1]], [-t1LTe2]))
    # s.x > e.x > t.x
    for e, (s, t, _) in graph.edge.items():
        sLTt = node[t,x] - node[s,x]
        eLTt = node[t,x] - node[s,x] - edge[e]

        m.addConstr(imp(f'R {e}', [ sLTt], [ edge[e],  eLTt]))
        m.addConstr(imp(f'L {e}', [-sLTt], [-edge[e], -eLTt]))

    # node[a].y > node[b].y if rank[a] < rank[b]
    m.addConstrs(node[a,0] - 1 >= node[b, 0] for a in graph.node for b in graph.node if graph.rank[a] < graph.rank[b])
    # node[a].yx != node[b].yx
    m.addConstrs(imp(f'{a}.xy != {b}.xy', [node[a,x] - node[b,x], node[b,x] - node[a,x]], [node[a,y] - 1 - node[b,y]])
                 for a in graph.node for b in graph.node if a > b and graph.rank[a] == graph.rank[b])

    # - set objective : change in node position + total edge length
    m.setObjective(
        sum(abs(node[n,y] -      yx[y]) + abs(node[n, x] -      yx[x]) for n, yx   in graph.node.items() if yx is not None)+
        sum(abs(node[s,y] - node[t, y]) + abs(node[s, x] - node[t, x]) for s, t, _ in graph.edge.values()),
        g.GRB.MINIMIZE,
    )

    m.update()
    m.write('debug.lp')

    m.optimize()

    for n in graph.node: graph.node[n] = int(round(node[n,y].X)), int(round(node[n,x].X))
    for e in graph.edge: graph.edge[e] = graph.edge[e][0], graph.edge[e][1], int(round(edge[e].X))
    print({n: (node[n,y].X, node[n,x].X) for n in graph.node})
    print({e: edge[e].X                  for e in graph.edge})
    print({var.VarName: int(round(var.X)) for var in m.getVars()})

if __name__ == '__main__':
    grph = GraphLayout.loadJson('../data/graphlayout.json')
    main(grph)
    grph.saveCoffee('./layoutData.coffee')