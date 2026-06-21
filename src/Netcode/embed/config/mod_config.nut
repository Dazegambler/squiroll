local item_table = {
    lang0 = {
        hitbox = "View hitboxes(jp)"
        discord = "Use Discord(requries restart)(jp)"
    }
    lang1 = {
        hitbox = "View hitboxes"
        discord = "Use Discord(requries restart)"
    }
};

local ptr = {
    hitbox = ::UI.Menu.Config.SquirollPTR(::overlay,"enabled","hitbox_vis","enabled")
    discord = ::UI.Menu.Config.SquirollPTR(::discord,"enabled","misc","discord_integration")
};

::UI.Menu.Create.call(this,
    ::UI.Menu.Page(
        ::UI.Menu.Struct.Title("Squiroll"),
        ::UI.Menu.Enum.Boolean(item_table,"hitbox",ptr.hitbox),
        ::UI.Menu.Enum.Boolean(item_table,"discord",ptr.discord)
    )
);
