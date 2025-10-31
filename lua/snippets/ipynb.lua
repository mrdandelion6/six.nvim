local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node

-- function to get current date
local function get_date()
  return os.date '%Y-%m-%d'
end

return {
  -- full metadata header
  s('meta', {
    t '---',
    t { '', 'title: "' },
    i(1, 'Untitled'),
    t '"',
    t { '', 'author: "faisal shaik"' },
    t { '', 'date: "' },
    f(get_date, {}),
    t '"',
    t { '', 'format:' },
    t { '', '  html:' },
    t { '', '    code-fold: true' },
    t { '', '    toc: true' },
    t { '', '  pdf:' },
    t { '', '    keep-tex: true' },
    t { '', 'jupyter: ' },
    i(2, 'python3'),
    t { '', 'execute:' },
    t { '', '  echo: true' },
    t { '', '  warning: false' },
    t { '', '---', '' },
    t { '', '# ' },
    i(3, 'Introduction'),
    t { '', '' },
    i(0),
  }),

  -- simple metadata (no pdf)
  s('qmeta', {
    t '---',
    t { '', 'title: "' },
    i(1, 'Untitled'),
    t '"',
    t { '', 'author: "faisal shaik"' },
    t { '', 'date: "' },
    f(get_date, {}),
    t '"',
    t { '', 'format: html' },
    t { '', 'jupyter: python3' },
    t { '', '---', '' },
    t { '', '# ' },
    i(2, 'Setup'),
    t { '', '' },
    i(0),
  }),

  -- python code cell
  s('py', {
    t '```{python}',
    t { '', '' },
    i(0),
    t { '', '```' },
  }),

  -- python cell for plots
  s('pyfig', {
    t '```{python}',
    t { '', '#| label: fig-' },
    i(1, 'plot'),
    t { '', '#| fig-cap: "' },
    i(2, 'Caption'),
    t '"',
    t { '', '#| fig-width: ' },
    i(3, '8'),
    t { '', '#| fig-height: ' },
    i(4, '6'),
    t { '', '' },
    i(0),
    t { '', '```' },
  }),

  -- callout blocks
  s('note', {
    t '::: {.callout-note}',
    t { '', '' },
    i(0),
    t { '', ':::' },
  }),
  s('warn', {
    t '::: {.callout-warning}',
    t { '', '' },
    i(0),
    t { '', ':::' },
  }),
  s('tip', {
    t '::: {.callout-tip}',
    t { '', '' },
    i(0),
    t { '', ':::' },
  }),
  s('imp', {
    t '::: {.callout-important}',
    t { '', '' },
    i(0),
    t { '', ':::' },
  }),

  -- bash code cell
  s('bash', {
    t '```{bash}',
    t { '', '' },
    i(0),
    t { '', '```' },
  }),
}
