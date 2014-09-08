package sublime.plugin;

import python.lib.Tuple;
import sublime.View;

@:pythonImport("sublime_plugin", "EventListener")
extern class EventListener {
    function on_query_completions(view:View, prefix:String, locations:Array<Int>):Tup2<Array<Tup2<String,String>>, Int>;
    function on_activated(view:View):Void;
    function on_deactivated(view:View):Void;
}
