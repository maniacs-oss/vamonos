var myviz, tut;

$(function () {
    myviz = new Vamonos.Visualizer({
        widgets: [
            new Vamonos.Widget.Array({
                container: "array",
                defaultInput: [6, 3, 1, 4, 1, 5, 9],
                ignoreIndexZero: false,
                varName: "A",
                cssRules: [
                    ["<", "i", "shaded"]
                ],
                showIndices: ["i", "m", "j"],
                showLabel: false
            }),

            new Vamonos.Widget.VarName({
                container: "a-var",
                varName: "A",
                inputVar: true,
                watchable: false
            }),

            new Vamonos.Widget.Pseudocode({
                container: "pseudocode",
                breakpoints: "all"
            }),

            new Vamonos.Widget.Controls("controls"),

            tut = new Vamonos.Widget.QTipTutorial([
                {
                    target: $("table.array"),
                    dir: "sw",
                    tooltip: "Here is the array that will be used as input to this algorithm. "
                            + "But since the visualization is in <b>edit</b> mode, you can "
                            + "change the array by clicking on it and typing new values.",
                },
                {
                    target: $("table.array"),
                    dir: "ne",
                    tooltip: "You can easily add more elements to the array, by pressing "
                            + "the right-arrow or the tab key while in the last cell.",
                },
                {
                    target: $("table.array"),
                    dir: "ne",
                    tooltip: "You can remove elements from the array (using the delete or backspace "
                            + "keys), too, but only from the end of the array.",
                },
                {
                    target: $("#pseudocode"),
                    dir: "w",
                    tooltip: "In edit mode, you can also toggle breakpoints.",
                },
                {
                    target: $(".controls-buttons"),
                    dir: "w",
                    tooltip: "When you're happy with the input and breakpoints, "
                            + "press the <b>run</b> button to execute the algorithm.",
                },
                {
                    target: $("#controls"),
                    dir: "e",
                    tooltip: "The visualization should now be in <b>playback</b> mode. Use these "
                            + "controls to step through the algorithm.",
                },
                {
                    target: $("#pseudocode"),
                    dir: "e",
                    tooltip: "The gray line is the one that has just executed, and "
                            + "the yellow line is the one about to execute.",
                },
                {
                    target: $("#array"),
                    dir: "e",
                    tooltip: "When you step forward through the frames, "
                            + "changes to the array are highlighted.",
                },
                {
                    target: $(".controls-buttons"),
                    dir: "w",
                    tooltip: "The <b>stop</b> button will take you back to editing mode.",
                },
                {
                    target: $("#array"),
                    tooltip: "What happens when you put non-numeric data in the array?",
                    dir: "s",
                },
                {
                    target: $("#array"),
                    dir: "s",
                    tooltip: "What happens when you put <b>infinity</b> in the array?",
                },
                {
                    target: $("#pseudocode"),
                    dir: "e",
                    tooltip: "This concludes your quick introduction to <b>Vamonos</b>! Enjoy!",
                }
                
            ])
        ],

        algorithm: function (_) {
            with (this) {
                for (_(1), i = 0; i < A.length-1; _(1), i++) {
    _(2);           m = i;
                    for (_(3), j = i+1; j < A.length; _(3), j++) {
    _(4);               if (A[j] < A[m]) {
    _(5);                   m = j
                        }
                    }
                    j = null;
    _(6);           var tmp = A[i];
                    A[i] = A[m];
                    A[m] = tmp;
                    m = null;
                }
                i = null;
            }
        },
    });

});
