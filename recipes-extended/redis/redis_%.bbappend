PR:append = ".1"

# Use virtual/lua so PREFERRED_PROVIDER_virtual/lua (luajit) is honored.
DEPENDS:remove = "lua"
DEPENDS:append = " virtual/lua"
