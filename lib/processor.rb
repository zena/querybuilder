
module QueryBuilder
  class Processor
    attr_reader :context, :query, :sxp, :ancestor
    
    class << self
      # class variable
      attr_accessor :main_table, :main_class
    end
    
    VERSION = '1.0.0'
    OPERATOR_TO_METHOD = {
      :"!" => :not,
      :"@-" => :change_sign, :"@~" => :invert_bits,
      :"^" => :bitwise_xor,
      :* => :times, :/ => :division, :DIV => :integer_division, :% => :modulo, :mod => :modulo,
      :- => :minus, :+ => :addition,
      :<< => :left_shift, :>> => :right_shift,
      :& => :bitwise_and,
      :| => :bitwise_or,
      :"=" => :equal, :"<=>" => :null_safe_equal, :>= => :greater_or_equal,
      :> => :greater, :<= => :smaller_or_equal, :< => :smaller, :"<>" => :not_equal, :"!=" => :not_equal,
      :"&&" => :and,
      :"||" => :or,
      :":=" => :assign,
      :relation => :scoped_relation
    }
    
    def initialize(source, opts = {})
      if source.kind_of?(Processor)
        @context  = source.context
        @query    = source.query
        @sxp      = source.sxp
        @ancestor = source
      else
        @sxp = Parser.parse(source)
        @context = opts.merge({:last => true})
        @query = Query.new(self.class)
        @sxp == [:query] ? process([:query, [:relation, main_table]]) : process(@sxp)
      end
    end
    
    protected
      def this
        @this || self
      end
      
      def this=(processor)
        @this = processor
      end
      
      def process(sxp)
        return sxp if sxp.kind_of?(String)
        method = "process_#{OPERATOR_TO_METHOD[sxp.first] || sxp.first}"
        if this.respond_to?(method)
          this.send(method, *sxp[1..-1])
        elsif sxp.size == 3
          this.process_op(*sxp)
        else
          raise QueryException.new("Method '#{method}' to handle #{sxp.first.inspect} not implemented.")
        end
      end
      
      def process_clause_or(clause1, clause2)
        this.process(clause2)
        query2 = @query
        @query = Query.new(this.class)
        this.process(clause1)
        
        @query.tables = (@query.tables + query2.tables).uniq
        @query.where  = ["((#{@query.where.join(' AND ')}) OR (#{query2.where.join(' AND ')}))"]
        @query.distinct = true
      end
      
      # A query can be made of many clauses:
      # [letters from friends] or [images in project]
      def process_query(args)
        this.process(args)
        if @query.order.nil? && this.default_order_clause
          sxp = Parser.parse("foo order by #{this.default_order_clause}")
          order = sxp[1]
          order[1] = [:void] # replace [:relation, "foo"] by [:void]
          this.process(order)
        end
      end
      
      # Parse sub-query from right to left
      def process_from(query, sub_query)
        @distinct = true
        if query.first == :scope
          scope = query.last
          this.with(:last => false, :scope => scope) do
            this.process(query[1])
          end
          table_alias = table
          where = @where
          @where = []
          restoring_this do
            this.process(sub_query)
          end
          sub_where = @where
          @where = where
          this.apply_scope(scope, table_alias)
          @where += sub_where
        else
          this.with(:last => false) do
            this.process(query)
          end
          restoring_this do
            this.process(sub_query)
          end
        end
      end
      
      def process_scoped_relation(relation)
        if context[:scope]
          this.process_relation(relation)
        else
          this.with(:scope => nil) do
            this.process_relation(relation)
            this.apply_scope(context[:scope]) if context[:scope]
          end
        end
      end
      
      def process_scope(relation, scope)
        this.with(:scope => scope) do
          this.process(relation)
          this.apply_scope(scope)
        end
      end
      
      def apply_scope(scope, left_alias = nil)
        if left_alias
          right_alias = table
        else
          left_alias  = table
          right_alias = nil
        end
        if fields = scope_fields(scope, right_alias.nil?)
          @query.add_filter("#{field_or_attr(fields[0], left_alias)} = #{field_or_attr(fields[1], right_alias)}") if fields != []
        else
          raise QueryException.new("Invalid scope '#{scope}'.")
        end
      end
      
      def field_or_attr(fld_name, table_alias = table)
        if table_alias
          this.with(:table_alias => table_alias) do
            this.process_field(fld_name)
          end
        else
          this.process_attr(fld_name)
        end
      end
      
      def process_field(fld_name)
        raise QueryException.new("Unknown field '#{fld_name}'.")
      end
      
      def process_integer(value)
        value
      end
      
      def process_attr(fld_name)
        insert_bind(fld_name)
      end
      
      def process_filter(relation, filter)
        process(relation)
        @query.add_filter process(filter)
      end
      
      def process_par(content)
        content.first == :or ? process(content) : "(#{process(content)})"
      end
      
      def process_clause_par(content)
        process(content)
      end
      
      def process_string(string)
        insert_bind(string.inspect)
      end
      
      def process_interval(value, interval)
        "INTERVAL #{this.process(value)} #{interval.upcase}"
      end
      
      def process_or(left, right)
        left_clause = left.first
        "(#{this.process(left)} OR #{this.process(right)})"
      end
      
      def process_relation(relation)
        raise QueryException.new("Unknown relation '#{relation}'.")
      end
      
      def process_op(op, left, right)
        "#{process(left)} #{op.to_s.upcase} #{process(right)}"
      end
      
      def process_not(expr)
        if expr.first == :like
          "#{this.process(expr[1])} NOT LIKE #{this.process(expr[2])}"
        else
          "NOT #{this.process(expr)}"
        end
      end
      
      def process_order(*args)
        variables = args
        process(variables.shift)  # parse query
        @query.order = " ORDER BY #{variables.map {|var| process(var)}.join(', ')}"
      end
      
      def process_group(*args)
        variables = args
        process(variables.shift)  # parse query
        @query.group = " GROUP BY #{variables.map {|var| process(var)}.join(', ')}"
      end
      
      def process_void(*args)
        # do nothing
      end
      
      def process_limit(*args)
        variables = args
        process(variables.shift)  # parse query
        if variables.size == 1
          @query.limit  = " LIMIT #{process(variables.first)}"
        else  
          @query.limit  = " LIMIT #{process(variables.last)}"
          @query.offset = " OFFSET #{process(variables.first)}"
        end
      end
      
      def process_offset(query, offset)
        process(query)
        raise QueryException.new("Invalid offset (used without limit).") unless @query.limit
        @query.offset = " OFFSET #{process(offset)}"
      end
      
      def process_paginate(query, paginate_fld)
        process(query)
        raise QueryException.new("Invalid paginate clause '#{paginate}' (used without limit).") unless @query.limit
        fld = process(paginate_fld)
        if fld && (page_size = @query.limit[/ LIMIT (\d+)/,1])
          @query.page_size = [2, page_size.to_i].max
          @query.offset = " OFFSET #{insert_bind("((#{fld}.to_i > 0 ? #{fld}.to_i : 1)-1)*#{@query.page_size}")}"
        else
          raise QueryException.new("Invalid paginate clause '#{paginate}'.")
        end  
      end
      
      # Used by paginate
      def process_param(param)
        param
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
        nil
      end
      
      def with(hash)
        context_bak = @context
        res = ''
        @context = @context.merge(hash)
        res = yield
        @context = context_bak
        res
      end
      
      def restoring_this
        processor = self.this
        yield
        if processor != self.this
          # changed class, we need to change back
          change_processor(processor)
        end
      end
      
      def change_processor(processor)
        if @this
          @this.change_processor(processor)
        else
          if processor.kind_of?(Processor)
          elsif processor.kind_of?(String)
            processor = Module.const_get(processor).new(this)
          else
            processor = processor.new(this)
          end
          @query.processor_class = processor.class
          update_processor(processor)
        end
      end
      
      def update_processor(processor)
        @this = processor
        if @ancestor
          @ancestor.update_processor(processor)
        end
      end
      
    private
      def table(table_name = nil, index = 0)
        if table_name.nil?
          context[:table_alias] || @query.table_at(@query.main_table, @query.table_counter(@query.main_table) + index)
        else
          @query.table_at(table_name, @query.table_counter(table_name) + index)
        end
      end

      def add_table(use_name, table_name = nil)
        @query.add_table(use_name, table_name)
      end

      def main_table
        @query.main_table
      end

  end
end