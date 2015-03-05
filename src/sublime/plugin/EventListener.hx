package sublime.plugin;

import python.Tuple;
import sublime.View;

@:pythonImport("sublime_plugin", "EventListener")
extern class EventListener {
    function on_query_completions(view:View, prefix:String, locations:Array<Int>):Tuple2<Array<Tuple2<String,String>>, Int>;
    function on_activated(view:View):Void;
    function on_deactivated(view:View):Void;
}
