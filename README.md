# ion-fusion.github.io

Source for the Fusion website at: <https://ion-fusion.dev/>

The site is currently built with Jekyll, and deployed via GitHub Pages.

## Development

### Docker

If you have a Docker-compatible CLI ([docker], [podman], [nerdctl], ...) capable of running Debian
Linux containers, you can build and serve the site via the included [Dockerfile](Dockerfile) with
invocations like:

```shell
docker build -t fusion-site .
```

Or, without even acquiring the sources:

```shell
docker build -t fusion-site https://github.com/ion-fusion/ion-fusion.github.io.git
```

After building, you can run the jekyll server with invocations like:

```shell
docker run -p 4000:4000 fusion-site
```

Or, to leverage Jekyll's auto-generation and live-reloading:

```shell
docker run -p 4000:4000 -p 35729:35729 -v "$(pwd):/home/build/fusion-site" fusion-site
```

You can pass extra flags to `jeykll serve` with invocations like:

```shell
docker run -p 4000:4000 fusion-site bundlew exec-jekyll-serve --drafts
```

Or, even run arbitrary `jekyll` commands with:

```shell
docker run fusion-site bundlew exec jekyll --help
```

[docker]: https://www.docker.com/products/cli/
[podman]: https://podman.io/
[nerdctl]: https://github.com/containerd/nerdctl

### macOS

On Mac, you'll probably install Ruby via Homebrew:

```shell
brew install ruby
```

...and add it to your path:

```shell
PATH=/opt/homebrew/opt/ruby/bin:$PATH
```

(I like to use `direnv` for the latter, so it's a local configuration.)

After checkout:

```shell
bundle install
```

To serve the site locally:

```shell
bundle exec jekyll serve
```

By default, the server will regenerate content when pages change. 

* The `--livereload` flag injects some JavaScript to auto-refresh your browser
  when a page rebuilds.  It's pretty sweet!
* The `--drafts` flag adds any pages in the `_drafts` directory to the blog, as
  if they were dated files in `_posts`.

For more info, see
[Testing your GitHub Pages site locally with Jekyll](https://docs.github.com/en/articles/testing-your-github-pages-site-locally-with-jekyll).


### Deploying your fork to GitHub Pages

You _can_ enable GitHub Pages deployments on your fork, but the site will be broken.
That's because the URLs GitHub uses for account-level and repo-level Pages are incompatible 
as far as Jekyll is concerned. Here, the upstream repo will deploy to `ion-fusion.github.io`
due to it having that magic name. But when forked, it'll deploy to (eg) 
`toddjonker.github.io/ion-fusion.github.io` which breaks all relative links unless the Jekyll
config is tweaked. I don't have a great solution to this, but we can probably live without it
and rely on local debugging.

To fix this, you'll need to create a local branch in which you change this setting in
`_config.yml`:

```yaml
baseurl: "/ion-fusion.github.io"   # ...or whatever you've named your fork
```

Push that branch to GitHub, and configure your repo's Pages to publish from that branch.

**Be very careful not to propagate that change upstream!**

Surprisingly, I could only find two complaints about this problem:

* https://stackoverflow.com/questions/46177672 notes the above change, along with
  a CNAME change that I've yet to need (but probably will).
* https://github.com/actions/starter-workflows/issues/1673 links to code that seems
  to address the problem, but its from an obsolete workflow version. And that approach
  doesn’t cover the older “publish from a branch” approach I’m currently using.

