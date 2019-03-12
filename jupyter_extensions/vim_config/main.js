define([
    'base/js/namespace',
    'base/js/events'
    ], function(Jupyter, events) {
        function load_ipython_extension() {
            // events.on("edit_mode.Cell", function () {
            events.on("edit_mode.Notebook", function () {
                CodeMirror.Vim.map("jk", "<Esc>", "insert"); // Map jk to <Esc>
            });
        }

        return {
            load_ipython_extension: load_ipython_extension
        };
    });
