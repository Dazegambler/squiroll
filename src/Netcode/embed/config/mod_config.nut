local item_table = {
    lang0 = {
        hitbox = ["View hitboxes(jp)","Disabled(jp)","Enabled(jp)"]
        discord = ["Use Discord**(jp)","Disabled(jp)","Enabled(jp)"]
    }
    lang1 = {
        hitbox = ["View hitboxes","Disabled","Enabled"]
        discord = ["Use Discord**","Disabled","Enabled"]
    }
};

local ptr = {
    hitbox = ::UI.Config.SquirollPTR(::overlay,"enabled","hitbox_vis","enabled")
    discord = ::UI.Config.SquirollPTR(::discord,"enabled","misc","discord_integration")
};

::UI.Menu.Create.call(this,
    ::UI.Menu.Page(
        ::UI.Menu.Struct.Title("Squiroll"),
        ::UI.Menu.Enum.Boolean(item_table,"hitbox",ptr.hitbox),
        ::UI.Menu.Enum.Boolean(item_table,"discord",ptr.discord)
    )
);
