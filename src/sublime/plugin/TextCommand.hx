package sublime.plugin;

@:pythonImport("sublime_plugin", "TextCommand")
extern class TextCommand {
    var view(default,null):sublime.View;
    function run(edit:sublime.Edit):Void;
    function is_enabled():Bool;
    function is_visible():Bool;
    function description():Null<String>;
}
