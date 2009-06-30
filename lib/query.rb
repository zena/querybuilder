module QueryBuilder  
  class Query
    attr_accessor :processor_class, :distinct, :select, :tables, :table_alias, :where, :limit, :offset, :page_size, :order, :group, :error, :attributes_alias
    def initialize(processor_class)
      @processor_class = processor_class
      @tables = []
      @table_alias = {}
      @join_tables   = {}
      @needed_join_tables = {}
      @attributes_alias   = {}
      @where   = []
    end
    
    def main_table
      # @main_table is only used in custom queries
      @main_table || processor_class.main_table
    end
    
    def main_class
      klass = @processor_class.main_class
      klass.kind_of?(String) ? Module.const_get(klass) : klass
    end
    
    def add_filter(filter)
      @where << filter
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
    # => "[\"SELECT objects.* FROM objects WHERE objects.project_id = ?\", project_id]"
    #
    # DummyQuery.new("nodes in site").to_s
    # => "\"SELECT objects.* FROM objects\""
    #
    # query.to_s(:count)
    # => "[\"SELECT COUNT(*) FROM objects WHERE objects.project_id = ?\", project_id]"
    def to_s(type = :find)
      statement, bind_values = build_statement(type)
      bind_values.empty? ? "\"#{statement}\"" : "[#{[["\"#{statement}\""] + bind_values].join(', ')}]"
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
      connection = get_connection(bindings)
      statement.gsub('?') { eval_bound_value(bind_values.shift, connection, bindings) }
    end

    # 'avoid_alias' is used when parsing the last element so that it takes the real table name (nodes, not no1). We need
    # this because we can use 'OR' between parts and we thus need the same table reference.
    def add_table(use_name, table_name = nil, avoid_alias = true)
      alias_name = get_alias(use_name, table_name, avoid_alias)
      add_alias_to_tables(table_name || use_name, alias_name)
    end
    
    def add_select(clause)
      @select ||= []
      @select << clause
      rebuild_attributes_hash!
    end
    
    def table(table_name = main_table, index = 0)
      @table_alias[table_name] ? @table_alias[table_name][index - 1] : nil
    end
    
    # Use this method to add a join to another table (added only once for each join name).
    # versions LEFT JOIN dyn_attributes ON ...
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
      @select.each do |attribute|
        if attribute =~ /\A(.+)\s+AS\s+(.+)\Z/
          @attributes_alias[$2] = $1
        end
      end
    end
    
    private
      # Make sure each used table gets a unique name
      def get_alias(use_name, table_name = nil, avoid_alias = true)
        table_name ||= use_name
        @table_alias[use_name] ||= []
        if avoid_alias && !@tables.include?(use_name)
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
        statement.gsub!(/\[\[(.*?)\]\]/) do
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
          group = @tables.size > 1 ? " GROUP BY #{main_table}.id" : " GROUP BY id"
        end
        
        "SELECT #{(@select || ["#{main_table}.*"]).join(',')} FROM #{table_list.flatten.sort.join(',')}" + (@where == [] ? '' : " WHERE #{@where.reverse.join(' AND ')}") + group.to_s + @order.to_s + @limit.to_s + @offset.to_s
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

        "SELECT #{count_on} FROM #{table_list.flatten.sort.join(',')}" + (@where == [] ? '' : " WHERE #{@where.reverse.join(' AND ')}")
      end
      
      def get_connection(bindings)
        eval "#{main_class}.connection", bindings
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
  end
end