class MemcacheLock
  class Error < RuntimeError; end

  DEFAULT_RETRY = 5
  DEFAULT_EXPIRY = 30

  def initialize(cache)
    @cache = cache
  end

  def synchronize(key, lock_expiry = DEFAULT_EXPIRY, retries = DEFAULT_RETRY)
    if recursive_lock?(key)
      yield
    else
      acquire_lock(key, lock_expiry, retries)
      begin
        yield
      ensure
        release_lock(key)
      end
    end
  end

  def acquire_lock(key, lock_expiry = DEFAULT_EXPIRY, retries = DEFAULT_RETRY)
    retries.times do |count|
      begin
        response = @cache.write("lock/#{key}", Process.pid, :expires_in => lock_expiry, :unless_exist => true)
        return if response
        raise Error if count == retries - 1
      end
      exponential_sleep(count) unless count == retries - 1
    end
    raise Error, "Couldn't acquire memcache lock for: #{key}"
  end

  def release_lock(key)
    @cache.delete("lock/#{key}")
  end

  def exponential_sleep(count)
    @runtime += Benchmark::measure { sleep((2**count) / 2.0) }
  end

  private
  def recursive_lock?(key)
    @cache.read("lock/#{key}") == Process.pid
  end
end

