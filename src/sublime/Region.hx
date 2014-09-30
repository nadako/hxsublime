package sublime;

@:pythonImport("sublime", "Region")
extern class Region {
    var a:Int;
    var b:Int;
    var xpos:Int;

    @:overload(function(pt:Int):Void {})
    function new(a:Int, b:Int);

    function begin():Int;
    function end():Int;
    function size():Int;
    function empty():Bool;
    function cover(region:Region):Region;
    function intersection(region:Region):Region;
    function intersects(region:Region):Bool;
    @:overload(function(point:Int):Bool {})
    function contains(region:Region):Bool;
}