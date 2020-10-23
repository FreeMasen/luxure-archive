package = "luxure"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      luxure = "luxure.lua",
      ["luxure.request"] = "luxure/request.lua",
      ["luxure.response"] = "luxure/response.lua",
      ["luxure.router"] = "luxure/router.lua",
      ["luxure.server"] = "luxure/server.lua",
      ["luxure.utils"] = "luxure/utils.lua",
      run_tests = "run_tests.lua"
   }
}
