package sublime;

@:pythonImport("sublime")
extern class Sublime {
    static var INHIBIT_EXPLICIT_COMPLETIONS(default,null):Int;
    static var INHIBIT_WORD_COMPLETIONS(default,null):Int;

    static function set_timeout(callback:Void->Void, delay:Int):Void;
    static function windows():Array<Window>;
    static function status_message(string:String):Void;
}