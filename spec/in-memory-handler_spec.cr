require "./spec_helper"

def request(handler, path, method = "GET")
  server = HTTP::Server.new [handler]
  server.bind_tcp "0.0.0.0", 18080

  response = nil

  spawn do
    response = HTTP::Client.exec method, "http://localhost:18080#{path}"
    server.close
  end

  server.listen

  response.should_not be nil

  return response.not_nil!
end

describe HTTP::InMemoryFileHandler do
  it "works" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/file.txt")

    response = request handler, "/file"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/plain; charset=utf-8"
    response.headers["Location"]?.should eq nil
    response.headers["Allow"]?.should eq nil
    response.body.lines.first.should eq "Test text file!"
  end

  it "works for unknown mime type" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/some.unknown")

    response = request handler, "/some"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "application/octet-stream"
    response.body.lines.first.should eq "Some unknown data"
  end

  it "works for unknown mime type with forced parameter" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/some.unknown", mime: "text/plain")

    response = request handler, "/some"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/plain; charset=utf-8"
    response.body.lines.first.should eq "Some unknown data"
  end

  it "works for HEAD requests" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/file.txt")

    response = request handler, "/file", method: "HEAD"

    response.status_code.should eq 200
    response.body.should eq ""
  end

  it "respond 404 for unknown path" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/file.txt")

    response = request handler, "/help"

    response.status_code.should eq 404
    response.body.should eq "404 Not Found\n"
  end

  it "respond 301 for slash at end" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/file.txt")

    response = request handler, "/file/"

    response.status_code.should eq 301
    response.headers["Location"].should eq "/file"
    response.body.should eq ""
  end

  it "respond 405 for non-GET/HEAD requests" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/file.txt")

    response = request handler, "/file", method: "POST"

    response.status_code.should eq 405
    response.headers["Allow"].should eq "GET, HEAD"
    response.body.should eq ""
  end

  it "works for custom path" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/file.txt", path: "/help")

    response = request handler, "/help"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/plain; charset=utf-8"
    response.body.lines.first.should eq "Test text file!"
  end

  it "respond 404 for old path when custom given" do
    handler = HTTP::InMemoryFileHandler.for("#{__DIR__}/fixtures/file.txt", path: "/help")

    response = request handler, "/file"

    response.status_code.should eq 404
    response.body.should eq "404 Not Found\n"
  end
end

describe HTTP::InMemoryDirectoryHandler do
  it "works" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/html; charset=utf-8"
    response.headers["Location"]?.should eq nil
    response.headers["Allow"]?.should eq nil
    response.body.lines[6].should eq "    Test HTML file!"
  end

  it "works for non-index file" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/other"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/html; charset=utf-8"
    response.body.lines[6].should eq "    Other HTML file!"
  end

  it "works for non-HTML file" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/text.txt"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/plain; charset=utf-8"
    response.body.lines.first.should eq "Test text file!"
  end

  it "respond 404 without extension for non-HTML" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/text"

    response.status_code.should eq 404
    response.body.should eq "404 Not Found\n"
  end

  it "respond 404 with extension for HTML" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/other.html"

    response.status_code.should eq 404
    response.body.should eq "404 Not Found\n"
  end

  it "respond 404 for index HTML full name" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/index"

    response.status_code.should eq 404
    response.body.should eq "404 Not Found\n"
  end

  it "works for second level" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/deeper"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/html; charset=utf-8"
    response.body.lines[6].should eq "    Deeper HTML file!"
  end

  it "works for unknown mime" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/deeper/some.unknown"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "application/octet-stream"
    response.body.lines.first.should eq "Some unknown data"
  end

  it "works for HEAD requests" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/other", method: "HEAD"

    response.status_code.should eq 200
    response.body.should eq ""
  end

  it "respond 404 for unknown path" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/help"

    response.status_code.should eq 404
    response.body.should eq "404 Not Found\n"
  end

  it "respond 301 for slash at end" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/other/"

    response.status_code.should eq 301
    response.headers["Location"].should eq "/other"
    response.body.should eq ""
  end

  it "respond 301 for slash at end for sub folder" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/deeper/"

    response.status_code.should eq 301
    response.headers["Location"].should eq "/deeper"
    response.body.should eq ""
  end

  it "respond 405 for non-GET/HEAD requests" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder")

    response = request handler, "/other", method: "POST"

    response.status_code.should eq 405
    response.headers["Allow"].should eq "GET, HEAD"
    response.body.should eq ""
  end

  it "works with prefix" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder", prefix: "/secret")

    response = request handler, "/secret"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/html; charset=utf-8"
    response.body.lines[6].should eq "    Test HTML file!"
  end

  it "works with prefix for non-index file" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder", prefix: "/secret")

    response = request handler, "/secret/other"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/html; charset=utf-8"
    response.body.lines[6].should eq "    Other HTML file!"
  end

  it "works with prefix for second level" do
    handler = HTTP::InMemoryDirectoryHandler.for("#{__DIR__}/fixtures/folder", prefix: "/secret")

    response = request handler, "/secret/deeper"

    response.status_code.should eq 200
    response.headers["Content-Type"].should eq "text/html; charset=utf-8"
    response.body.lines[6].should eq "    Deeper HTML file!"
  end
end
