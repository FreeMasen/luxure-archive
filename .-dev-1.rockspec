package = "."
version = "dev-1"
source = {
   url = "https://github.com/freemasen/luxure"
}
description = {
   homepage = "https://github.com/freemasen/luxure",
   license = "MIT"
}
build = {
   type = "builtin",
   modules = {
      init = "lib/init.lua",
      ["request.header"] = "lib/request/header.lua",
      ["request.init"] = "lib/request/init.lua"
   }
}
