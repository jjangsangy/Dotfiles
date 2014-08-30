// we want strict javascript that fails
// on ambiguous syntax
"using strict";

// to prevent timeout
requirejs.config({
    waitSeconds: 60
});

$([IPython.events]).on('app_initialized.NotebookApp', function(){
    require(['nbextensions/livereveal/main'], function(livereveal) {
       // livereveal.parameters('theme', 'transition', 'fontsize', static_prefix);
       //   * theme can be: simple, sky, beige, serif, solarized
       //   (you will need aditional css for default, night, moon themes).
       //   * transition can be: linear, zoom, fade, none
       livereveal.parameters('solarized', 'fade');
       console.log('Live reveal extension loaded correctly');
    });
/**  Use path to js file relative to /static/ dir without leading slash, or
*  js extension.
*  Link directly to file is js extension.
*
*  first argument of require is a **list** that can contains several modules if needed.
**/

// require(['custom/foo/bar'])

/**
*  Link to entrypoint if extension is a folder.
*  to be consistent with commonjs module, the entrypoint is main.js
*  here youcan also trigger a custom function on load that will do extra
*  action with the module if needed
**/

// require(['custom/foobar/main'],function(slidemode){
//     // do stuff
// })

// zenmode example
/* require(['custom/styling/zenmode/main'],function(zenmode){
*
*   // You can use other images as a background, just check the
*   // zenmode/images folder or put there your own background...
*   // Don't forget to modify properly the the line below:
*
*   zenmode.background('images/back12.jpg');
*
*   // or if you want an IPython logo you can use:
*
*   zenmode.background('images/ipynblogo1.png');
*
*   console.log('Zenmode extension loaded correctly')
*
* })
*/

// software carpentry tags example.
/*  require(['custom/testing/swc/main'],function(m){
*
*       // param1 : Name of the preset in the dropdown selector
*       // param2 : namespace to use in metadata
*       // param3 : list of tags name to use both in UI in front of checkboxes and in metadata
*
*       m.new_tag_set('Software Carpentry Tags', 'swc' ,['instructor','learner','exercise'])
*
*       console.log('Sofware carpentry tags extension loaded corectly')
*  })
*/

/*
* all exentensions from IPython-notebook-extensions, uncomment to activate
*/

// PUBLISHING
//   require(['custom/publishing/gist_it'])
//   require(['custom/publishing/printviewmenu_button'])
   require(['custom/publishing/nbviewer_theme/main'])
   require(['custom/publishing/nbconvert_button'])
   require(['custom/publishing/printview_button'])

// SLIDEMODE
    require(['custom/slidemode/main'])

// STYLING

// TESTING
//    require(['custom/testing/history/history'])
//    require(['custom/testing/swc/main'],function(m){
//        m.new_tag_set('Software Carpentry Tags', 'swc' ,['instructor','learner','exercise'])
//        console.log('Sofware carpentry tags extension loaded corectly')
//    })
//    require(['custom/testing/cellstate'])

// USABILITY
    require(['custom/usability/aspell/ipy-aspell']) // external python depency: python-aspell
    require(['custom/usability/dragdrop/drag-and-drop'])
    require(['custom/usability/help_panel/help_panel'])
//    require(['custom/usability/codefolding/codefolding'])
//    require(['custom/usability/init_cell/main'])
//    require(['custom/usability/runtools/runtools'])
//    require(['custom/usability/autosavetime'])
//    require(['custom/usability/autoscroll'])
//    require(['custom/usability/breakpoints'])
//    require(['custom/usability/chrome_clipboard'])
//    require(['custom/usability/clean_start'])
//    require(['custom/usability/comment-uncomment'])
//    require(['custom/usability/hide_input'])
//    require(['custom/usability/hide_input_all'])
    require(['custom/usability/linenumbers'])
    require(['custom/usability/navigation-hotkeys'])
//    require(['custom/usability/no_exec_dunder'])
//    require(['custom/usability/noscroll'])
    require(['custom/usability/read-only'])
//    require(['custom/usability/search'])
    require(['custom/usability/shift-tab'])
//    require(['custom/usability/split-combine'])
//    require(['custom/usability/toggle_all_line_number'])

});

IPython.Cell.options_default.cm_config.lineNumbers = true;

