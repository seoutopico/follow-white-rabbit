# follow-white-rabbit

This repository is the **publishing destination** for a personal research feed generated daily by [`follow-white-rabbit-plugin`](https://github.com/seoutopico/follow-white-rabbit-plugin).

It does **not** contain code. The code lives in the plugin repo above.

## Where to read the feed

Web site: **<https://seoutopico.github.io/follow-white-rabbit/>**
Archive:  **<https://seoutopico.github.io/follow-white-rabbit/archive/>**

## RSS subscriptions

Pick any of these URLs in your RSS reader (Feedly, Inoreader, Reeder, NetNewsWire, …) or import the OPML to get them all in one go:

- OPML (all at once): <https://seoutopico.github.io/follow-white-rabbit/index.opml>
- Combined feed (every topic): <https://seoutopico.github.io/follow-white-rabbit/white-rabbit.xml>
- Per topic:
  - Claude Code: <https://seoutopico.github.io/follow-white-rabbit/white-rabbit-claude-code.xml>
  - IA Generativa: <https://seoutopico.github.io/follow-white-rabbit/white-rabbit-ia-generativa.xml>
  - Papers de IA: <https://seoutopico.github.io/follow-white-rabbit/white-rabbit-papers-ia.xml>
  - CPS (Complex Problem Solving): <https://seoutopico.github.io/follow-white-rabbit/white-rabbit-cps.xml>
  - Casos de uso de IA: <https://seoutopico.github.io/follow-white-rabbit/white-rabbit-casos-uso-ia.xml>

## How it works

The plugin runs once a day on the maintainer's machine, researches each topic with Claude, generates RSS XML + human-readable HTML pages, and pushes the result to this repo's `gh-pages` branch. GitHub Pages serves it at the URLs above.

If you want your own daily research feed about your own topics, install the plugin:

```
/plugin marketplace add seoutopico/follow-white-rabbit-plugin
/plugin install follow-white-rabbit@seoutopico
/setup
```

The plugin docs walk you through the rest: <https://github.com/seoutopico/follow-white-rabbit-plugin>.

## License

[MIT](LICENSE).
