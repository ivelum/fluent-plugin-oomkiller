require 'helper'

class OomKillerOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG1 = %[
  ]
  CONFIG2 = %[
    add_tag_prefix oomkiller.
  ]

  def create_driver(conf=%[], tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::OomKillerOutput, tag).configure(conf)
  end

  def test_configure_nil
    d = create_driver(CONFIG1, 'myapp.test1')
    assert_equal nil, d.instance.add_tag_prefix
  end

  def test_configure_set_config
    d = create_driver(CONFIG2, 'myapp.test2')
    assert_equal 'oomkiller.', d.instance.add_tag_prefix
  end

  def test_emit_nil
    current_year = Time.now.year
    d = create_driver(CONFIG1, 'myapp.test3')
    d.run do
      IO.foreach(File.join(File.dirname(__FILE__), "..", "testdata", "message1")) do |s|
        d.emit("message" => s)
      end
      IO.foreach(File.join(File.dirname(__FILE__), "..", "testdata", "message2")) do |s|
        d.emit("message" => s)
      end
      IO.foreach(File.join(File.dirname(__FILE__), "..", "testdata", "message3")) do |s|
        d.emit("message" => s)
      end
      IO.foreach(File.join(File.dirname(__FILE__), "..", "testdata", "message4")) do |s|
        d.emit("message" => s)
      end
    end
    assert_equal 2, d.emits.size

    assert_equal 'myapp.test3', d.emits[0][0]
    d.emits[0][2].delete("time")
    d.emits[0][2].delete("message")
    assert_equal({
      "pid" => 13550,
      "name" => "java",
      "total_vm_kb" => 12466024,
      "anon_rss_kb" => 7625016,
      "file_rss_kb" => 2608,
      "raw" => File.read(File.join(File.dirname(__FILE__), "..", "testdata", "message2"))
    }, d.emits[0][2])

    assert_equal 'myapp.test3', d.emits[1][0]
    d.emits[1][2].delete("time")
    d.emits[1][2].delete("message")
    assert_equal({
      "pid" => 18938,
      "name" => "java",
      "total_vm_kb" => 12482944,
      "anon_rss_kb" => 7678888,
      "file_rss_kb" => 744,
      "raw" => File.read(File.join(File.dirname(__FILE__), "..", "testdata", "message4"))
    }, d.emits[1][2])
  end

  def test_emit_set_config
    current_year = Time.now.year
    d = create_driver(CONFIG2, 'myapp.test4')
    d.run do
      IO.foreach(File.join(File.dirname(__FILE__), "..", "testdata", "message1")) do |s|
        d.emit("message" => s)
      end
      IO.foreach(File.join(File.dirname(__FILE__), "..", "testdata", "message2")) do |s|
        d.emit("message" => s)
      end
      IO.foreach(File.join(File.dirname(__FILE__), "..", "testdata", "message3")) do |s|
        d.emit("message" => s)
      end
      IO.foreach(File.join(File.dirname(__FILE__), "..", "testdata", "message4")) do |s|
        d.emit("message" => s)
      end
    end
    assert_equal 2, d.emits.size

    assert_equal 'oomkiller.myapp.test4', d.emits[0][0]
    d.emits[0][2].delete("time")
    d.emits[0][2].delete("message")
    assert_equal({
      "pid" => 13550,
      "name" => "java",
      "total_vm_kb" => 12466024,
      "anon_rss_kb" => 7625016,
      "file_rss_kb" => 2608,
      "raw" => File.read(File.join(File.dirname(__FILE__), "..", "testdata", "message2"))
    }, d.emits[0][2])

    assert_equal 'oomkiller.myapp.test4', d.emits[1][0]
    d.emits[1][2].delete("time")
    d.emits[1][2].delete("message")
    assert_equal({
      "pid" => 18938,
      "name" => "java",
      "total_vm_kb" => 12482944,
      "anon_rss_kb" => 7678888,
      "file_rss_kb" => 744,
      "raw" => File.read(File.join(File.dirname(__FILE__), "..", "testdata", "message4"))
    }, d.emits[1][2])
  end

end
