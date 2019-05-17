## YOU NEED

1. npm
2. nodejs
3. python, gurobi
4. coffeescript

## RUN HEURISTIC
```
cd src
node --require coffeescript/register heuristic.coffee
```
the input folder name is hardcoded in the `heuristic.coffee` file on line: 266

`state = new State readCSV '../data/Bool/and'`

## RUN ILP

first run heuristic (this will create `src/layoutdata.coffee`)
```
cd src
python ILP.py
```

## RUN VISUALIZATION
```
 npm install
 npm start
```

Examples of generated images:

[Dominance Layout Nat/27f](data/Nat/27f/DOM.JPG)

[ILP Nat/27f](data/Nat/27f/ILP.JPG)

[Dominance Layout AST](data/AST/dom.JPG)

[ILP AST](data/AST/ILP.JPG)