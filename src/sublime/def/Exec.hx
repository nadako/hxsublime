package sublime.def;

import python.Dict;
import python.lib.Bytes;

@:pythonImport("Default.exec", "AsyncProcess")
extern class AsyncProcess {
    function new(cmd:Array<String>, shell_cmd:String, env:Dict<String,String>, listener:ProcessListener);
}

@:pythonImport("Default.exec", "ProcessListener")
extern class ProcessListener {
    function on_data(proc:AsyncProcess, data:Bytes):Void;
    function on_finished(proc:AsyncProcess):Void;
}
