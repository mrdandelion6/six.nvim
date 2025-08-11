local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local rep = require("luasnip.extras").rep

return {
  -- std::string
  s("str", {
    t("std::string")
  }),

  -- std::vector<T>
  s("vec", {
    t("std::vector<"),
    i(1, "int"),
    t(">")
  }),

  -- std::cin
  s("cin", {
    t("std::cin >> "),
    i(1),
    t(";")
  }),

  -- std::cout
  s("cout", {
    t("std::cout << "),
    i(1),
    t(";")
  }),

  -- std::cerr
  s("cerr", {
    t("std::cerr << "),
    i(1),
    t(";")
  }),

  -- std::endl
  s("endl", {
    t("std::endl")
  }),

  -- Range-based for loop
  s("forr", {
    t("for ("),
    c(1, {
      t("const auto& "),
      t("auto& "),
      t("auto "),
    }),
    i(2, "item"),
    t(" : "),
    i(3, "container"),
    t(") {"),
    t({ "", "\t" }),
    i(0),
    t({ "", "}" })
  }),

  -- Traditional for loop
  s("fort", {
    t("for ("),
    c(1, {
      t("int "),
      t("size_t "),
      t("auto "),
    }),
    i(2, "i"),
    t(" = "),
    i(3, "0"),
    t("; "),
    rep(2),
    t(" < "),
    i(4, "n"),
    t("; ++"),
    rep(2),
    t(") {"),
    t({ "", "\t" }),
    i(0),
    t({ "", "}" })
  }),

  -- Do-while macro with clang-format guards
  s("mac", {
    t("// clang-format off"),
    t({ "", "#define " }),
    i(1, "MACRO"),
    t("("),
    i(2),
    t(") do { \\"),
    t({ "", "\t" }),
    i(0),
    t(" \\"),
    t({ "", "} while (0)" }),
    t({ "", "// clang-format on" })
  }),
}
