class Hash
  def method_missing(method, *params)
    method_string = method.to_s
    if method_string.last == "="
      self[method_string[0..-2]] = params.first
    else
      self[method_string]
    end
  end
end

module ActiveRecord
  class Base
    class << self

      def find_by_sql_as_hashes(sql)
        connection.select_all(sanitize_sql(sql))
      end

      def find_as_hashes(*args)
        options = args.extract_options!
        if options.include?(:include)
          raise ActiveRecord::StatementInvalid, "find_as_hashes cannot accept :include options!"
        end
        validate_find_options(options)
        set_readonly_option!(options)

        case args.first
        when :first
          find_initial_as_hashes(options)
        when :all
          find_every_as_hashes(options)
        else
          find_from_ids_as_hashes(args, options)
        end
      end

      private

      def find_every_as_hashes(options)
        connection.select_all(construct_finder_sql(options))
      end

      def find_initial_as_hashes(options)
        find_every_as_hashes(options.merge(:limit => 1))
      end


      def find_from_ids_as_hashes(ids, options)
        expects_array = ids.first.kind_of?(Array)
        return ids.first if expects_array && ids.first.empty?

        ids = ids.flatten.compact.uniq

        case ids.size
        when 0
          raise RecordNotFound, "Couldn't find #{name} without an ID"
        when 1
          result = find_one_as_hash(ids.first, options)
          expects_array ? [ result ] : result
        else
          find_some_as_hashes(ids, options)
        end
      end

      def find_one_as_hash(id, options)
        conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
        options.update :conditions => "#{table_name}.#{connection.quote_column_name(primary_key)} = #{quote_value(id,columns_hash[primary_key])}#{conditions}"

        # Use find_every(options).first since the primary key condition
        # already ensures we have a single record. Using find_initial adds
        # a superfluous :limit => 1.
        if result = find_every_as_hashes(options).first
          result
        else
          raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{id}#{conditions}"
        end
      end

      def find_some_as_hashes(ids, options)
        conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
        ids_list   = ids.map { |id| quote_value(id,columns_hash[primary_key]) }.join(',')
        options.update :conditions => "#{table_name}.#{connection.quote_column_name(primary_key)} IN (#{ids_list})#{conditions}"

        result = find_every_as_hashes(options)

        if result.size == ids.size
          result
        else
          raise RecordNotFound, "Couldn't find all #{name.pluralize} with IDs (#{ids_list})#{conditions}"
        end
      end
    end  
  end
end