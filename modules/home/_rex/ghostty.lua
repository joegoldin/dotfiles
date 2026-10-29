-- Ghostty's explicitly configured shortcuts; leave Rex's other defaults alone.
rex.bind("ctrl+shift+t", "client.tab.new")
rex.bind("ctrl+shift+w", "pane.close")
rex.bind("ctrl+shift+n", "client.window.new")

-- Match Ghostty's text:\x1b\r, not a client-dependent interpretation of Return.
rex.bind("shift+enter", function(ctx, ev)
  local result, err = rex.block.call("com.superlogical.terminal", "write", {
    data = "\027\r",
  })
  if err ~= nil then error(err, 0) end
  return true
end)
