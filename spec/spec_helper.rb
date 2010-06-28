$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'memcache-lock'
require 'rubygems'
require 'active_support'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  config.mock_with :rr
  config.before :suite do
    config = YAML.load(IO.read((File.expand_path(File.dirname(__FILE__) + "/memcache.yml"))))['test']
    $memcache = ActiveSupport::Cache::MemCacheStore.new(*config['servers'])
    $lock = MemcacheLock.new($memcache)
  end

  config.before :each do
    $memcache.clear
  end  
end
