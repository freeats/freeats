# frozen_string_literal: true

class BaseQueries
  FILES_PATH = "app/queries"
  VARIABLE_PATTERN = "(?<!:)<prefix>\\w+\\b"
  PREFIX_PATTERN = /^-- prefix: (.+)$/
  DEFAULT_PREFIX = ":"

  DATE_RANGE_TYPES = [Date, DateTime, ActiveSupport::TimeWithZone, NilClass].freeze

  class Argument # rubocop:disable Style/ClassAndModuleChildren
    # Provides arguments in a form of VALUES:
    # Values.new([1,2,3]).to_sql(2) #=> { sql: "VALUES (($2),($3),($4))", binds: [1,2,3] }
    class Values
      include Dry::Initializer.define -> do
        param :values, Types::Array
      end

      def to_sql(idx)
        sql =
          values
          .map.with_index(idx) { |_, i| "($#{i})" }
          .join(", ")
          .then { "VALUES #{_1}" }
        { sql:, binds: values }
      end
    end
  end

  class << self
    def location_search_by_name(name, types:, limit:)
      query_name = "location_search_by_name"
      parameters = { types:, name:, limit: }
      sql = extract_query(query_name)
      sql, binds = inject_variables(sql, parameters)

      connection.exec_query(sql, query_name, binds).map do |attributes|
        location = into_active_record_model(attributes.except("aliases"), Location)
        location.define_singleton_method(:aliases) do
          attributes["aliases"].remove("{").remove("}").split(",")
        end
        location
      end
    end

    def last_messages_of_each_thread(email_thread_ids:, per_page: 25, page: 1, includes: {})
      return { records: [], total_count: 0 } if email_thread_ids.blank?

      parameters = { thread_ids: Array(email_thread_ids), per_page:, page: }
      sql = extract_query("last_messages_of_each_thread")
      sql, binds = inject_variables(sql, parameters)

      records = EmailMessage.find_by_sql(sql, binds)
      ActiveRecord::Associations::Preloader.new(records:, associations: includes).call

      total_count = email_thread_ids.size

      { records:, total_count: }
    end

    private

    def inject_variables(sql, parameters)
      prefix = extract_prefix(sql)
      variables = extract_variables(sql, prefix)
      raise ArgumentError, <<~ERROR if variables.sort != parameters.keys.sort
        Variables in SQL: #{variables.sort} are not the same as provided \
        in parameters: #{parameters.keys.sort}
      ERROR

      parameters.reduce([sql, []]) do |acc, name_value|
        sql, binds = acc
        name, value = name_value
        case value
        when Argument::Values
          inject_values_variable(sql, binds, name, value, prefix)
        when Array
          inject_array_variable(sql, binds, name, value, prefix)
        else
          inject_single_variable(sql, binds, name, value, prefix)
        end
      end
    end

    def inject_single_variable(sql, binds, name, value, prefix)
      binds_index = binds.size + 1
      [sql.gsub("#{prefix}#{name}", "$#{binds_index}"), binds.push(value)]
    end

    def inject_array_variable(sql, binds, name, values, prefix)
      binds_index = binds.size + 1
      placeholders =
        (binds_index...binds_index + values.size)
        .map { |idx| "$#{idx}" }
        .join(", ")
      [sql.gsub("#{prefix}#{name}", placeholders), binds.push(*values)]
    end

    def inject_values_variable(sql, binds, name, value, prefix)
      value.to_sql(binds.size + 1) => { sql: value_sql, binds: value_binds }
      [sql.gsub("#{prefix}#{name}", value_sql), binds.push(*value_binds)]
    end

    def into_active_record_model(attributes, klass)
      object = klass.new
      object.assign_attributes(attributes)
      object.instance_variable_set(:@new_record, false)
      object
    end

    # Get contents of the query given the name of the query.
    def extract_query(query_name)
      File
        .read(file_path("#{query_name}.sql"))
        .gsub(/--.*?$/, "")
    end

    # Get variables used in the sql query.
    def extract_variables(sql, prefix)
      sql
        .scan(Regexp.new(VARIABLE_PATTERN.sub("<prefix>", prefix)))
        .map { _1.delete_prefix(prefix).to_sym }
        .uniq
    end

    def extract_prefix(sql)
      sql.scan(PREFIX_PATTERN).flatten.first || DEFAULT_PREFIX
    end

    def file_path(file_name)
      Rails.root.join(FILES_PATH, file_name)
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
