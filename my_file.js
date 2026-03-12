let new_viewer = document.createElement("div");
let big = document.getElementById("outerContainer");
new_viewer = document.getElementById("viewerContainer");

setTimeout(() => {
    big.replaceWith(new_viewer);
    // new_viewer = document.getElementById("viewerContainer");
    // const old_style = new_viewer.getAttribute("style");
    // console.log(old_style);
    // new_viewer.setAttribute("style", old_style.replace(";", "/4;"));
});