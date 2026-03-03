class ArchiveJob
  include Sidekiq::Job
  sidekiq_options queue: 'low', retry: false

  RAW_RETENTION_DAYS = 90
  HOURLY_RETENTION_MONTHS = 36
  PLC_WRITE_LOG_RETENTION_DAYS = 90
  BATCH_SIZE = 10_000

  def perform
    archive_raw_values
    archive_hourly_aggregations
    archive_plc_write_log
    archive_weather_station_api_raw_values
    archive_weather_station_api_hourly_aggregations
  end

  private
    def archive_raw_values
      cutoff = RAW_RETENTION_DAYS.days.ago

      loop do
        moved = archive_batch(
          source: 'raw_values',
          target: 'archived_raw_values',
          condition: "sample_time < '#{cutoff.to_fs(:db)}'",
        )
        if moved < BATCH_SIZE
          break
        end
      end
    end

    def archive_hourly_aggregations
      cutoff = HOURLY_RETENTION_MONTHS.months.ago.to_date

      loop do
        moved = archive_batch(
          source: 'hourly_aggregations',
          target: 'archived_hourly_aggregations',
          condition: "date < '#{cutoff}'",
        )
        if moved < BATCH_SIZE
          break
        end
      end
    end

    def archive_plc_write_log
      cutoff = PLC_WRITE_LOG_RETENTION_DAYS.days.ago

      loop do
        moved = archive_batch(
          source: 'plc_write_logs',
          target: 'archived_plc_write_logs',
          condition: "created_at < '#{cutoff}'",
        )
        if moved < BATCH_SIZE
          break
        end
      end
    end

    def archive_weather_station_api_raw_values
      cutoff = RAW_RETENTION_DAYS.days.ago

      loop do
        moved = archive_batch(
          source: 'weather_station_api_raw_values',
          target: 'archived_weather_station_api_raw_values',
          condition: "sample_time < '#{cutoff.to_fs(:db)}'",
        )
        if moved < BATCH_SIZE
          break
        end
      end
    end

    def archive_weather_station_api_hourly_aggregations
      cutoff = HOURLY_RETENTION_MONTHS.months.ago.to_date

      loop do
        moved = archive_batch(
          source: 'weather_station_api_hourly_aggregations',
          target: 'archived_weather_station_api_hourly_aggregations',
          condition: "date < '#{cutoff}'",
        )
        if moved < BATCH_SIZE
          break
        end
      end
    end

    def archive_batch(source:, target:, condition:)
      columns = ActiveRecord::Base.connection.columns(source).map(&:name).join(', ')

      count = ActiveRecord::Base.connection.select_value(
        "SELECT COUNT(*) FROM #{source} WHERE #{condition} LIMIT #{BATCH_SIZE}"
      ).to_i

      if count == 0
        return 0
      end

      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute(<<-SQL)
          INSERT INTO #{target} (#{columns}, archived_at)
          SELECT #{columns}, NOW()
          FROM #{source}
          WHERE #{condition}
          LIMIT #{BATCH_SIZE}
        SQL

        ActiveRecord::Base.connection.execute(<<-SQL)
          DELETE FROM #{source}
          WHERE #{condition}
          LIMIT #{BATCH_SIZE}
        SQL
      end

      count
    end
end
