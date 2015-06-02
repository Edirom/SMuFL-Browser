/*
 * Some Javascript functions for SMuFL-Browser
 */

$.fn.facets = function ()
{
     this.selectize({
        plugins: ['remove_button'],
        hideSelected: true,
        onDropdownClose: function(e){
            var params = [];
            /* Set filters */
            $('option:selected').each(function() {
                var facet = $(this).parent().attr('name');
                var value = $(this).attr('value');
                /*console.log(facet + '=' + value);*/
                params.push(facet + '=' + encodeURI(value))
            })
            
            /* Refresh page */
            self.location='?'+params.join('&')
        }
    })
};

/* Initialize selectize plugin for the input forms */
$(document).ready(function()  {
    $("#ranges-list").facets();
    $("#glyphnames-list").facets();
    $("#classes-list").facets();
});