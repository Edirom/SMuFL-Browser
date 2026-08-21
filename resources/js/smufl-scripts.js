/*
 * Some Javascript functions for SMuFL-Browser
 */

/* Initialize choices plugin for the input forms */
document.querySelectorAll("select").forEach(function(e) {
    new Choices(e, {
            removeItemButton: true
        }
    );
});
