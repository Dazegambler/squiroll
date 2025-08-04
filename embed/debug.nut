function patch_instance(inst) {
	local base_type = inst.getclass();

    local subclass = class extends base_type {
        constructor(inst) {
            foreach(k,v in inst.getclass()){
                if (typeof v != "function"){
                    this[k] = v;
                }
            }
        }

        function SetMotion(motion,take) {
            ::print("success!\n");
            base.SetMotion(motion,take);
        }
    };

    return subclass(inst);
}