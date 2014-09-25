using StringTools;

@:enum abstract Target(String) {
    var Js = "js";
    var Neko = "neko";
    var Cpp = "cpp";
    var Cs = "cs";
    var Java = "java";
    var Python = "python";
    var Swf = "swf";
    var As3 = "as3";
    var Xml = "xml";
    var Php = "php";
}

typedef Build = {
    main:String,
    target:Target,
    output:String,
    classPaths:Array<String>,
    libs:Array<String>,
    args:Array<String>,
}

enum HxmlLine {
    Comment(comment:String);
    Simple(name:String);
    Param(name:String, value:String);
}

class BuildHelper {
    public static function parse(hxml:String):Build {
        return createBuilds(parseHxmlLines(hxml));
    }

    static function unquote(s:String):String {
        var len = s.length;
        return if (len > 0 && s.fastCodeAt(0) == "\"".code && s.fastCodeAt(len - 1) == "\"".code)
            s.substring(1, len - 1);
        else
            s;
    }

    static function parseHxmlLines(src:String):Array<HxmlLine> {
        var result = [];
        var srcLines = ~/[\n\r]+/g.split(src);
        for (line in srcLines) {
            line = unquote(line.trim());
            if (line.length == 0)
                continue;
            if (line.startsWith("#")) {
                result.push(Comment(line.substr(1).ltrim()));
            } else if (line.startsWith("-")) {
                var idx = line.indexOf(" ");
                if (idx == -1) {
                    result.push(Simple(line));
                } else {
                    var name = line.substr(0, idx);
                    var value = unquote(line.substr(idx).ltrim());
                    result.push(Param(name, value));
                }
            } else {
                result.push(Simple(line));
            }
        }
        return result;
    }

    static function createBuilds(lines:Array<HxmlLine>):Build {
        var build:Build = {
            main: null,
            target: null,
            output: null,
            classPaths: [],
            libs: [],
            args: [],
        };

        for (line in lines) {
            switch (line) {
                case Comment(_): // do nothing

                case Param("-main", main):
                    build.main = main;

                case Param("-cp", path):
                    build.classPaths.push(path);

                case Param("-lib", name):
                    build.libs.push(name);

                case Param(target = ("-cpp" | "-cs" | "-java" | "-js" | "-neko" | "-python" | "-swf" | "-as3" | "-xml" | "-php"), output):
                    build.target = cast target.substr(1);
                    build.output = output;

                case Param("--run", main):
                    build.target = Neko;
                    build.main = main;

                case Simple("--interp"):
                    build.target = Neko;

                case Param(name, value):
                    build.args.push(name);
                    build.args.push(value);

                // TODO: support --each and --next and multiple builds from a single hxml file
                // for now it means that build file is ended, so i can separate -cmd and other stuff from completion params
                case Simple("--each"):
                case Simple("--next"):
                    break;

                case Simple(name):
                    build.args.push(name);
            }
        }

        if (build.target == null)
            build.target = Neko;
        if (build.output == null)
            build.output = "__none__";

        return build;
    }
}
