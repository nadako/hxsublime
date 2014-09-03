import python.lib.os.Path;

import python.lib.Tuple;
import python.lib.Bytes;

import sublime.def.Exec;
import sublime.View;

using StringTools;

@:enum abstract FieldCompletionKind(String) {
    var Var = "var";
    var Method = "method";
    var Type = "type";
    var Package = "package";
}

class HaxeComplete extends sublime.plugin.EventListener {
    override function on_query_completions(view:sublime.View, prefix:String, locations:Array<Int>):Tup2<Array<Tup2<String,String>>, Int> {
        var pos = locations[0];

        var scopeName = view.scope_name(pos);
        if (scopeName.indexOf("source.haxe") != 0)
            return null;

        var scopes = scopeName.split(" ");
        for (scope in scopes) {
            if (scope.startsWith("string") || scope.startsWith("comment"))
                return null;
        }

        var fileName = view.file_name();
        if (fileName == null)
            return null;

        var offset = pos - prefix.length;
        var src = view.substr(new sublime.Region(0, view.size()));

        var prev = src.charAt(offset - 1);
        var cur = src.charAt(offset);

        var toplevel = (prev != "." && prev != "(");

        var b = python.NativeStringTools.encode(src.substr(0, offset), "utf-8");
        var bytePos = b.length;

        var mode = if (toplevel) "@toplevel" else "";

        var folder = null;
        for (f in view.window().folders()) {
            if (fileName.startsWith(f)) {
                folder = f;
                break;
            }
        }

        var cmd = [
            "haxe",
            "--no-output",
            "--display",
            '$fileName@$bytePos$mode'
        ];

        var buildFile = Path.join(folder, "build.hxml");
        var build = BuildHelper.parse(sys.io.File.getContent(buildFile));

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

        var si = python.lib.Subprocess.STARTUPINFO();
        si.dwFlags = python.lib.Subprocess.STARTF_USESHOWWINDOW;
        si.wShowWindow = python.lib.Subprocess.SW_HIDE;

        trace("Running completion " + cmd.join(" "));

        var tempFile = saveTempFile(view);
        var proc = python.lib.subprocess.Popen.create(cmd, {
            startupinfo: si,
            stderr: python.lib.Subprocess.PIPE,
            cwd: folder
        });
        var result = proc.communicate(15);
        restoreTempFile(view, tempFile);
        var out = result._1, err = result._2;

        var result = err.decode();
        trace(result);
        var xml = try {
            python.lib.xml.etree.ElementTree.XML(result);
        } catch (_:Dynamic) {
            trace("No completion:\n" + result);
            return null;
        }

        var result:Array<Tup2<String,String>> = [];

        for (e in xml.findall("i")) {
            if (toplevel) {
                var name = e.text;
                var kind = e.attrib.get("k", "");
                var hint = switch (kind) {
                    case "local" | "member" | "static" | "enum" | "global":
                        SignatureHelper.prepareSignature(e.attrib.get("t", null));
                    default:
                        "";
                }
                result.push(Tup2.create('$name$hint\t$kind', e.text));
            } else {
                var name = e.attrib.get("n", "?");
                var kind:FieldCompletionKind = cast e.attrib.get("k", "");
                var hint = switch (kind) {
                    case Var | Method: SignatureHelper.prepareSignature(e.find("t").text);
                    case Type: "\ttype";
                    case Package: "\tpackage";
                }
                result.push(Tup2.create('$name$hint', name));
            }
        }

        return Tup2.create(result, sublime.Sublime.INHIBIT_WORD_COMPLETIONS);
    }

    function saveTempFile(view:View):String {
        var currentFile = view.file_name();
        var tempFile = currentFile + ".tmp";
        var content = view.substr(new sublime.Region(0, view.size()));
        python.lib.ShUtil.copy2(currentFile, tempFile);
        sys.io.File.saveContent(currentFile, content);
        return tempFile;
    }

    function restoreTempFile(view:View, tempFile:String):Void {
        var currentFile = view.file_name();
        python.lib.ShUtil.copy2(tempFile, currentFile);
        sys.FileSystem.deleteFile(tempFile);
    }
}
