package sublime;

@:pythonImport("sublime", "Selection")
extern class Selection implements ArrayAccess<Region> {
    function clear():Void;
    function add(region:Region):Void;
}