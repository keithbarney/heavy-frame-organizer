// Generated by CoffeeScript 2.7.0
(function() {
  document.getElementById("apply").addEventListener("click", function() {
    var horizontalSpacing, ref, ref1, verticalSpacing;
    horizontalSpacing = parseInt((ref = document.getElementById("horizontalSpacing")) != null ? ref.value : void 0, 10) || 0;
    verticalSpacing = parseInt((ref1 = document.getElementById("verticalSpacing")) != null ? ref1.value : void 0, 10) || 0;
    console.log("📤 Sending to Figma:", {horizontalSpacing, verticalSpacing});
    return parent.postMessage({
      pluginMessage: {
        type: "apply-spacing",
        horizontalSpacing: horizontalSpacing,
        verticalSpacing: verticalSpacing
      }
    }, "*");
  });

}).call(this);
