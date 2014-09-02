class HaxeGotoDefinition extends sublime.plugin.TextCommand {
    override function run(edit:sublime.Edit):Void {
        var word = view.word(view.sel()[0]);
        var content = view.substr(new sublime.Region(0, word.b));
        var offset = python.lib.Codecs.encode(content, "utf-8").length + 1;
        trace(offset);
    }
}