import python.lib.Os;
import python.lib.os.Path;

class Utils {

    /**
        Convert normalized path returned by Haxe to the OS path.
    **/
    public static function convertPath(path:String):String {
        if (Sys.systemName() == "Windows") {
            var r = Path.split(path), dir = r._1, file = r._2;
            for (f in Os.listdir(dir)) {
                if (f.toLowerCase() == file)
                    return Path.join(dir, f);
            }
        }
        return path;
    }
}