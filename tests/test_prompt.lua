local prompt = require("herdr-nvim.prompt")

T.test("prompt: single comment, no git context", function()
  local s = prompt.format({
    { comment = { file = "/tmp/x.py", start_line = 5, end_line = 5, text = "rename to double" },
      snippet = { "def f(x): return x*2" }, comment_type = "feedback" },
  }, {})
  local expected = table.concat({
    "Notes from my editor:",
    "",
    "1. [feedback] /tmp/x.py:5",
    "   > def f(x): return x*2",
    "   Comment: rename to double",
    "",
    "Reply to each item: answer the questions and describe what you changed for the rest.",
  }, "\n")
  T.eq(s, expected)
end)

T.test("prompt: multiple comments numbered, snippet capped at 3 lines, header context", function()
  local s = prompt.format({
    { comment = { file = "a.rs", start_line = 1, end_line = 9, text = "c1" },
      snippet = { "l1", "l2", "l3", "l4", "l5" } },
    { comment = { file = "b.rs", start_line = 2, end_line = 3, text = "c2" },
      snippet = { "x", "y" } },
  }, { header_context = "repo: demo, branch: main" })
  T.ok(s:find("Notes from my editor (repo: demo, branch: main):", 1, true) == 1)
  T.ok(s:find("1. [feedback] a.rs:1-9", 1, true))
  T.ok(s:find("   > l3", 1, true))
  T.ok(not s:find("> l4", 1, true), "snippet must cap at 3 lines")
  T.ok(s:find("2. [feedback] b.rs:2-3", 1, true))
  T.ok(s:find("   Comment: c2", 1, true))
end)

T.test("prompt: items render their type label inline", function()
  local s = prompt.format({
    { comment = { file = "a.py", start_line = 1, end_line = 1, text = "why?" }, snippet = {}, comment_type = "question" },
    { comment = { file = "b.py", start_line = 2, end_line = 2, text = "fix" }, snippet = {}, comment_type = "feedback" },
  }, {})
  T.ok(s:find("1. [question] a.py:1\n", 1, true))
  T.ok(s:find("2. [feedback] b.py:2\n", 1, true))
end)

T.test("prompt: an item without a type renders as feedback", function()
  local s = prompt.format({
    { comment = { file = "a.py", start_line = 1, end_line = 1, text = "old" }, snippet = {} },
  }, {})
  T.ok(s:find("1. [feedback] a.py:1\n", 1, true))
end)

T.test("prompt: comments use the same short location as references", function()
  local s = prompt.format({
    { comment = { file = "/repo/lua/init.lua", start_line = 42, end_line = 42, text = "c" }, snippet = {} },
    { comment = { file = "/elsewhere/x.lua", start_line = 1, end_line = 3, text = "d" }, snippet = {} },
  }, { cwd = "/repo" })
  T.ok(s:find("1. [feedback] lua/init.lua:42\n", 1, true))
  T.ok(s:find("2. [feedback] /elsewhere/x.lua:1-3\n", 1, true))
end)

T.test("prompt: format_ref is a bare citation ending in a space", function()
  local s = prompt.format_ref({ file = "/repo/lua/init.lua", start_line = 5, end_line = 10 }, { cwd = "/repo" })
  T.eq(s, "lua/init.lua:5-10 ")
end)

T.test("prompt: format_ref collapses a single line", function()
  T.eq(prompt.format_ref({ file = "/repo/a.rs", start_line = 7, end_line = 7 }, { cwd = "/repo" }), "a.rs:7 ")
end)

T.test("prompt: single-line sub-span renders path:line:colStart-colEnd", function()
  -- 0-indexed start col 4, exclusive end col 9 -> 1-indexed inclusive 5-9.
  T.eq(prompt.location({ file = "/repo/a.rs", start_line = 12, end_line = 12, cols = { 4, 9 } }, "/repo"),
    "a.rs:12:5-9")
end)

T.test("prompt: multi-line span keeps a line-only location", function()
  T.eq(prompt.location({ file = "/repo/a.rs", start_line = 12, end_line = 14, cols = { 4, 9 } }, "/repo"),
    "a.rs:12-14")
end)

T.test("prompt: _relpath shortens against the cwd, keeps outside paths absolute", function()
  T.eq(prompt._relpath("/repo/lua/init.lua", "/repo"), "lua/init.lua")
  T.eq(prompt._relpath("/repo/lua/init.lua", "/repo/"), "lua/init.lua", "trailing slash tolerated")
  T.eq(prompt._relpath("/elsewhere/x.lua", "/repo"), "/elsewhere/x.lua", "outside the cwd stays absolute")
  T.eq(prompt._relpath("/repo-other/x.lua", "/repo"), "/repo-other/x.lua", "prefix must end at a separator")
  T.eq(prompt._relpath("/repo/x.lua", ""), "/repo/x.lua", "no cwd known → unchanged")
end)
