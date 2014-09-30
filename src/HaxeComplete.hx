import python.lib.os.Path;
import python.lib.subprocess.Popen;
import python.lib.Tuple;
import python.lib.Bytes;

import sublime.def.Exec;
import sublime.View;

import BuildHelper.Build;

using StringTools;

@:enum abstract FieldCompletionKind(String) {
    var Var = "var";
    var Method = "method";
    var Type = "type";
    var Package = "package";
}

enum CompletionType {
    Toplevel;
    Field;
    Argument;
}

class HaxeServer {
    var proc:Popen;
    var port:Int;

    public function new() {
    }

    public function start(port:Int):Void {
        if (proc != null)
            stop();
        this.port = port;
        proc = new Popen(["haxe", "-v", "--wait", Std.string(port)]);
    }

    public function stop():Void {
        if (proc != null) {
            proc.terminate();
            proc = null;
        }
    }

    public function run(args:Array<String>):String {
        var sock = new sys.net.Socket();
        sock.connect(new sys.net.Host("127.0.0.1"), port);
        for (arg in args) {
            sock.output.writeString(arg);
            sock.output.writeByte('\n'.code);
        }
        sock.output.writeInt8(0);
        sock.waitForRead();
        var buf = new StringBuf();
        for (line in sock.read().split("\n")) {
            switch (line.fastCodeAt(0)) {
                case 0x01: // TODO: print
                case 0x02: // TODO: show error
                default:
                    buf.add(line);
                    buf.addChar('\n'.code);
            }
        }
        sock.close();
        return buf.toString();
    }
}

class HaxeComplete extends sublime.plugin.EventListener {

    public static var instance(default,null):HaxeComplete;

    var haxeServer:HaxeServer = null;

    function new() {
        instance = this;
    }

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

        var completionType:CompletionType = switch (prev) {
            case ".": Field;
            case "(": Toplevel;//Argument;
            default: Toplevel;
        }

        var b = python.NativeStringTools.encode(src.substr(0, offset), "utf-8");
        var bytePos = b.length;

        var mode = if (completionType.match(Toplevel)) "@toplevel" else "";

        var folder = null;
        for (f in view.window().folders()) {
            if (fileName.startsWith(f)) {
                folder = f;
                break;
            }
        }

        var cmd = [
            "--cwd", folder,
            "--no-output",
            "--display",
            '$fileName@$bytePos$mode'
        ];

        var build = getBuild(folder);

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

        trace("Running completion " + cmd.join(" "));

        var tempFile = saveTempFile(view);
        var result = runHaxe(cmd);
        restoreTempFile(view, tempFile);

        var xml = try {
            python.lib.xml.etree.ElementTree.XML(result);
        } catch (_:Dynamic) {
            trace("No completion:\n" + result);
            return null;
        }

        var result:Array<Tup2<String,String>> = [];

        switch (completionType) {
            case Toplevel:
                for (e in xml.findall("i")) {
                    var name = e.text;
                    var kind = e.attrib.get("k", "");
                    var hint = switch (kind) {
                        case "local" | "member" | "static" | "enum" | "global":
                            SignatureHelper.prepareSignature(e.attrib.get("t", null));
                        default:
                            "";
                    }
                    result.push(Tup2.create('$name$hint\t$kind', e.text));
                }

            case Field:
                for (e in xml.findall("i")) {
                    var name = e.attrib.get("n", "?");
                    var kind:FieldCompletionKind = cast e.attrib.get("k", "");
                    var hint = switch (kind) {
                        case Var | Method: SignatureHelper.prepareSignature(e.find("t").text);
                        case Type: "\ttype";
                        case Package: "\tpackage";
                    }
                    result.push(Tup2.create('$name$hint', name));
                }

            case Argument:
                view.show_popup_menu([xml.text], null);
                return null;
        }

        return Tup2.create(result, sublime.Sublime.INHIBIT_WORD_COMPLETIONS);
    }

    public function getBuild(folder:String):Build {
        return BuildHelper.parse(sys.io.File.getContent(Path.join(folder, "build.hxml")));
    }

    public function runHaxe(args:Array<String>):String {
        var haxePort = 6000;
        if (haxeServer == null) {
            haxeServer = new HaxeServer();
            haxeServer.start(haxePort);
        }
        return haxeServer.run(args);
    }

    public function saveTempFile(view:View):String {
        var currentFile = view.file_name();
        var tempFile = currentFile + ".tmp";
        var content = view.substr(new sublime.Region(0, view.size()));
        python.lib.ShUtil.copy2(currentFile, tempFile);
        sys.io.File.saveContent(currentFile, content);
        return tempFile;
    }

    public function restoreTempFile(view:View, tempFile:String):Void {
        var currentFile = view.file_name();
        python.lib.ShUtil.copy2(tempFile, currentFile);
        sys.FileSystem.deleteFile(tempFile);
    }
}
