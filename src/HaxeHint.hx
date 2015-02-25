private typedef Args = {input:String};

class HaxeHint extends sublime.plugin.TextCommand<Args> {
    override function run(edit:sublime.Edit, ?args:python.KwArgs<Args>) {
        var args = args.typed();
        view.run_command("insert", python.Lib.anonAsDict({characters: args.input}));

        trace("Showing hint " + args);
    }
}
