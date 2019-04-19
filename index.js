(function () {
    window.addEventListener("message", function (evt) {
        if (evt.data.data) {
            d = JSON.parse(evt.data.data);
            document.getElementById("vis").textContent = d.type + " " + d.radius
        }
    });
}());
