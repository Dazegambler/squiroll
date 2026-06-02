//improved input handler
class InputDevice extends ::manbow.InputSingle {
    map = null;
    constructor(mapping) {
        base.constructor();
        map = ::manbow.DeviceMapping();
        foreach (k,v in mapping)Bind(k,v);
        SetDeviceAssign(map);
    }

    function Bind(key,val) {map[key] = val;}

    function Apply(){SetDeviceAssign(map);}
}

class InputManager extends ::manbow.InputMulti {
    devices = null;
    constructor(dev) {
        base.constructor();
        devices = {}; 
        foreach (k,d in dev)Add(k,d);
        local manager = this;
        ::loop.AddTask({
            Update = function() {
                if (!manager)::loop.DeleteTask(this);
                else manager.Update();
            }
        });
    }
    
    function Bind(dev,input,val) {
        devices[dev].Bind(input,val);
        Apply();
    }

    function Apply(){
        foreach (i in devices)i.Apply();
    }

    function Add(label,input) {
        Append(input);
        devices[label] <- input;
    }

    function Remove(label) {
        delete devices[label];
    }

    function Clear() {
        base.Clear();
        devices = {};
    }
}

function Poll() {
    local id = -1;
    id = ::manbow.GetKeyboardState();
    if (id >= 0)return id;
    id = ::manbow.GetPadButtonState();
    return id;
}
