import python.lib.Codecs;

import sublime.View;

using StringTools;

class HaxeGotoDefinition extends sublime.plugin.TextCommand<Dynamic> {
    override function run(edit:sublime.Edit, ?_):Void {
        var fileName = view.file_name();
        if (fileName == null)
            return null;

        var word = view.word(view.sel()[0]);
        var content = view.substr(new sublime.Region(0, word.b));
        var offset = python.lib.Codecs.encode(content, "utf-8").length + 1;

        var context = HaxeComplete.instance;

        var folder = null;
        for (f in view.window().folders()) {
            if (fileName.startsWith(f)) {
                folder = f;
                break;
            }
        }

        var build = context.getBuild(folder);
        var cmd = [
            "--cwd", folder,
            "--no-output",
            "--display",
            '$fileName@$offset@position'
        ];

        cmd.push("-" + build.target);
        cmd.push(build.output);

        for (cp in build.classPaths) {
            cmd.push("-cp");
            cmd.push(cp);
        }

        for (lib in build.libs) {
            cmd.push("-lib");
            cmd.push(lib);
        }

        if (build.main != null) {
            cmd.push("-main");
            cmd.push(build.main);
        }

        for (arg in build.args) {
            if (arg != "--no-output")
                cmd.push(arg);
        }

        var tempFile = context.saveTempFile(view);
        var result = context.runHaxe(cmd);
        context.restoreTempFile(view, tempFile);

        var xml = try {
            python.lib.xml.etree.ElementTree.XML(result);
        } catch (_:Dynamic) {
            trace("No position info:\n" + result);
            return;
        }

        var pos = xml.find("pos");
        if (pos == null)
            return;

        var re = ~/^(.*):(\d+): (lines|characters) (\d+)-\d+$/;
        if (!re.match(pos.text)) {
            trace("Invalid position info: " + pos.text);
            return;
        }

        trace(pos.text);

        var path = Utils.convertPath(re.matched(1));
        var line = Std.parseInt(re.matched(2));
        var mode = re.matched(3);
        var start = Std.parseInt(re.matched(4));
        if (mode == "lines")
            start = 0;

        var window = sublime.Sublime.active_window();
        var view = window.open_file(path);
        gotoPosition(view, line, start);
    }

    function gotoPosition(view:View, line:Int, start:Int):Void {
        if (view.is_loading()) {
            sublime.Sublime.set_timeout(gotoPosition.bind(view, line, start), 10);
            return;
        }

        var point = view.text_point(line - 1, 0);

        if (start > 0) {
            var lineString = view.substr(view.full_line(point));
            var src:python.lib.Bytes = python.Syntax.arrayAccess(Codecs.encode(lineString, "utf-8"), 0, start);
            var col = Codecs.decode(src, "utf-8").length;
            point = view.text_point(line - 1, col);
        }

        view.sel().clear();
        view.sel().add(new sublime.Region(point));
        view.show_at_center(point);

    }
}