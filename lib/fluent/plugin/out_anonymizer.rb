require 'fluent/mixin/rewrite_tag_name'

class Fluent::AnonymizerOutput < Fluent::Output
  Fluent::Plugin.register_output('anonymizer', self)

  # To support log_level option since Fluentd v0.10.43
  unless method_defined?(:log)
    define_method(:log) { $log }
  end

  config_param :tag, :string, :default => nil
  config_param :hash_salt, :string, :default => ''
  config_param :ipv4_mask_subnet, :integer, :default => 24
  config_param :ipv6_mask_subnet, :integer, :default => 104

  include Fluent::HandleTagNameMixin
  include Fluent::Mixin::RewriteTagName
  include Fluent::SetTagKeyMixin
  config_set_default :include_tag_key, false

  def initialize
    require 'fluent/plugin/anonymizer'
    super
  end

  def configure(conf)
    super
    @anonymizer = Fluent::Anonymizer.new(self, conf)
  end

  def emit(tag, es, chain)
    es.each do |time, record|
      record = @anonymizer.anonymize(record)
      emit_tag = tag.dup
      filter_record(emit_tag, time, record)
      router.emit(emit_tag, time, record)
    end
    chain.next
  end
end
