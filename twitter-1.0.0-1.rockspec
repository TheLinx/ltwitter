package = "twitter"
version = "1.0.0-1"
description = {
    summary = "A Twitter library for Lua.",
    detailed = [[
        A Twitter library for Lua.
    ]],
    license = "CC0",
    homepage = "http://github.com/TheLinx/ltwitter",
    maintainer = "Linus Sjögren <thelinx@unreliablepollution.net>"
}
dependencies = {
    "lua >= 5.1",
    "json4lua >= 0.9.3",
    "oauth >= 0",
}
source = {
    url = "git://github.com/TheLinx/ltwitter.git",
    tag = "1.0.0"
}
build = {
    type = "builtin",
    modules = {
        twitter = "twitter/init.lua"
    }
}
