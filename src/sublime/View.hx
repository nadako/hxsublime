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

}
