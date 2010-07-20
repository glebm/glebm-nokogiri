require "helper"

module Nokogiri
  module XML
    class TestXPath < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)

        @handler = Class.new {
          attr_reader :things

          def initialize
            @things = []
          end

          def thing thing
            @things << thing
            thing
          end

          def returns_array node_set
            @things << node_set.to_a
            node_set.to_a
          end

          def my_filter set, attribute, value
            set.find_all { |x| x[attribute] == value }
          end

          def saves_node_set node_set
            @things = node_set
          end
        }.new
      end

      def test_unknown_attribute
        assert_equal 0, @xml.xpath('//employee[@id="asdfasdf"]/@fooo').length
        assert_nil @xml.xpath('//employee[@id="asdfasdf"]/@fooo')[0]
      end

      def test_boolean
        assert_equal false, @xml.xpath('1 = 2')
      end

      def test_number
        assert_equal 2, @xml.xpath('1 + 1')
      end

      def test_string
        assert_equal 'foo', @xml.xpath('concat("fo", "o")')
      end

      def test_css_search_uses_custom_selectors_with_arguments
        set = @xml.css('employee > address:my_filter("domestic", "Yes")', @handler)
        assert set.length > 0
        set.each do |node|
          assert_equal 'Yes', node['domestic']
        end
      end

      def test_css_search_uses_custom_selectors
        set = @xml.xpath('//employee')
        css_set = @xml.css('employee:thing()', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_pass_self_to_function
        set = @xml.xpath('//employee/address[my_filter(., "domestic", "Yes")]', @handler)
        assert set.length > 0
        set.each do |node|
          assert_equal 'Yes', node['domestic']
        end
      end

      def test_custom_xpath_function_gets_strings
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[thing("asdf")]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(['asdf'] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_true_booleans
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[thing(true())]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([true] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_false_booleans
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[thing(false())]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([false] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_numbers
        set = @xml.xpath('//employee')
        @xml.xpath('//employee[thing(10)]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([10] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_node_sets
        set = @xml.xpath('//employee/name')
        @xml.xpath('//employee[thing(name)]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_custom_xpath_gets_node_sets_and_returns_array
        set = @xml.xpath('//employee/name')
        @xml.xpath('//employee[returns_array(name)]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_custom_xpath_handler_is_passed_a_decorated_node_set
        x = Module.new do
          def awesome! ; end
        end
        util_decorate(@xml, x)
        set = @xml.xpath('//employee/name')
        @xml.xpath('//employee[saves_node_set(name)]', @handler)
        assert_equal @xml, @handler.things.document
        assert @handler.things.respond_to?(:awesome!)
      end

      def test_code_that_invokes_OP_RESET_inside_libxml2
        doc = "<html><body id='foo'><foo>hi</foo></body></html>"
        xpath = 'id("foo")//foo'
        nokogiri = Nokogiri::HTML.parse(doc)
        tree = nokogiri.xpath(xpath)
      end
    end
  end
end
