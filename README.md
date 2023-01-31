# HTTP In-Memory Handler

[![GitHub release](https://img.shields.io/github/release/Xanders/in-memory-handler.svg)](https://github.com/Xanders/in-memory-handler/releases)

Sometimes you want to compile your program
into one small binary, even including all
the HTML/CSS/JS stuff for the web interface
or just one humble `api.md` file to serve.

It's easier and more secure to deploy such
binary in comparison to a bunch of files.
Also, it's much faster to serve static files
to the client from the memory rather than
reading them from the disc again and again
with the [HTTP::StaticFileHandler](https://crystal-lang.org/api/master/HTTP/StaticFileHandler.html).

*HTTP::InMemoryHandler* to the rescue!

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     in-memory-handler:
       github: Xanders/in-memory-handler
   ```

2. Run `shards install`

## Usage

There are two options for how to use this library.

### Single file

The first one is to serve only one file.
You can provide the optional `path` parameter
(defaults to file's name without extension)
and the optional `mime` parameter (will be
inferred by Crystal's [MIME](https://crystal-lang.org/api/master/MIME.html)
module by default).

```crystal
require "http/server"

require "in-memory-handler"

my_handler = HTTP::InMemoryFileHandler.for("src/api.md", path: "/help", mime: "text/markdown")

server = HTTP::Server.new [my_handler]
server.bind_tcp "0.0.0.0", 8080
server.listen
```

**GET** and **HEAD** HTTP methods are supported.
All other methods will lead to
[405 Method Not Allowed](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/405)
error.

*Note:* giving MIME type to Markdown file
will not lead to compiling it into HTML,
but you can use an extension for yourself.

### A folder

The second option is to serve the given folder.
In opposition to single file mode, regular files
will be served with their full names including
extensions, except `*.html` files, which will
be served without extensions. For example,
`favicon.ico` will be served as `/favicon.ico`
and `help.html` — as `/help`.

Subfolders are supported as well. For example,
`js/app.js` will be served as `/js/app.js`.

The special `index.html` will be served without
its name. For example, `api/index.html` will
be served at the `/api` URL. And `index.html`
in the root folder will be served as `/`.

You can use the `prefix` parameter when you want
to serve your files starting from a non-root URL.
For example, `api/index.html` with `prefix: "/static"`
would lead to the `/static/api` URL.

```crystal
require "http/server"

require "in-memory-handler"

my_handler = HTTP::InMemoryDirectoryHandler.for("public", prefix: "/static")

server = HTTP::Server.new [my_handler]
server.bind_tcp "0.0.0.0", 8080
server.listen
```

*Note:* In both modes adding an unnecessary `/`
at the end of the URL (`/some/`) will lead to
a [301 Moved Permanently](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/301)
redirect to the non-`/` version (`/some`).
This behavior is best for search engines.

## Development

I'm using [Docker](https://www.docker.com) for library development.
If you have Docker available, you can use `make` command
to see the help, powered by [make-help](https://github.com/Xanders/make-help) project.
There are commands for testing, formatting and documentation.

## Contributing

1. Fork it (<https://github.com/Xanders/in-memory-handler/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
