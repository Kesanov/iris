module.exports = function(type) {
    if (type.constructor == "Shape") {
        return [{name: "shape", path: "index.html"}];
    } else {
        return [];
    }
}
