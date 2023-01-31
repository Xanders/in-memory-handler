require "io/memory"
require "base64"
require "mime"
require "compress/gzip"

# Never pollutes global namespace
# as it only runs at compile time

# :nodoc:
def file_to_cache(path, mime = "")
  raise "first argument is not a file" unless File.file?(path)

  info = File.info(path)

  mime = MIME.from_filename(path, "application/octet-stream") if mime.empty?
  mime = "#{mime}; charset=utf-8" if mime.starts_with?("text/") && !mime.includes?("; charset=")
  time = info.modification_time.to_unix

  memory = IO::Memory.new
  File.open(path) do |file|
    Compress::Gzip::Writer.open(memory) do |gzip|
      IO.copy(file, gzip)
    end
  end
  size = memory.size
  body = Base64.encode(memory.to_s)

  return "#{size}_u64, \"#{mime}\", #{time}_u64, IO::Memory.new(Base64.decode(\"#{body}\"))"
end
