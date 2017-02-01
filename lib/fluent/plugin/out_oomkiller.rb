class Fluent::OomKillerOutput < Fluent::Output
  Fluent::Plugin.register_output('oomkiller', self)

  include Fluent::HandleTagNameMixin

  def configure(conf)
    super
    @logs = {}
    @is_oomlog = false
  end

  def start
    super
  end

  def shutdown
    super
  end

  def emit(tag, es, chain)
    if !@logs[:"#{tag}"].instance_of?(Array)
      @logs[:"#{tag}"] = []
    end
    chain.next
    es.each {|time, record|
      make_record_block(tag, time, record)
    }
  end

  def make_record_block(tag, time, record)
    if !record.has_key?('message')
      return
    end

    value = record['message']

    if @is_oomlog then
      @logs[:"#{tag}"] << value
    end

    if /invoked oom-killer:/ =~ value then
      @is_oomlog = true
      @logs[:"#{tag}"] << value
    elsif /Killed process/ =~ value then
      @is_oomlog = false
      parse_record_block(record, tag, time)
    end
  end

  REGEX1 = /^(\S+\s+\d+\s\d+:\d+:\d+)\s.+/
  REGEX2 = /Killed process (\d+)\s+\((\S+)\)\s+total-vm:(\d+)kB,\s+anon-rss:(\d+)kB,\s+file-rss:(\d+)kB/

  def parse_record_block(syslog_record, tag, time)
    record = {}

    if syslog_record.has_key?('time') and syslog_record['time'] then
      time = syslog_record['time']
    else
      @logs[:"#{tag}"][0] =~ REGEX1
      if $1 then
        datetime = Time.parse($1)
        time = datetime.to_i if datetime
      end
    end

    @logs[:"#{tag}"][-1] =~ REGEX2
    record['time'] = time
    record['host'] = syslog_record['host']
    record['ident'] = syslog_record['ident']
    record['pid'] = $1.to_i
    record['name'] = $2
    record['total_vm_kb'] = $3.to_i
    record['anon_rss_kb'] = $4.to_i
    record['file_rss_kb'] = $5.to_i

    record['raw'] = @logs[:"#{tag}"].map {|m| m.strip}.join("\n")

    flush_emit(tag, time, record)
  end

  def flush_emit(tag, time, record)
    @logs[:"#{tag}"].clear

    if !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix
      Fluent::Engine.emit(tag, time, record)

    else
      _tag = tag.clone
      filter_record(_tag, time, record)
      if tag != _tag
        Fluent::Engine.emit(_tag, time, record)
      else
        $log.warn "Can not emit message because the tag has not changed. Dropped record #{record}"
      end
    end

  end
end
