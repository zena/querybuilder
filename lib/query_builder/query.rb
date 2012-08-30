require 'active_record'

module QueryBuilder
  class Query
    SELECT_WITH_TYPE_REGEX = /^(.*):(.*)$/
    attr_accessor :processor_class, :distinct, :select, :tables, :table_alias, :where,
                  :limit, :offset, :page_size, :order, :group, :error, :attributes_alias,
                  :pagination_key, :main_class, :context, :key_value_tables, :having, :types

    class << self
      def adapter
        @adapter ||= ActiveRecord::Base.connection.class.name.split('::').last[/(.+)Adapter/,1].downcase
      end
    end

    def initialize(processor_class)
      @processor_class = processor_class
      @tables = []
      @table_alias = {}
      @join_tables = {}
      @needed_join_tables = {}
      @attributes_alias   = {}
      # Custom select foo as bar:time or 'types:' field in custom query.
      @types              = {}
      @key_value_tables   = {}
      @where = []
    end

    def main_table
      # @main_table is only used in custom queries
      @main_table || processor_class.main_table
    end

    # Return the class of resulting objects (different from default_class if
    # the value has been changed by the query building process).
    def main_class
      @main_class || default_class
    end

    def master_class(after_class = ActiveRecord::Base)
      klass = main_class
      klass = klass.first if klass.kind_of?(Array)
      begin
        up = klass.superclass
        return klass if up == after_class
      end while klass = up
      return main_class
    end

    # Return the default class of resulting objects (usually the base class).
    def default_class
      @default_class ||= begin
        klass = @processor_class.main_class
        QueryBuilder.resolve_const(klass)
      end
    end

    def add_filter(filter)
      @where << filter
    end

    # Return all explicit selected keys
    # For example, sql such as "SELECT form.*, MAX(form.date) AS last_date" would provice 'last_date' key.
    def select_keys
      @select_keys ||= begin
        keys = @attributes_alias.keys.compact
        # When rebuilding select_keys, we rebuild @types
        keys.each do |k|
          # Default type is string
          @types[k] ||= :string
        end
        keys
      end
    end

    # Convert query object to a string. This string should then be evaluated.
    #
    # ==== Parameters
    # type<Symbol>:: Type of query to build (:find or :count).
    #
    # ==== Returns
    # NilClass:: If the query is not valid and "ignore_warnings" was not set to true during initialize.
    # String::   A string representing the query with its bind parameters.
    #
    # ==== Examples
    # query.to_s
    # => "[%Q{SELECT objects.* FROM objects WHERE objects.project_id = ?}, project_id]"
    #
    # DummyQuery.new("nodes in site").to_s
    # => "%Q{SELECT objects.* FROM objects}"
    #
    # query.to_s(:count)
    # => "[%Q{SELECT COUNT(*) FROM objects WHERE objects.project_id = ?}, project_id]"
    def to_s(type = :find)
      statement, bind_values = build_statement(type)
      bind_values.empty? ? "%Q{#{statement}}" : "[#{[["%Q{#{statement}}"] + bind_values].join(', ')}]"
    end

    # Convert the query object into an SQL query.
    #
    # ==== Parameters
    # bindings<Binding>:: Binding context in which to evaluate bind clauses (query arguments).
    # type<Symbol>::      Type of SQL query (:find or :count)
    #
    # ==== Returns
    # NilClass:: If the query is not valid and "ignore_warnings" was not set to true during initialize.
    # String::   An SQL query, ready for execution (no more bind variables).
    #
    # ==== Examples
    # query.sql(binding)
    # => "SELECT objects.* FROM objects WHERE objects.project_id = 12489"
    #
    # query.sql(bindings, :count)
    # => "SELECT COUNT(*) FROM objects WHERE objects.project_id = 12489"
    def sql(bindings, type = :find)
      statement, bind_values = build_statement(type)
      statement.gsub('?') { eval_bound_value(bind_values.shift, connection, bindings) }
    end

    # 'avoid_alias' is used when parsing the last element so that it takes the real table name (nodes, not no1). We need
    # this because we can use 'OR' between parts and we thus need the same table reference.
    def add_table(use_name, table_name = nil, avoid_alias = true)
      alias_name = get_alias(use_name, table_name, avoid_alias)
      add_alias_to_tables(table_name || use_name, alias_name)
    end

    # Add a table to 'import' a key/value based field. This method ensures that
    # a given field is only included once for each context.
    def add_key_value_table(use_name, index_table, key, &block)
      key_tables = (@key_value_tables[table] ||= {})
      key_table = (key_tables[use_name] ||= {})
      if alias_table = key_table[key]
        # done, the index_table has been used for the given key in the current context
      else
        # insert the new table
        add_table(use_name, index_table, false)
        alias_table = key_table[key] = table(use_name)
        # Let caller configure the filter (join).
        block.call(alias_table)
      end
      alias_table
    end

    def add_select(field, fname)
      if fname =~ SELECT_WITH_TYPE_REGEX
        fname, type = $1, $2
        @types[fname] = type.to_sym
      end
      @select ||= ["#{main_table}.*"]
      @select << "#{field} AS #{quote_column_name(fname)}"
      @attributes_alias[fname] = field
    end

    def table(table_name = main_table, index = 0)
      @table_alias[table_name] ? @table_alias[table_name][index - 1] : nil
    end

    # Use this method to add a join to another table (added only once for each join name).
    # nodes JOIN idx_nodes_string AS id1 ON ...
    # FIXME: can we remove this ? It seems buggy (JOIN in or clauses)
    def needs_join_table(table_name1, type, table_name2, clause, join_name = nil)
      join_name ||= "#{table_name1}=#{type}=#{table_name2}"
      @needed_join_tables[join_name] ||= {}
      @needed_join_tables[join_name][table] ||= begin
        # define join for this part ('table' = unique for each part)

        # don't add to list of tables, just get unique alias name
        second_table = get_alias(table_name2)

        # create join
        first_table = table(table_name1)

        @join_tables[first_table] ||= []
        @join_tables[first_table] << "#{type} JOIN #{second_table} ON #{clause.gsub('TABLE1',first_table).gsub('TABLE2',second_table)}"
        second_table
      end
    end

    # Duplicate query, avoiding sharing some arrays and hash
    def dup
      other = super
      %w{tables table_alias where tables key_value_tables}.each do |k|
        other.send("#{k}=", other.send(k).dup)
      end
      other
    end

    # Used after setting @tables from custom query.
    def rebuild_tables!
      @table_alias = {}
      @tables.each do |t|
        if t =~ /\A(.+)\s+AS\s+(.+)\Z/
          base, use_name = $1, $2
        else
          base = use_name = t
        end
        @table_alias[base] ||= []
        @table_alias[base] << use_name
      end
    end

    def rebuild_attributes_hash!
      @attributes_alias = {}
      (@select || []).each do |field|
        if field =~ %r{\A(.*)\s+AS\s+(.+)\Z}i
          key, value = $2, $1
          if key =~ /('|"|`)(.*)\1/
            # TODO: is this clean enough unquoting ?
            key = $2
          end
          @attributes_alias[key] = value
        elsif field =~ %r{^(\w+\.|)([^\*]+)$}
          @attributes_alias[$2] = field
        end
      end
      # Force rebuild
      @select_keys = nil
    end


    def filter
      @where.reverse.join(' AND ')
    end

    def quote_column_name(name)
      connection.quote_column_name(name)
    end

    private
      # Make sure each used table gets a unique name
      def get_alias(use_name, table_name = nil, avoid_alias = true)
        table_name ||= use_name
        @table_alias[use_name] ||= []
        if avoid_alias && !@tables.include?(table_name)
          alias_name = use_name
        elsif @tables.include?(use_name)
          # links, li1, li2, li3
          alias_name = "#{use_name[0..1]}#{@table_alias[use_name].size}"
        else
          # ob1, obj2, objects
          alias_name = "#{use_name[0..1]}#{@table_alias[use_name].size + 1}"
        end

        @table_alias[use_name] << alias_name
        alias_name
      end

      def add_alias_to_tables(table_name, alias_name)
        if alias_name != table_name
          @tables << "#{table_name} AS #{alias_name}"
        else
          @tables << table_name
        end
      end

      def build_statement(type = :find)
        statement = type == :find ? find_statement : count_statement

        # get bind variables
        bind_values = []
        statement.gsub!(/\[\[(.*?)\]\](?!\])/) do
          bind_values << $1
          '?'
        end
        [statement, bind_values]
      end

      def find_statement
        table_list = []
        @tables.each do |t|
          table_name = t.split(/\s+/).last # objects AS ob1
          if joins = @join_tables[table_name]
            table_list << "#{t} #{joins.join(' ')}"
          else
            table_list << t
          end
        end

        group = @group
        if !group && @distinct
          key =  @tables.size > 1 ? "#{main_table}.id" : 'id'

          case self.class.adapter
          when 'postgresql'
            if @order.to_s =~ /ORDER BY (.*)/
              keys = $1.split(',').map {|k| k[/^(.*)\s/,1]}
              key = ([key] + keys).join(',')
            end
            distinct = " DISTINCT ON (#{key})"
          else
            group    = " GROUP BY #{key}"
          end
        end

        "SELECT#{distinct} #{(@select || ["#{main_table}.*"]).join(',')} FROM #{table_list.flatten.sort.join(',')}" + (@where == [] ? '' : " WHERE #{filter}") + group.to_s + @having.to_s + @order.to_s + @limit.to_s + @offset.to_s
      end

      def count_statement
        table_list = []
        @tables.each do |t|
          table_name = t.split(/\s+/).last # objects AS ob1
          if joins = @join_tables[table_name]
            table_list << "#{t} #{joins.join(' ')}"
          else
            table_list << t
          end
        end

        if @group =~ /GROUP\s+BY\s+(.+)/
          # we need to COALESCE in order to count groups where $1 is NULL.
          fields = $1.split(",").map{|f| "COALESCE(#{f.strip},0)"}.join(",")
          count_on = "COUNT(DISTINCT #{fields})"
        elsif @distinct
          count_on = "COUNT(DISTINCT #{table}.id)"
        else
          count_on = "COUNT(*)"
        end

        "SELECT #{count_on} FROM #{table_list.flatten.sort.join(',')}" + (@where == [] ? '' : " WHERE #{filter}")
      end

      def get_connection
        eval("#{default_class}.connection")
      end

      # Adapted from Rail's ActiveRecord code. We need "eval" because
      # QueryBuilder is a compiler and it has absolutely no knowledge
      # of the running context.
      def eval_bound_value(value_as_string, connection, bindings)
        value = eval(value_as_string, bindings)
        if value.respond_to?(:map) && !value.kind_of?(String) #!value.acts_like?(:string)
          if value.respond_to?(:empty?) && value.empty?
            connection.quote(nil)
          else
            value.map { |v| connection.quote(v) }.join(',')
          end
        else
          connection.quote(value)
        end
      end

      def connection
        @connection ||= get_connection
      end
  end
end
