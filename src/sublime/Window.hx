package sublime;

extern class Window {
    function folders():Array<String>;
    function open_file(file_name:String, ?flags:Int):View;
    function create_output_panel(name:String):View;
    function run_command(cmd:String, ?args:Dynamic):Void;
}