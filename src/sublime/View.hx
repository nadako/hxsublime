package sublime;

import python.Dict;

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

    function set_scratch(value:Bool):Void;
    function set_read_only(value:Bool):Void;

    function show_popup(content:String, ?flags:Int, ?location:Int, ?max_width:Int, ?max_height:Int, ?on_navigate:Void->Void, ?on_hide:Void->Void):Void;
    function update_popup(content:String):Void;
    function is_popup_visible():Bool;
    function hide_popup():Void;
}
