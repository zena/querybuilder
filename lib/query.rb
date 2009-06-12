module QueryBuilder  
  class Query
    attr_accessor :processor_class, :distinct, :select, :tables, :where, :limit, :offset, :page_size, :order, :group, :error
    def initialize(processor_class)
      @processor_class = processor_class
      @tables = []
      @table_counter = {}
      @join_tables   = {}
      @select  = []
      @where   = []
    end
    
    def main_table
      @processor_class.main_table
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
    
    def table_counter(table_name)
      @table_counter[table_name] || 0
    end

    def table_at(table_name, index)
      if index < 0
        return nil # no table at this address
      end
      index == 0 ? table_name : "#{table_name[0..1]}#{index}"
    end

    def add_table(use_name, table_name = nil)
      table_name ||= use_name
      if !@table_counter[use_name]
        @table_counter[use_name] = 0
        if use_name != table_name
          @tables << "#{table_name} as #{use_name}"
        else
          @tables << table_name
        end
      else  
        @table_counter[use_name] += 1
        @tables << "#{table_name} AS #{table(use_name)}"
      end
    end
    
    def table(table_name = main_table, index = 0)
      table_at(table_name, table_counter(table_name) + index)
    end
    
    private
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


        "SELECT #{(["#{main_table}.*"]+@select).join(',')} FROM #{table_list.flatten.join(',')}" + (@where == [] ? '' : " WHERE #{@where.join(' AND ')}") + group.to_s + @order.to_s + @limit.to_s + @offset.to_s
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

        "SELECT #{count_on} FROM #{table_list.flatten.join(',')}" + (@where == [] ? '' : " WHERE #{@where.join(' AND ')}")
      end
  end
end