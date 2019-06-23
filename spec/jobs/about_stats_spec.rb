# frozen_string_literal: true

require 'rails_helper'

describe Jobs::AboutStats do
  it 'caches the stats' do
    begin
      stats = About.fetch_stats.to_json
      cache_key = About.stats_cache_key
      $redis.del(cache_key)

      expect(described_class.new.execute({})).to eq(stats)
      expect($redis.get(cache_key)).to eq(stats)
    ensure
      $redis.del(cache_key)
    end
  end
end
