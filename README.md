# Project Spell Check

An additional dictionary for the `spell-check-test` package that provides project folder specific language. All spell-checked buffers within a given proejct will use the `language.json` file, if present in the project root.

```json
{
  "knownWords": [
    "word",
    "/specific-word/",
    "/SomeWord/i"
  ]
}
```
