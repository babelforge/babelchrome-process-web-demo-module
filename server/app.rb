#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "json"
require "socket"
require "uri"

def argument_value(name)
  index = ARGV.index(name)
  return nil if index.nil?

  ARGV[index + 1]
end

def selected_port
  value = argument_value("--port") || ENV["BABELCHROME_PORT"] || ENV["PORT"]
  Integer(value || "", 10)
rescue ArgumentError
  warn "Missing or invalid --port value"
  exit 64
end

def read_request(client)
  request_line = client.gets&.strip
  headers = {}

  while (line = client.gets)
    line = line.strip
    break if line.empty?

    name, value = line.split(":", 2)
    next if name.nil? || value.nil?

    headers[name.downcase] = value.strip
  end

  [request_line, headers]
end

def write_response(client, status, content_type, body)
  reason = {
    200 => "OK",
    404 => "Not Found",
    405 => "Method Not Allowed"
  }.fetch(status, "OK")

  client.write "HTTP/1.1 #{status} #{reason}\r\n"
  client.write "Content-Type: #{content_type}\r\n"
  client.write "Content-Length: #{body.bytesize}\r\n"
  client.write "Connection: close\r\n"
  client.write "\r\n"
  client.write body
end

def html_page(headers)
  module_id = CGI.escapeHTML(ENV.fetch("BABELCHROME_MODULE_ID", ""))
  module_dir = CGI.escapeHTML(ENV.fetch("BABELCHROME_MODULE_DIR", ""))
  port = CGI.escapeHTML(ENV.fetch("BABELCHROME_PORT", ENV.fetch("PORT", "")))
  source_url = CGI.escapeHTML(headers.fetch("x-babelchrome-source-url", ""))
  route = CGI.escapeHTML(headers.fetch("x-babelchrome-module-route", ""))
  file_types = CGI.escapeHTML(headers.fetch("x-babelchrome-file-types", ""))

  <<~HTML
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>Process Web Demo</title>
      <style>
        :root {
          color-scheme: light dark;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        body {
          margin: 0;
          background: Canvas;
          color: CanvasText;
        }

        main {
          max-width: 780px;
          margin: 48px auto;
          padding: 0 24px;
        }

        h1 {
          margin: 0 0 12px;
          font-size: 30px;
          line-height: 1.2;
        }

        p {
          line-height: 1.55;
        }

        dl {
          display: grid;
          grid-template-columns: max-content 1fr;
          gap: 10px 16px;
          margin-top: 28px;
          padding: 18px;
          border: 1px solid color-mix(in srgb, CanvasText 18%, transparent);
          border-radius: 10px;
          background: color-mix(in srgb, CanvasText 5%, Canvas);
        }

        dt {
          font-weight: 700;
        }

        dd {
          margin: 0;
          overflow-wrap: anywhere;
        }
      </style>
    </head>
    <body>
      <main>
        <h1>Process Web Demo</h1>
        <p>This page was rendered by a module-owned Ruby HTTP process behind a stable BabelChrome route.</p>
        <dl>
          <dt>Module</dt>
          <dd>#{module_id}</dd>
          <dt>Runtime</dt>
          <dd>process-web</dd>
          <dt>Route</dt>
          <dd>#{route}</dd>
          <dt>Assigned port</dt>
          <dd>#{port}</dd>
          <dt>Module directory</dt>
          <dd>#{module_dir}</dd>
          <dt>Source URL</dt>
          <dd>#{source_url}</dd>
          <dt>Advertised file types</dt>
          <dd>#{file_types}</dd>
        </dl>
      </main>
    </body>
    </html>
  HTML
end

def handle_request(client)
  request_line, headers = read_request(client)
  return if request_line.nil? || request_line.empty?

  method, target, = request_line.split(" ")
  uri = URI.parse(target || "/")

  if method != "GET"
    write_response(client, 405, "text/plain; charset=utf-8", "Method not allowed")
    return
  end

  case uri.path
  when "/health"
    body = JSON.generate({ ok: true, runtime: "process-web" })
    write_response(client, 200, "application/json; charset=utf-8", body)
  when "/index", "/"
    write_response(client, 200, "text/html; charset=utf-8", html_page(headers))
  else
    write_response(client, 404, "text/plain; charset=utf-8", "Not found")
  end
rescue StandardError => error
  warn "Request failed: #{error.class}: #{error.message}"
end

server = TCPServer.new("127.0.0.1", selected_port)
trap("TERM") { server.close rescue nil; exit 0 }
trap("INT") { server.close rescue nil; exit 0 }

warn "Process Web Demo listening on 127.0.0.1:#{server.addr[1]}"

loop do
  client = server.accept
  handle_request(client)
ensure
  client&.close
end
