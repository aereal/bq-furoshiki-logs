#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'time'

DELIMITER = "---\n"
LOGS_DIR = File.expand_path('~/.furo2/logs')
DEST_DIR = File.expand_path('./logs')
THRESHOLD_SIZE = 1024 * 1024 * 10 # 10MiB

def parse_file_name(filename)
  name = filename.sub(LOGS_DIR + '/', '')
  site, owner, repo, rest = *name.split('/', 4)
  t = Time.strptime(rest, '%Y/%m/%d/%H%M%S.%L.log')
  id = [site, owner, repo].join('-')
  { id: id, time: t }
end

def parse_log_file(log_file)
  seen_delimiter = false
  out = ''
  raw_opts = ''
  opts = {}
  open(log_file).each_line do |line|
    if line == DELIMITER
      seen_delimiter = true
      opts = YAML.load(raw_opts)
      next
    end
    if seen_delimiter
      out += line
    else
      raw_opts += line
    end
  end
  opts.merge('output' => normalize_utf8(out))
end

def flush_json_log(body, dest_file)
  warn "---> Write to #{dest_file}"
  open(dest_file, 'a') do |f|
    f.puts(JSON.generate(body))
  end
end

def normalize_utf8(str)
  str.encode('UTF-16', invalid: :replace, replace: '').encode('UTF-8')
end

def process_files(files, offset = 0)
  index = {}
  buf = ''
  unflushed_id = nil

  flush = ->(id) do
    dest_file = File.join(DEST_DIR, id) + "_#{index[id]}" + ".jsonl"
    warn "---> Write to #{dest_file}"
    open(dest_file, 'a') do |f|
      f << buf
    end
    buf = ''
  end

  files.each do |log_file|
    attrs = parse_file_name(log_file)
    parsed = parse_log_file(log_file)
    parsed['executedAt'] = attrs[:time]
    name = log_file.sub(LOGS_DIR + '/', '')
    site, owner, repo, _ = *name.split('/', 4)
    id = [site, owner, repo].join('-')
    unflushed_id = id
    index[id] ||= offset 
    warn "---> Process #{log_file} index=#{index[id]}"
    buf += JSON.generate(parsed) + "\n"
    current_size = buf.bytesize
    if current_size >= THRESHOLD_SIZE
      flush.call(id)
      index[id] += 1
      unflushed_id = nil
    end
  end

  if !buf.empty? && !unflushed_id.nil?
    flush.call(unflushed_id)
  end
end

process_files(Dir.glob("#{LOGS_DIR}/**/*.log"))
# rest_files = %w(
#   /Users/aereal/.furo2/logs/github.com/hatena/blog-team/2020/06/22/184622.322262.log
#   /Users/aereal/.furo2/logs/github.com/hatena/blog-team/2020/06/25/151424.107960.log
#   /Users/aereal/.furo2/logs/github.com/hatena/blog-team/2020/06/25/145738.512099.log
#   /Users/aereal/.furo2/logs/github.com/hatena/blog-team/2020/06/25/160544.578614.log
# )
# 
# process_files(rest_files, 1)
