# Setup Sklair

This is a simple custom GitHub Action which installs a pinned [Sklair](https://sklair.numelon.com)
release in your runner's PATH.

For more information, please see the [deployment guide](https://sklair.numelon.com/docs/sklair/deployment/)
in the Sklair documentation.

```yaml
steps:
  - uses: actions/checkout@v6
  - uses: numelon-oss/setup-sklair@v1
    with:
      version: '0.4.0'
  - run: sklair build
```

`version` is required and accepts a release number with or without `v`, including
prereleases.

Use `sklair build` in the directory containing your project, and deploy the built
output (or do anything you need with it, really).
