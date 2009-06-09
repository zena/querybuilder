require 'rubygems'
require 'ruby-debug'
Debugger.start

module NewQueryBuilder
  class ClauseException < Exception
  end
  
  class Query
    attr_reader :context
    
    class << self
      # class variable
      attr_accessor :main_table
    end
    
    VERSION = '1.0.0'
    OPERATOR_TO_METHOD = {
      :"!" => :not,
      :"@-" => :change_sign, :"@~" => :invert_bits,
      :"^" => :bitwise_xor,
      :* => :times, :/ => :division, :DIV => :integer_division, :% => :modulo, :MOD => :modulo,
      :- => :minus, :+ => :addition,
      :<< => :left_shift, :>> => :right_shift,
      :& => :bitwise_and,
      :| => :bitwise_or,
      :"=" => :equal, :"<=>" => :null_safe_equal, :>= => :greater_or_equal,
      :> => :greater, :<= => :smaller_or_equal, :< => :smaller, :"<>" => :not_equal, :"!=" => :not_equal,
      :IS => :is, :LIKE => :like, :REGEXP => :regexp, :IN => :in,
      :BETWEEN => :between, :CASE => :case, :WHEN => :when, :THEN => :then, :ELSE => :else,
      :NOT => :not,
      :"&&" => :and, :AND => :and,
      :XOR => :xor,
      :"||" => :or, :OR => :or,
      :":=" => :assign,
      :relation => :scoped_relation
    }
    
    def initialize(source)
      @sxp = PseudoSQLParser.parse(source)
      @context = {}
      @tables = []
      @table_counter = {}
      @join_tables   = {}
      @select = []
      @where  = []
      process(@sxp)
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
      return "\"SELECT #{main_table}.* FROM #{main_table} WHERE 0\"" if @tables.empty? # all alternate queries invalid and 'ignore_warnings' set.
      statement, bind_values = build_statement(type)
      bind_values.empty? ? "\"#{statement}\"" : "[#{[["\"#{statement}\""] + bind_values].join(', ')}]"
    end

    protected
      def process(sxp)
        return sxp if sxp.kind_of?(String)
        method = "process_#{OPERATOR_TO_METHOD[sxp.first] || sxp.first}"
        if respond_to?(method)
          self.send(method, *sxp[1..-1])
        else
          process_op(sxp.first, *sxp[1..-1])
        end
      end
      
      def process_query(args)
        if args.empty?
          process([:relation, main_table])
        else
          process(args)
        end
        default_order_clause unless @order
        @select << "#{table}.*"
      end
      
      # Parse sub-query from right to left
      def process_from(query, sub_query)
        @distinct = true
        process(sub_query)
        # reverse order to make conditionals more easy to understand
        sub_where = @where
        @where = []
        process(query)
        @where += sub_where
      end
      
      def process_scoped_relation(relation)
        if relation.kind_of?(String)
          with(:scope => nil) do
            process_relation(relation)
            apply_scope(context[:scope]) if context[:scope]
          end
        else
          process(relation)
        end
      end
      
      def process_scope(relation, scope)
        with(:scope => scope) do
          process_relation(relation)
          apply_scope(scope)
        end
      end
      
      def apply_scope(scope)
        # FIXME: is_last ?
        previous_table_alias = table(main_table,-1)
        if fields = scope_fields(scope, previous_table_alias.nil?)
          @where << "#{field_or_attr(fields[0])} = #{field_or_attr(fields[1], previous_table_alias)}" if fields != []
        else
          @errors << "Invalid scope '#{scope}'."
        end
      end
      
      def field_or_attr(fld_name, table_alias = table)
        if table_alias
          with(:table_alias => table_alias) do
            process_field(fld_name)
          end
        else
          process_attr(fld_name)
        end
      end
      
      def process_field(fld_name)
        raise ClauseException.new("Unknown field '#{fld_name}'.")
      end
      
      def process_attr(fld_name)
        insert_bind(fld_name)
      end
      
      def process_filter(relation, filter)
      end
      
      def process_relation(relation)
        raise ClauseException.new("Unknown relation '#{relation}'.")
      end
      
      def process_op(op, left, right)
        "#{process(left)} #{op} #{process(right)}"
      end
      
      def process_order(*args)
        variables = args
        process(variables.shift)
        @order = " ORDER BY #{variables.map {|var| process(var)}.join(', ')}"
      end
      
      def process_asc(field)
        "#{process(field)} ASC"
      end
      
      def process_desc(field)
        "#{process(field)} DESC"
      end
      
      def insert_bind(str)
        "[[#{str}]]"
      end
      
      def default_order_clause
      end
    
    private
      def main_table
        self.class.main_table
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

      def table(table_name = nil, index = 0)
        if table_name.nil?
          context[:table_alias] || table_at(main_table, table_counter(main_table) + index)
        else
          table_at(table_name, table_counter(table_name) + index)
        end
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

      def with(hash)
        context_bak = @context
        res = ''
        @context = @context.merge(hash)
        res = yield
        @context = context_bak
        res
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
          group = @tables.size > 1 ? " GROUP BY #{table}.id" : " GROUP BY id"
        end


        "SELECT #{@select.join(',')} FROM #{table_list.flatten.join(',')}" + (@where == [] ? '' : " WHERE #{@where.join(' AND ')}") + group.to_s + @order.to_s + @limit.to_s + @offset.to_s
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