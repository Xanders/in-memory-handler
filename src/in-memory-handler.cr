require "http/server/handler"
require "io/memory"

abstract class HTTP::InMemoryHandler
  include HTTP::Handler
end

# Class for single file handling
class HTTP::InMemoryFileHandler < HTTP::InMemoryHandler
  @path : String
  @size : UInt64
  @mime : String
  @time : UInt64
  @body : IO::Memory

  def initialize(@path, @size, @mime, @time, @body)
  end

  def call(context)
    # TODO: cache like in https://github.com/crystal-lang/crystal/blob/master/src/http/server/handlers/static_file_handler.cr
    case context.request.path
    when @path
      if context.request.method == "GET" || context.request.method == "HEAD"
        context.response.content_length = @size
        context.response.content_type = @mime
        context.response.headers.add("Content-Encoding", "gzip")
        IO.copy(@body.rewind, context.response) unless context.request.method == "HEAD"
      else
        context.response.status = :method_not_allowed
        context.response.headers.add("Allow", "GET, HEAD")
      end
    when @path + "/"
      context.response.status = :moved_permanently
      context.response.headers.add("Location", @path)
    else
      call_next(context)
    end
  end

  # Creates a handler for single static file
  #
  # *path* should start with */* and not finish with */*
  #
  # *mime* would be used when given
  # even if Crystal can infer MIME type with itself
  macro for(file, path = "", mime = "")
    file, path, mime = {{ file }}, {{ path }}, {{ mime }}
    path = "/" + File.basename(file, suffix: File.extname(file)) if path.empty?
    HTTP::InMemoryFileHandler.new(path, {{ run("./macro/file_builder.cr", file, mime) }})
  end
end

# Class for folder handling
class HTTP::InMemoryDirectoryHandler < HTTP::InMemoryHandler
  @data : Hash(String, {UInt64, String, UInt64, IO::Memory})

  def initialize(@data, prefix = "")
    return if prefix.empty?

    raise ArgumentError.new("prefix should start with slash") unless prefix.starts_with?("/")
    raise ArgumentError.new("prefix should not end with slash") if prefix.ends_with?("/")
    @data = @data.transform_keys { |path| path == "/" ? prefix : prefix + path }
  end

  def call(context)
    # TODO: cache like in https://github.com/crystal-lang/crystal/blob/master/src/http/server/handlers/static_file_handler.cr
    if @data.has_key?(context.request.path)
      if context.request.method == "GET" || context.request.method == "HEAD"
        size, mime, time, body = @data[context.request.path]
        context.response.content_length = size
        context.response.content_type = mime
        context.response.headers.add("Content-Encoding", "gzip")
        IO.copy(body.rewind, context.response) unless context.request.method == "HEAD"
      else
        context.response.status = :method_not_allowed
        context.response.headers.add("Allow", "GET, HEAD")
      end
    elsif context.request.path.ends_with?("/") && @data.has_key?(context.request.path[0..-2])
      context.response.status = :moved_permanently
      context.response.headers.add("Location", context.request.path[0..-2])
    else
      call_next(context)
    end
  end

  # Creates a handler for all the files in given folder
  #
  # *prefix* should start with */* and not finish with */*
  macro for(dir, prefix = "")
    {% raise ArgumentError, "HTTP::InMemoryDirectoryHandler.new first argument should not end with slash" if dir.ends_with?("/") %}
    HTTP::InMemoryDirectoryHandler.new({{ run("./macro/directory_builder.cr", dir) }}, prefix: {{ prefix }})
  end
end
