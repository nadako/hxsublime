package sublime;

extern class Window {
    function folders():Array<String>;
    function open_file(file_name:String, ?flags:Int):View;
}