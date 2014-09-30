package sublime;

import python.lib.Dict;

@:pythonImport("sublime", "View")
extern class View {

    function size():Int;
    function file_name():String;
    function scope_name(point:Int):String;
    function substr(region:Region):String;
    function run_command(string:String, ?args:Dict<String,Dynamic>):Void;
    function window():Window;
    @:overload(function(region:Region):Region {})
    function word(point:Int):Region;
    function sel():Selection;
    function show_popup_menu(items:Array<String>, on_done:Int->Void):Void;
    function is_loading():Bool;
    function text_point(row:Int, col:Int):Int;
    function show_at_center(point:Int):Void;

    @:overload(function(region:Region):Region {})
    function full_line(point:Int):Region;
}
